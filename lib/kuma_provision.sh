#!/usr/bin/env bash

provision_kuma() {
  if [ -z "$KUMA_ADMIN_USER" ] || [ -z "$KUMA_ADMIN_PASSWORD" ]; then
    note "KUMA_ADMIN_USER and KUMA_ADMIN_PASSWORD are both required to provision."
    note "They sign in to Uptime Kuma, or create the admin if there is not one yet."
    return 0
  fi
  "${DOCKER[@]}" run --rm --network host \
    --volume "$SCRIPT_DIR/lib:/provision:ro" \
    --volume "$MONITORS_FILE:/monitors.json:ro" \
    --volume "$STATUS_PAGES_FILE:/status-pages.json:ro" \
    --env "KUMA_URL=http://127.0.0.1:${PORT}" \
    --env "KUMA_ADMIN_USER=$KUMA_ADMIN_USER" \
    --env "KUMA_ADMIN_PASSWORD=$KUMA_ADMIN_PASSWORD" \
    --env "KUMA_MONITORS_FILE=/monitors.json" \
    --env "KUMA_STATUS_PAGES_FILE=/status-pages.json" \
    "$PYTHON_IMAGE" \
    sh -c "pip install --quiet --disable-pip-version-check --root-user-action=ignore $API_PACKAGE && python /provision/kuma_provision.py"
}
