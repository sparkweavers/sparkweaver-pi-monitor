#!/usr/bin/env bash

DOCKER=(docker)

select_docker_runner() {
  if docker info >/dev/null 2>&1; then
    DOCKER=(docker)
  else
    DOCKER=(sudo docker)
  fi
}

compose() { "${DOCKER[@]}" compose "$@"; }

container_running() {
  "${DOCKER[@]}" ps --format '{{.Names}}' 2>/dev/null | grep -qx "$CONTAINER"
}
