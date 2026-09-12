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
# shellcheck source=lib/signal.sh
source "$SCRIPT_DIR/lib/signal.sh"
# shellcheck source=lib/summary.sh
source "$SCRIPT_DIR/lib/summary.sh"

main() {
  step "Checking the machine"
  require_normal_user
  select_docker_runner
  require_signal_running
  wait_for_signal_api

  local number
  number="$(linked_number)"
  if [ -n "$number" ]; then
    ok "already linked as $number, nothing to do"
    print_signal_summary
    return 0
  fi

  step "Linking this host to your Signal account"
  print_link_instructions
  await_linked_number

  print_signal_summary
}

main "$@"
