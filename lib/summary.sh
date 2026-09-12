#!/usr/bin/env bash

print_summary() {
  local ip command
  ip="$(primary_ip)"
  printf '\n  Uptime Kuma is running.\n\n    http://%s:%s\n\n' "${ip:-<this-host>}" "$PORT"
  printf '  Manage it with:\n'
  for command in "${MANAGE_COMMANDS[@]}"; do
    printf '    cd %s && docker compose %s\n' "$INSTALL_DIR" "$command"
  done
  printf '\n  History lives in the %s volume and survives "docker compose down".\n\n' "$VOLUME"
}

print_no_change_summary() {
  printf '\n  Already on the newest %s, version %s. Nothing was changed.\n\n' "$IMAGE" "$(running_version)"
}

print_update_summary() {
  printf '\n  Uptime Kuma is now version %s.\n\n' "$(running_version)"
  printf '  To roll back, stop the stack and unpack the newest backup into the volume:\n\n'
  printf '    cd %s && docker compose down\n' "$INSTALL_DIR"
  printf '    docker run --rm -v %s:/data -v %s:/backup %s sh -c "rm -rf /data/* && tar xzf /backup/%s -C /data"\n' \
    "$VOLUME" "$BACKUP_DIR" "$BACKUP_IMAGE" "$(basename "$(newest_backup)")"
  printf '    cd %s && docker compose up -d\n\n' "$INSTALL_DIR"
}
