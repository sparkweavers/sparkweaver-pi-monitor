#!/usr/bin/env bash

require_installed() {
  if [ ! -f "$INSTALL_DIR/docker-compose.yml" ]; then
    die "nothing installed at $INSTALL_DIR. Run ./install.sh first."
  fi
  ok "found $INSTALL_DIR/docker-compose.yml"
}

running_version() {
  "${DOCKER[@]}" exec "$CONTAINER" cat /app/package.json 2>/dev/null |
    awk -F'"' '/"version"/ {print $4; exit}'
}

major_of() { printf '%s' "${1%%.*}"; }

target_major() {
  local tag="${IMAGE##*:}"
  major_of "$tag"
}

image_digest() {
  "${DOCKER[@]}" image inspect "$IMAGE" --format '{{index .RepoDigests 0}}' 2>/dev/null || true
}

pull_image() {
  "${DOCKER[@]}" pull --quiet "$IMAGE" >/dev/null || die "could not pull $IMAGE"
  ok "pulled $IMAGE"
}

require_major_allowed() {
  local from to
  from="$(major_of "$(running_version)")"
  to="$(target_major)"
  if [ -z "$from" ] || [ "$from" = "$to" ]; then
    return 0
  fi
  if [ "$ALLOW_MAJOR_UPGRADE" = "1" ]; then
    note "major upgrade $from to $to, allowed explicitly"
    return 0
  fi
  note "$IMAGE moves this instance from $from.x to $to.x."
  note "That rewrites the database on first boot and cannot be undone."
  die "read the release notes, then re-run with ALLOW_MAJOR_UPGRADE=1"
}
