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
  local port="$1" container="$2" override="$3"
  if port_in_use "$port" && ! container_running "$container"; then
    die "port $port is held by something other than $container. Free it, or set $override="
  fi
  ok "port $port is available"
}

require_free_ports() {
  require_free_port "$PORT" "$CONTAINER" PORT
  require_free_port "$SIGNAL_PORT" "$SIGNAL_CONTAINER" SIGNAL_PORT
}
