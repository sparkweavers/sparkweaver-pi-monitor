#!/usr/bin/env bash

signal_service_block() {
  cat <<YAML

  ${SIGNAL_SERVICE}:
    image: ${SIGNAL_IMAGE}
    container_name: ${SIGNAL_CONTAINER}
    restart: always
    environment:
      - MODE=${SIGNAL_MODE}
    ports:
      - "${SIGNAL_PORT}:${SIGNAL_CONTAINER_PORT}"
    volumes:
      - ${SIGNAL_VOLUME}:/home/.local/share/signal-cli
YAML
}

signal_get() {
  curl -fsS --max-time "$SIGNAL_TIMEOUT" "http://127.0.0.1:${SIGNAL_PORT}$1" 2>/dev/null || true
}

# /v1/accounts answers a JSON array of linked numbers, or [] before linking.
linked_number() {
  signal_get /v1/accounts | tr -d '[]" ' | cut -d, -f1
}

send_endpoint() {
  printf 'http://%s:%s/v2/send' "$SIGNAL_SERVICE" "$SIGNAL_CONTAINER_PORT"
}

link_url() {
  printf 'http://%s:%s/v1/qrcodelink?device_name=%s' \
    "$(primary_ip)" "$SIGNAL_PORT" "$SIGNAL_DEVICE_NAME"
}

require_signal_running() {
  if ! container_running "$SIGNAL_CONTAINER"; then
    die "$SIGNAL_CONTAINER is not running. Run ./install.sh first."
  fi
  ok "$SIGNAL_CONTAINER is running"
}

wait_for_signal_api() {
  local attempt
  for ((attempt = 0; attempt < SIGNAL_WAIT_ATTEMPTS; attempt++)); do
    if [ -n "$(signal_get /v1/about)" ]; then
      ok "the Signal bridge answers on port $SIGNAL_PORT"
      return 0
    fi
    sleep "$WAIT_INTERVAL"
  done
  die "no response from the Signal bridge on port $SIGNAL_PORT"
}

print_link_instructions() {
  printf '\n  Open this on a machine that can reach the Pi:\n\n    %s\n\n' "$(link_url)"
  printf '  Then in Signal on your phone: Settings, Linked devices, plus, scan it.\n'
  printf '  Waiting for the link to complete.\n\n'
}

await_linked_number() {
  local attempt number
  for ((attempt = 0; attempt < SIGNAL_LINK_ATTEMPTS; attempt++)); do
    number="$(linked_number)"
    if [ -n "$number" ]; then
      ok "linked as $number"
      return 0
    fi
    sleep "$WAIT_INTERVAL"
  done
  die "nothing was linked within $((SIGNAL_LINK_ATTEMPTS * WAIT_INTERVAL))s. Re-run to try again."
}
