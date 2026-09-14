import json
import os
import sys

from kuma_status_pages import ensure_status_page
from uptime_kuma_api import MonitorType, UptimeKumaApi

URL = os.environ["KUMA_URL"]
USER = os.environ["KUMA_ADMIN_USER"]
PASSWORD = os.environ["KUMA_ADMIN_PASSWORD"]
MONITORS_FILE = os.environ["KUMA_MONITORS_FILE"]
STATUS_PAGES_FILE = os.environ["KUMA_STATUS_PAGES_FILE"]

# Keys a re-run pushes onto monitors that already exist. Anything outside this
# set stays as the dashboard left it.
RECONCILED = ("url", "interval", "accepted_statuscodes")
STATES = ("added", "updated", "unchanged")


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
    return {monitor["name"]: monitor for monitor in api.get_monitors()}


def ensure_group(api, name, index):
    if name in index:
        return index[name]["id"]
    response = api.add_monitor(type=MonitorType.GROUP, name=name)
    index[name] = {"id": response["monitorID"], "name": name}
    print(f"created group {name}")
    return index[name]["id"]


def reconcile(api, monitor, spec):
    changes = {
        key: spec[key]
        for key in RECONCILED
        if key in spec and monitor.get(key) != spec[key]
    }
    if not changes:
        return "unchanged"
    api.edit_monitor(monitor["id"], **changes)
    print(f"updated {monitor['name']}: {', '.join(sorted(changes))}")
    return "updated"


def ensure_monitor(api, spec, index):
    spec = dict(spec)
    group = spec.pop("group", None)
    name = spec["name"]
    if name in index:
        return reconcile(api, index[name], spec)
    if group:
        spec["parent"] = ensure_group(api, group, index)
    spec["type"] = MonitorType(spec["type"])
    response = api.add_monitor(**spec)
    index[name] = {"id": response["monitorID"], "name": name}
    print(f"added monitor {name}")
    return "added"


def report(label, results):
    counts = (f"{results.count(state)} {state}" for state in STATES)
    print(f"{label}: {', '.join(counts)}")


def main():
    specs = read_specs(MONITORS_FILE)
    pages = read_specs(STATUS_PAGES_FILE)
    with UptimeKumaApi(URL) as api:
        print(f"admin account {ensure_admin(api)}")
        api.login(USER, PASSWORD)
        index = index_by_name(api)
        report("monitors", [ensure_monitor(api, spec, index) for spec in specs])
        slugs = {page["slug"] for page in api.get_status_pages()}
        report(
            "status pages",
            [ensure_status_page(api, page, specs, index, slugs) for page in pages],
        )
    return 0


if __name__ == "__main__":
    sys.exit(main())
