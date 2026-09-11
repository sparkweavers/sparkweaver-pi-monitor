#!/usr/bin/env bash
# Installs Docker if absent, then runs Uptime Kuma as a container on port 3001.
# Safe to re-run: existing installs are upgraded in place, data is preserved.
set -euo pipefail

INSTALL_DIR="${INSTALL_DIR:-/opt/uptime-kuma}"
IMAGE="${IMAGE:-louislam/uptime-kuma:1}"
PORT="${PORT:-3001}"
CONTAINER="uptime-kuma"

say()  { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
ok()   { printf '\033[1;32m  ok\033[0m %s\n' "$*"; }
die()  { printf '\n\033[1;31mERROR:\033[0m %s\n' "$*" >&2; exit 1; }

[ "$(id -u)" -eq 0 ] && die "Run this as your normal user, not root. It calls sudo itself."

say "Checking the machine"
ARCH="$(uname -m)"
case "$ARCH" in
  aarch64|arm64|x86_64|amd64) ok "architecture $ARCH is supported" ;;
  *) die "architecture $ARCH has no official Uptime Kuma image. 64-bit OS required." ;;
esac
ok "$(. /etc/os-release && echo "$PRETTY_NAME")"

# A free port matters more than a running container: something else on 3001 must not be displaced.
if ss -lnt 2>/dev/null | grep -q ":${PORT} " && ! docker ps 2>/dev/null | grep -q "$CONTAINER"; then
  die "Port ${PORT} is already in use by something that is not ${CONTAINER}. Free it or set PORT=."
fi

say "Checking for Docker"
if command -v docker >/dev/null 2>&1; then
  ok "$(docker --version)"
else
  echo "  Docker is not installed. Installing from get.docker.com (sudo password needed)."
  curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
  sudo sh /tmp/get-docker.sh
  rm -f /tmp/get-docker.sh
  ok "$(docker --version)"
fi

if ! docker compose version >/dev/null 2>&1; then
  echo "  Compose plugin missing. Installing docker-compose-plugin."
  sudo apt-get update -qq && sudo apt-get install -y -qq docker-compose-plugin
fi
ok "$(docker compose version)"

say "Enabling Docker at boot"
sudo systemctl enable --now docker >/dev/null 2>&1 || true
ok "docker service enabled"

say "Granting $USER access to Docker"
if id -nG "$USER" | tr ' ' '\n' | grep -qx docker; then
  ok "already in the docker group"
else
  sudo usermod -aG docker "$USER"
  ok "added to the docker group (takes effect on your next login)"
fi

# Group membership does not apply to this shell yet, so fall back to sudo for this run.
if docker info >/dev/null 2>&1; then
  DC="docker compose"
else
  DC="sudo docker compose"
fi

say "Writing $INSTALL_DIR/docker-compose.yml"
sudo mkdir -p "$INSTALL_DIR"
sudo tee "$INSTALL_DIR/docker-compose.yml" >/dev/null <<YAML
services:
  uptime-kuma:
    image: ${IMAGE}
    container_name: ${CONTAINER}
    restart: always
    ports:
      - "${PORT}:3001"
    volumes:
      - uptime-kuma-data:/app/data

volumes:
  uptime-kuma-data:
YAML
ok "compose file written"

say "Pulling the image and starting the container"
cd "$INSTALL_DIR"
$DC pull
$DC up -d
ok "container started"

say "Waiting for Uptime Kuma to answer"
CODE=""
for _ in $(seq 1 60); do
  CODE="$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:${PORT}" 2>/dev/null || true)"
  case "$CODE" in 200|302) break ;; esac
  sleep 2
done
case "$CODE" in
  200|302) ok "responded with HTTP $CODE" ;;
  *) $DC logs --tail=40; die "no response on port ${PORT} after 120s. Logs are above." ;;
esac

IP="$(hostname -I 2>/dev/null | awk '{print $1}')"
cat <<EOF

  Uptime Kuma is running.

    http://${IP:-<this-host>}:${PORT}

  Open it now and create the admin account. Uptime Kuma ships with no
  credentials, so the first visitor to that page sets the password.

  Manage it with:
    cd ${INSTALL_DIR} && docker compose ps
    cd ${INSTALL_DIR} && docker compose logs -f
    cd ${INSTALL_DIR} && docker compose restart

  Your monitor history lives in the uptime-kuma-data volume and survives
  "docker compose down". Re-run this script to upgrade.

EOF
