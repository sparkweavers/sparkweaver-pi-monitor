# Keys of a page spec that describe the repo's own wiring rather than a field
# Uptime Kuma stores. Everything else is pushed to the page as given.
LOCAL_KEYS = ("slug", "groups")


def build_sections(page, monitors, existing, index):
    """One section per monitor group named in the page spec, in file order."""
    ids = {
        section["name"]: section["id"] for section in existing if section.get("id")
    }
    sections = []
    for name in page.get("groups", []):
        members = [
            {"id": index[spec["name"]]["id"]}
            for spec in monitors
            if spec.get("group") == name and spec["name"] in index
        ]
        section = {"name": name, "monitorList": members}
        if name in ids:
            section["id"] = ids[name]
        sections.append(section)
    return sections


def shape(sections):
    """Sections reduced to what we control, so ordering changes are drift."""
    return [
        (section["name"], [monitor["id"] for monitor in section["monitorList"]])
        for section in sections
    ]


def reconcile(api, page, current, sections):
    changes = {
        key: value
        for key, value in page.items()
        if key not in LOCAL_KEYS and current.get(key) != value
    }
    if shape(sections) != shape(current["publicGroupList"]):
        changes["publicGroupList"] = sections
    if changes:
        api.save_status_page(page["slug"], **changes)
    return sorted(changes)


def ensure_status_page(api, page, monitors, index, slugs):
    slug = page["slug"]
    added = slug not in slugs
    if added:
        api.add_status_page(slug, page["title"])
    current = api.get_status_page(slug)
    sections = build_sections(page, monitors, current["publicGroupList"], index)
    changes = reconcile(api, page, current, sections)
    if added:
        print(f"added status page {slug}")
        return "added"
    if changes:
        print(f"updated status page {slug}: {', '.join(changes)}")
        return "updated"
    return "unchanged"
