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

start_stack() {
  cd "$INSTALL_DIR" || die "cannot enter $INSTALL_DIR"
  compose pull
  compose up -d
  ok "container started"
}

stop_stack() {
  cd "$INSTALL_DIR" || die "cannot enter $INSTALL_DIR"
  compose down
  ok "container stopped, the $VOLUME volume is untouched"
}

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
