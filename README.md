# sparkweaver-pi-monitor

One script that installs [Uptime Kuma](https://github.com/louislam/uptime-kuma) on a
Raspberry Pi, as a Docker container on port 3001.

## Install

On the Pi:

```
git clone https://github.com/sparkweavers/sparkweaver-pi-monitor.git && cd sparkweaver-pi-monitor && ./install.sh
```

It asks for your sudo password, because installing Docker needs root. Everything after
that runs unprivileged.

## What it does

Installs Docker and the Compose plugin if they are missing, enables the Docker service at
boot, adds you to the `docker` group, writes `/opt/uptime-kuma/docker-compose.yml`, starts
the container, and waits until the web interface answers before printing its URL.

Re-running the script upgrades to the latest 1.x image. Your monitor history is held in a
named volume and is not touched.

## Requirements

A 64-bit OS on `aarch64` or `x86_64`. The official Uptime Kuma image has no 32-bit build,
so the script stops rather than fail halfway through.

Port 3001 must be free. If something else already holds it, the script stops instead of
displacing it. Override with `PORT=8080 ./install.sh`.

## After installing

Open the printed URL and create the admin account straight away. Uptime Kuma has no
default credentials, so the first person to load that page chooses the password.

Monitors and notification channels are added in the web interface.

## Managing it

```
cd /opt/uptime-kuma && docker compose ps
```

```
cd /opt/uptime-kuma && docker compose logs -f
```

```
cd /opt/uptime-kuma && docker compose restart
```

## Settings

| Variable | Default | Purpose |
|---|---|---|
| `PORT` | `3001` | Host port the dashboard listens on |
| `INSTALL_DIR` | `/opt/uptime-kuma` | Where the compose file is written |
| `IMAGE` | `louislam/uptime-kuma:1` | Pinned to the 1.x line, so no surprise major upgrade |
