#!/usr/bin/env bash

print_summary() {
  local ip command
  ip="$(primary_ip)"
  printf '\n  Uptime Kuma is running.\n\n    http://%s:%s\n\n' "${ip:-<this-host>}" "$PORT"
  printf '  Open it now and create the admin account. Uptime Kuma ships with no\n'
  printf '  credentials, so the first visitor to that page sets the password.\n\n'
  printf '  Manage it with:\n'
  for command in "${MANAGE_COMMANDS[@]}"; do
    printf '    cd %s && docker compose %s\n' "$INSTALL_DIR" "$command"
  done
  printf '\n  History lives in the %s volume and survives "docker compose down".\n\n' "$VOLUME"
}
