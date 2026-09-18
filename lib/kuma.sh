#!/usr/bin/env bash

extra_hosts_block() {
  local ip host
  ip="$(peer_ip_by_fqdn "$TUNNEL_PEER_FQDN")"
  if [ -z "$ip" ]; then
    note "peer $TUNNEL_PEER_FQDN is unknown, so the tunnelled hosts are left out"
    return 0
  fi
  printf '    extra_hosts:\n'
  for host in "${TUNNEL_HOSTNAMES[@]}"; do
    printf '      - "%s:%s"\n' "$host" "$ip"
  done
}

kuma_service_block() {
  cat <<YAML
services:
  uptime-kuma:
    image: ${IMAGE}
    container_name: ${CONTAINER}
    restart: always
    ports:
      - "${PORT}:${CONTAINER_PORT}"
    volumes:
      - ${VOLUME}:/app/data
YAML
}

volumes_block() {
  cat <<YAML

volumes:
  ${VOLUME}:
  ${SIGNAL_VOLUME}:
YAML
}

write_compose_file() {
  sudo mkdir -p "$INSTALL_DIR"
  {
    kuma_service_block
    extra_hosts_block
    signal_service_block
    volumes_block
  } | sudo tee "$INSTALL_DIR/docker-compose.yml" >/dev/null
  ok "wrote $INSTALL_DIR/docker-compose.yml"
}

enter_install_dir() {
  cd "$INSTALL_DIR" || die "cannot enter $INSTALL_DIR"
}

# Reaches the registry only on the way in, so a stack that is merely stopped can
# come back without the network.
resume_stack() {
  enter_install_dir
  compose up -d
  ok "container started"
}

start_stack() {
  enter_install_dir
  compose pull
  resume_stack
}

stop_stack() {
  enter_install_dir
  compose down
  ok "container stopped, the $VOLUME volume is untouched"
}

# Prints the code it accepted, so callers can report it without asking twice.
answering() {
  local code
  code="$(http_code "$KUMA_URL")"
  contains "$code" "${HEALTHY_CODES[@]}" || return 1
  printf '%s' "$code"
}

already_running() {
  container_running "$CONTAINER" && answering >/dev/null
}

wait_until_healthy() {
  local code attempt
  for ((attempt = 0; attempt < WAIT_ATTEMPTS; attempt++)); do
    if code="$(answering)"; then
      ok "answered with HTTP $code"
      return 0
    fi
    sleep "$WAIT_INTERVAL"
  done
  compose logs --tail=40
  die "no response on port $PORT after $((WAIT_ATTEMPTS * WAIT_INTERVAL))s. Logs are above."
}
