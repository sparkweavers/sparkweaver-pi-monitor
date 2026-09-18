#!/usr/bin/env bash

# A start must not reach the network, or a stopped instance stays down whenever
# the registry is unreachable. Pulling is update.sh's job.
resume_stack() {
  cd "$INSTALL_DIR" || die "cannot enter $INSTALL_DIR"
  compose up -d
  ok "container started"
}

already_answering() {
  container_running "$CONTAINER" || return 1
  contains "$(http_code "http://127.0.0.1:${PORT}")" "${HEALTHY_CODES[@]}"
}
