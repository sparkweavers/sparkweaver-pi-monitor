#!/usr/bin/env bash

netbird_connected() {
  sudo netbird status 2>/dev/null | grep -q 'Management: Connected'
}

netbird_peer_ip() {
  sudo netbird status 2>/dev/null | awk -F': *' '/NetBird IP:/ {print $2; exit}'
}

peer_ip_by_fqdn() {
  sudo netbird status -d 2>/dev/null | awk -v want="$1:" '
    $1 == want { found = 1; next }
    found && $1 == "NetBird" && $2 == "IP:" { print $3; exit }
  '
}

install_netbird_agent() {
  if has_command netbird; then
    ok "NetBird agent already installed"
    return 0
  fi
  note "Installing the NetBird agent from $NETBIRD_INSTALL_URL (sudo password needed)."
  local script
  script="$(mktemp)"
  curl -fsSL "$NETBIRD_INSTALL_URL" -o "$script"
  sudo sh "$script"
  rm -f "$script"
  has_command netbird || die "netbird is still not on PATH after installing"
  ok "NetBird agent installed"
}

enrol_netbird() {
  if netbird_connected; then
    ok "already enrolled, existing peer left alone"
    return 0
  fi
  sudo netbird up --setup-key "$NETBIRD_SETUP_KEY"
  ok "enrolled with the setup key"
}

await_peer_address() {
  local attempt
  for ((attempt = 0; attempt < NETBIRD_WAIT_ATTEMPTS; attempt++)); do
    if [ -n "$(netbird_peer_ip)" ]; then return 0; fi
    sleep "$WAIT_INTERVAL"
  done
  die "enrolled, but no peer address was assigned"
}

ensure_netbird() {
  if [ -z "$NETBIRD_SETUP_KEY" ]; then
    note "NETBIRD_SETUP_KEY is unset, so this host stays off the VPN."
    note "The Supabase monitors answer 403 until this host is an allowlisted peer."
    return 0
  fi
  install_netbird_agent
  sudo systemctl enable --now netbird >/dev/null 2>&1 || true
  enrol_netbird
  await_peer_address
  ok "peer address $(netbird_peer_ip)"
}

print_allowlist_hint() {
  local ip
  ip="$(netbird_peer_ip)"
  if [ -z "$ip" ]; then return 0; fi
  printf '  This host reaches Supabase only once %s/32 is listed.\n' "$ip"
  printf '  Append it to SUPABASE_ALLOWLIST in both sparkweaver-db Environments,\n'
  printf '  then run "Update Supabase Nginx Allowlist" once per environment.\n\n'
}
