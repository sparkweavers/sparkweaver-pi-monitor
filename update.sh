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
# shellcheck source=lib/backup.sh
source "$SCRIPT_DIR/lib/backup.sh"
# shellcheck source=lib/update.sh
source "$SCRIPT_DIR/lib/update.sh"
# shellcheck source=lib/summary.sh
source "$SCRIPT_DIR/lib/summary.sh"

main() {
  local before after

  step "Checking the machine"
  require_normal_user
  select_docker_runner
  require_installed

  step "Checking the upgrade is safe"
  require_major_allowed

  step "Fetching the newest image"
  before="$(image_digest)"
  pull_image
  after="$(image_digest)"

  if [ -n "$before" ] && [ "$before" = "$after" ]; then
    print_no_change_summary
    return 0
  fi

  step "Backing up the data volume"
  stop_stack
  backup_data_volume
  prune_backups

  step "Starting the new image"
  write_compose_file
  start_stack

  step "Waiting for Uptime Kuma to answer"
  wait_until_healthy

  print_update_summary
}

main "$@"
