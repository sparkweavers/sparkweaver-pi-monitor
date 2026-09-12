#!/usr/bin/env bash

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
