#!/usr/bin/env bash

DATA_VOLUME=""
BACKUP_NAME=""

resolve_data_volume() {
  DATA_VOLUME="$("${DOCKER[@]}" inspect "$CONTAINER" \
    --format "{{range .Mounts}}{{if eq .Destination \"$DATA_MOUNT\"}}{{.Name}}{{end}}{{end}}" 2>/dev/null)"
  if [ -z "$DATA_VOLUME" ]; then
    die "nothing is mounted at $DATA_MOUNT in $CONTAINER, so a backup would be empty"
  fi
  ok "data volume $DATA_VOLUME"
}

backup_file_name() { printf '%s-%s.tgz' "$CONTAINER" "$(date +%Y%m%d-%H%M%S)"; }

verify_backup() {
  tar tzf "$1" 2>/dev/null | grep -q "$DATABASE_FILE" ||
    die "$1 holds no $DATABASE_FILE. Refusing to go further."
}

backup_data_volume() {
  BACKUP_NAME="$(backup_file_name)"
  mkdir -p "$BACKUP_DIR"
  "${DOCKER[@]}" run --rm \
    --volume "${DATA_VOLUME}:/data:ro" \
    --volume "${BACKUP_DIR}:/backup" \
    "$BACKUP_IMAGE" \
    tar czf "/backup/${BACKUP_NAME}" -C /data . ||
    die "backup failed, so nothing was changed"
  sudo chown "$(id -u):$(id -g)" "$BACKUP_DIR/$BACKUP_NAME" 2>/dev/null || true
  verify_backup "$BACKUP_DIR/$BACKUP_NAME"
  ok "backed up to $BACKUP_DIR/$BACKUP_NAME"
}

backup_files() {
  local files=("$BACKUP_DIR/$CONTAINER"-*.tgz)
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
