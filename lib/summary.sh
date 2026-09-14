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

# Read from the data file so the printed URL and the provisioned page cannot drift.
status_page_slug() {
  grep -o '"slug"[[:space:]]*:[[:space:]]*"[^"]*"' "$STATUS_PAGES_FILE" 2>/dev/null |
    head -1 | cut -d'"' -f4
}

print_status_page_hint() {
  local slug
  slug="$(status_page_slug)"
  [ -n "$slug" ] || return 0
  printf '  The status page needs no login. Anyone who can reach this host can read it.\n\n'
  printf '    http://%s:%s/status/%s\n\n' "$(primary_ip)" "$PORT" "$slug"
}

print_signal_hint() {
  if [ -n "$(linked_number)" ]; then
    print_signal_summary
    return 0
  fi
  printf '  Signal alerts are one step away. Run ./link-signal.sh to link this host\n'
  printf '  to your Signal account.\n\n'
}

print_signal_summary() {
  printf '\n  Add the notification in Uptime Kuma under Settings, Notifications,\n'
  printf '  Setup Notification. Pick Signal and fill in:\n\n'
  printf '    Post URL    %s\n' "$(send_endpoint)"
  printf '    Number      %s\n' "$(linked_number)"
  printf '    Recipients  %s\n\n' "$(linked_number)"
  printf '  Sending to your own number puts the alerts in Note to Self.\n'
  printf '  Use Test to prove it before you rely on it.\n\n'
}

print_no_change_summary() {
  printf '\n  Already on the newest %s, version %s. Nothing was changed.\n\n' "$IMAGE" "$(running_version)"
}

print_update_summary() {
  printf '\n  Uptime Kuma is now version %s.\n\n' "$(running_version)"
  printf '  To roll back, stop the stack and unpack the newest backup into the volume:\n\n'
  printf '    cd %s && docker compose down\n' "$INSTALL_DIR"
  printf '    docker run --rm -v %s:/data -v %s:/backup %s sh -c "rm -rf /data/* && tar xzf /backup/%s -C /data"\n' \
    "$DATA_VOLUME" "$BACKUP_DIR" "$BACKUP_IMAGE" "$BACKUP_NAME"
  printf '    cd %s && docker compose up -d\n\n' "$INSTALL_DIR"
}
