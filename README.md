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
can reach the host.

## Link Signal for alerts

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
