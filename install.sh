#!/usr/bin/env bash
# Installs Docker if absent, then runs Uptime Kuma as a container.
# Re-running upgrades the image and preserves existing monitor data.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
# shellcheck source=lib/output.sh
source "$SCRIPT_DIR/lib/output.sh"
# shellcheck source=lib/predicates.sh
source "$SCRIPT_DIR/lib/predicates.sh"

# --- configuration --------------------------------------------------------
# Every value reads from the environment, so changing one never means editing this file.
readonly INSTALL_DIR="${INSTALL_DIR:-/opt/uptime-kuma}"
readonly IMAGE="${IMAGE:-louislam/uptime-kuma:1}"
readonly PORT="${PORT:-3001}"
readonly CONTAINER="${CONTAINER:-uptime-kuma}"
readonly VOLUME="${VOLUME:-uptime-kuma-data}"
readonly DOCKER_INSTALL_URL="${DOCKER_INSTALL_URL:-https://get.docker.com}"

readonly CONTAINER_PORT=3001
readonly WAIT_ATTEMPTS=60
readonly WAIT_INTERVAL=2
readonly SUPPORTED_ARCHS=(aarch64 arm64 x86_64 amd64)
readonly HEALTHY_CODES=(200 302)
readonly MANAGE_COMMANDS=(ps "logs -f" restart)

# --- the docker runner ----------------------------------------------------
# Call sites use compose(), so none of them knows whether the daemon needs
# sudo. Replacing the runner replaces it at every call site at once.
DOCKER=(docker)

select_docker_runner() {
  if docker info >/dev/null 2>&1; then
    DOCKER=(docker)
  else
    DOCKER=(sudo docker)
  fi
}

compose() { "${DOCKER[@]}" compose "$@"; }

container_running() {
  "${DOCKER[@]}" ps --format '{{.Names}}' 2>/dev/null | grep -qx "$CONTAINER"
}

# --- preconditions --------------------------------------------------------
require_normal_user() {
  if [ "$(id -u)" -eq 0 ]; then
    die "Run this as your normal user, not root. It calls sudo where it needs to."
  fi
  ok "running as $USER"
}

require_supported_arch() {
  local arch
  arch="$(uname -m)"
  if ! contains "$arch" "${SUPPORTED_ARCHS[@]}"; then
    die "architecture $arch has no official Uptime Kuma image. A 64-bit OS is required."
  fi
  ok "architecture $arch is supported"
  ok "$(os_pretty_name)"
}

require_free_port() {
  if port_in_use "$PORT" && ! container_running; then
    die "port $PORT is held by something other than $CONTAINER. Free it, or set PORT="
  fi
  ok "port $PORT is available"
}

# --- provisioning ---------------------------------------------------------
ensure_docker() {
  if has_command docker; then
    ok "$(docker --version)"
    return 0
  fi
  note "Docker is not installed. Installing from $DOCKER_INSTALL_URL (sudo password needed)."
  local script
  script="$(mktemp)"
  curl -fsSL "$DOCKER_INSTALL_URL" -o "$script"
  sudo sh "$script"
  rm -f "$script"
  ok "$(docker --version)"
}

ensure_compose_plugin() {
  if ! docker compose version >/dev/null 2>&1; then
    note "Compose plugin missing. Installing docker-compose-plugin."
    sudo apt-get update -qq
    sudo apt-get install -y -qq docker-compose-plugin
  fi
  ok "$(docker compose version)"
}

ensure_docker_service() {
  sudo systemctl enable --now docker >/dev/null 2>&1 || true
  ok "docker service enabled at boot"
}

ensure_docker_group() {
  if in_group docker; then
    ok "$USER is already in the docker group"
    return 0
  fi
  sudo usermod -aG docker "$USER"
  ok "added $USER to the docker group, active at next login"
}

write_compose_file() {
  sudo mkdir -p "$INSTALL_DIR"
  sudo tee "$INSTALL_DIR/docker-compose.yml" >/dev/null <<YAML
services:
  uptime-kuma:
    image: ${IMAGE}
    container_name: ${CONTAINER}
    restart: always
    ports:
      - "${PORT}:${CONTAINER_PORT}"
    volumes:
      - ${VOLUME}:/app/data

volumes:
  ${VOLUME}:
YAML
  ok "wrote $INSTALL_DIR/docker-compose.yml"
}

start_stack() {
  cd "$INSTALL_DIR"
  compose pull
  compose up -d
  ok "container started"
}

# --- verification ---------------------------------------------------------
wait_until_healthy() {
  local url="http://127.0.0.1:${PORT}" code attempt
  for ((attempt = 0; attempt < WAIT_ATTEMPTS; attempt++)); do
    code="$(http_code "$url")"
    if contains "$code" "${HEALTHY_CODES[@]}"; then
      ok "answered with HTTP $code"
      return 0
    fi
    sleep "$WAIT_INTERVAL"
  done
  compose logs --tail=40
  die "no response on port $PORT after $((WAIT_ATTEMPTS * WAIT_INTERVAL))s. Logs are above."
}

print_summary() {
  local ip command
  ip="$(primary_ip)"
  printf '\n  Uptime Kuma is running.\n\n    http://%s:%s\n\n' "${ip:-<this-host>}" "$PORT"
  printf '  Open it now and create the admin account. Uptime Kuma ships with no\n'
  printf '  credentials, so the first visitor to that page sets the password.\n\n'
  printf '  Manage it with:\n'
  for command in "${MANAGE_COMMANDS[@]}"; do
    printf '    cd %s && docker compose %s\n' "$INSTALL_DIR" "$command"
  done
  printf '\n  History lives in the %s volume and survives "docker compose down".\n\n' "$VOLUME"
}

# --- orchestration --------------------------------------------------------
main() {
  step "Checking the machine"
  require_normal_user
  require_supported_arch

  step "Checking for Docker"
  ensure_docker
  ensure_compose_plugin
  ensure_docker_service
  ensure_docker_group
  select_docker_runner
  require_free_port

  step "Writing the compose file"
  write_compose_file

  step "Pulling the image and starting the container"
  start_stack

  step "Waiting for Uptime Kuma to answer"
  wait_until_healthy

  print_summary
}

main "$@"
