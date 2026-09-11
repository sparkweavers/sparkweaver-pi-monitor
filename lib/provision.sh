#!/usr/bin/env bash

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
