# sparkweaver-pi-monitor

Creating a selfhosted Uptime Kuma instance on Raspberry Pi.

This Respository is optimized for @BirgitPohl 's Raspberry Pi.

## First-time setup

```
cd ~/sparkweaver-pi-monitor && KUMA_ADMIN_USER='admin-name' KUMA_ADMIN_PASSWORD='admin-password' NETBIRD_SETUP_KEY='reusable-setup-key' ./install.sh
```

## What is provisioned

`monitors.json` holds the checks and the group each one belongs to.
`status-pages.json` holds the status pages, each naming the monitor groups it
shows. Both are pushed on every run, so editing a file and re-running is how you
change what is watched and what is published.

A status page is served without a login, so treat it as readable by anyone who
can reach the host. Each project gets its own page, because publishing one
project's services on another's page hands them to the wrong audience.

A group reaches a status page only when a page names it, so a new group in
`monitors.json` is half the job. A group that is missing from the dashboard or a
page is never a reason to wipe the volume: a re-run creates the group, moves
existing monitors into it and leaves every bit of history alone.

A monitor name has to be unique across every group, because a re-run matches
what is already there by name alone. Prefix the name with the project when a
second group watches the same kind of service.

## Link Signal for alerts

A notification is picked per monitor and a group does not pass its own down to
the members, so a new group needs the notification ticked on each of its
monitors. A re-run of `install.sh` leaves those ticks alone.

```
cd ~/sparkweaver-pi-monitor && ./link-signal.sh
```

## Start it again after a stop

The container restarts itself on boot, so a reboot needs nothing. This is for the
case where it was stopped by hand and you want it back without re-provisioning.

```
cd ~/sparkweaver-pi-monitor && ./start.sh
```

## Update Uptime Kuma

```
cd ~/sparkweaver-pi-monitor && ./update.sh
```

Coming from 1.x rewrites the database and cannot be undone, so prefix that one
run with `ALLOW_MAJOR_UPGRADE=1`. The volume is backed up first.

Provisioning does not work on 2.x yet, so `install.sh` stops at that step.
`start.sh` and `update.sh` are unaffected.
