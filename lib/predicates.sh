#!/usr/bin/env bash

contains() {
  local needle="$1" item
  shift
  for item in "$@"; do
    if [ "$item" = "$needle" ]; then return 0; fi
  done
  return 1
}

has_command() { command -v "$1" >/dev/null 2>&1; }

http_code() { curl -s -o /dev/null -w '%{http_code}' "$1" 2>/dev/null || true; }

port_in_use() { ss -lnt 2>/dev/null | grep -q ":${1} "; }

in_group() { id -nG "${2:-$USER}" | tr ' ' '\n' | grep -qx "$1"; }

os_pretty_name() { (. /etc/os-release && printf '%s' "$PRETTY_NAME"); }

primary_ip() { hostname -I 2>/dev/null | awk '{print $1}'; }
