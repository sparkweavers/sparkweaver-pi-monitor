#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

# shellcheck source=lib/config.sh
source "$SCRIPT_DIR/lib/config.sh"
# shellcheck source=lib/output.sh
source "$SCRIPT_DIR/lib/output.sh"
# shellcheck source=lib/predicates.sh
source "$SCRIPT_DIR/lib/predicates.sh"
# shellcheck source=lib/docker.sh
source "$SCRIPT_DIR/lib/docker.sh"
# shellcheck source=lib/preflight.sh
source "$SCRIPT_DIR/lib/preflight.sh"
# shellcheck source=lib/kuma.sh
source "$SCRIPT_DIR/lib/kuma.sh"
# shellcheck source=lib/update.sh
source "$SCRIPT_DIR/lib/update.sh"
# shellcheck source=lib/summary.sh
source "$SCRIPT_DIR/lib/summary.sh"

main() {
  step "Checking the machine"
  require_normal_user
  select_docker_runner
  require_installed

  if already_running; then
    ok "$CONTAINER is already answering on port $PORT"
  else
    step "Starting the container"
    resume_stack

    step "Waiting for Uptime Kuma to answer"
    wait_until_healthy
  fi

  print_summary
  print_status_page_hint
}

main "$@"
