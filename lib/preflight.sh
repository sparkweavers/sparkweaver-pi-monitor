#!/usr/bin/env bash

require_normal_user() {
  if [ "$(id -u)" -eq 0 ]; then
    die "Run this as your normal user, not root. It calls sudo where it needs to."
  fi
  ok "running as $USER"
}

require_supported_arch() {
  local arch
  arch="$(uname -m)"
  if ! contains "$arch" "${SUPPORTED_ARCHS[@]}"; then
    die "architecture $arch has no official Uptime Kuma image. A 64-bit OS is required."
  fi
  ok "architecture $arch is supported"
  ok "$(os_pretty_name)"
}

require_free_port() {
  if port_in_use "$PORT" && ! container_running; then
    die "port $PORT is held by something other than $CONTAINER. Free it, or set PORT="
  fi
  ok "port $PORT is available"
}
