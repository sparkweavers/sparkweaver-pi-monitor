#!/usr/bin/env bash

provision_kuma() {
  if [ -z "$KUMA_ADMIN_PASSWORD" ]; then
    note "KUMA_ADMIN_PASSWORD is unset, so nothing is provisioned."
    note "Create the admin account in the dashboard before anyone else does."
    return 0
  fi
  "${DOCKER[@]}" run --rm --network host \
    --volume "$SCRIPT_DIR/lib/kuma_provision.py:/provision.py:ro" \
    --volume "$MONITORS_FILE:/monitors.json:ro" \
    --env "KUMA_URL=http://127.0.0.1:${PORT}" \
    --env "KUMA_ADMIN_USER=$KUMA_ADMIN_USER" \
    --env "KUMA_ADMIN_PASSWORD=$KUMA_ADMIN_PASSWORD" \
    --env "KUMA_MONITORS_FILE=/monitors.json" \
    "$PYTHON_IMAGE" \
    sh -c "pip install --quiet --disable-pip-version-check --root-user-action=ignore $API_PACKAGE && python /provision.py"
}
