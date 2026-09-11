#!/usr/bin/env bash
# Terminal output only. Nothing here knows about Docker or Uptime Kuma.

readonly C_STEP=$'\033[1;36m' C_OK=$'\033[1;32m' C_ERR=$'\033[1;31m' C_OFF=$'\033[0m'

step() { printf '\n%s==> %s%s\n' "$C_STEP" "$*" "$C_OFF"; }
ok()   { printf '%s  ok%s %s\n' "$C_OK" "$C_OFF" "$*"; }
note() { printf '     %s\n' "$*"; }
die()  { printf '\n%sERROR:%s %s\n' "$C_ERR" "$C_OFF" "$*" >&2; exit 1; }
