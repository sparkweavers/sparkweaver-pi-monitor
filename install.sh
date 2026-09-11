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
# shellcheck source=lib/provision.sh
source "$SCRIPT_DIR/lib/provision.sh"
# shellcheck source=lib/kuma.sh
source "$SCRIPT_DIR/lib/kuma.sh"
# shellcheck source=lib/summary.sh
source "$SCRIPT_DIR/lib/summary.sh"

main() {
  step "Checking the machine"
  require_normal_user
  require_supported_arch

  step "Providing Docker"
  ensure_docker
  ensure_compose_plugin
  ensure_docker_service
  ensure_docker_group
  select_docker_runner
  require_free_port

  step "Writing the compose file"
  write_compose_file

  step "Starting the container"
  start_stack

  step "Waiting for Uptime Kuma to answer"
  wait_until_healthy

  print_summary
}

main "$@"
