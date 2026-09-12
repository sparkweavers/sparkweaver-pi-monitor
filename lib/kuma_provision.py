import json
import os
import sys

from uptime_kuma_api import MonitorType, UptimeKumaApi

URL = os.environ["KUMA_URL"]
USER = os.environ["KUMA_ADMIN_USER"]
PASSWORD = os.environ["KUMA_ADMIN_PASSWORD"]
MONITORS_FILE = os.environ["KUMA_MONITORS_FILE"]


def read_specs(path):
    if not os.path.exists(path):
        return []
    with open(path, encoding="utf-8") as handle:
        return json.load(handle)


def ensure_admin(api):
    if api.need_setup():
        api.setup(USER, PASSWORD)
        return "created"
    return "exists"


def index_by_name(api):
    return {monitor["name"]: monitor["id"] for monitor in api.get_monitors()}


def ensure_group(api, name, index):
    if name in index:
        return index[name]
    response = api.add_monitor(type=MonitorType.GROUP, name=name)
    index[name] = response["monitorID"]
    print(f"created group {name}")
    return index[name]


def ensure_monitor(api, spec, index):
    spec = dict(spec)
    group = spec.pop("group", None)
    name = spec["name"]
    if name in index:
        return False
    if group:
        spec["parent"] = ensure_group(api, group, index)
    spec["type"] = MonitorType(spec["type"])
    response = api.add_monitor(**spec)
    index[name] = response["monitorID"]
    print(f"added monitor {name}")
    return True


def main():
    specs = read_specs(MONITORS_FILE)
    with UptimeKumaApi(URL) as api:
        print(f"admin account {ensure_admin(api)}")
        api.login(USER, PASSWORD)
        index = index_by_name(api)
        added = sum(ensure_monitor(api, spec, index) for spec in specs)
        print(f"{added} added, {len(specs) - added} already present")
    return 0


if __name__ == "__main__":
    sys.exit(main())
