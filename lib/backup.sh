#!/usr/bin/env bash

backup_file_name() { printf '%s-%s.tgz' "$VOLUME" "$(date +%Y%m%d-%H%M%S)"; }

backup_data_volume() {
  local name
  name="$(backup_file_name)"
  mkdir -p "$BACKUP_DIR"
  "${DOCKER[@]}" run --rm \
    --volume "${VOLUME}:/data:ro" \
    --volume "${BACKUP_DIR}:/backup" \
    "$BACKUP_IMAGE" \
    tar czf "/backup/${name}" -C /data . \
    || die "backup failed, so nothing was changed"
  sudo chown "$(id -u):$(id -g)" "$BACKUP_DIR/$name" 2>/dev/null || true
  ok "backed up to $BACKUP_DIR/$name"
}

backup_files() {
  local files=("$BACKUP_DIR/$VOLUME"-*.tgz)
  if [ ! -e "${files[0]}" ]; then return 0; fi
  printf '%s\n' "${files[@]}"
}

newest_backup() { backup_files | tail -1; }

prune_backups() {
  local files file stale
  mapfile -t files < <(backup_files)
  stale=$((${#files[@]} - BACKUP_KEEP))
  if [ "$stale" -le 0 ]; then return 0; fi
  for file in "${files[@]:0:$stale}"; do
    rm -f "$file" && note "pruned $(basename "$file")"
  done
}
