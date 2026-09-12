# sparkweaver-pi-monitor

Installs [Uptime Kuma](https://github.com/louislam/uptime-kuma) on a Raspberry Pi as a
Docker container, and provisions its monitors from `monitors.json`.

## Install

```
./install.sh
```

Asks for your sudo password, because installing Docker needs root. Re-running upgrades
the image and adds any new monitor, leaving existing data and monitors alone.

To create the admin account at the same time, set a password. The leading space keeps it
out of shell history.

```
 KUMA_ADMIN_PASSWORD='choose-one' ./install.sh
```

Without that variable the admin account is not provisioned and you create it in the
browser. Uptime Kuma has no default credentials, so the first visitor to the dashboard
sets the password.

## Monitors

`monitors.json` holds them. `group` is optional and nests the monitor under a group of
that name, which is created if it does not exist. Monitors are matched by `name`, so
re-running never duplicates one. See `monitors.example.json`.

```json
{
  "type": "http",
  "name": "Backend production",
  "url": "https://backend.sparkweaver.app/api",
  "group": "Sparkweaver",
  "interval": 60,
  "accepted_statuscodes": ["401"]
}
```

A non-200 expectation is often the right one. A 401 from an authenticated endpoint proves
the proxy, the process and the auth layer are all alive.

## Settings

| Variable | Default | Purpose |
|---|---|---|
| `PORT` | `3001` | Host port for the dashboard |
| `INSTALL_DIR` | `/opt/uptime-kuma` | Where the compose file is written |
| `IMAGE` | `louislam/uptime-kuma:1` | Pinned to 1.x |
| `MONITORS_FILE` | `./monitors.json` | Monitor definitions |
| `KUMA_ADMIN_USER` | `admin` | Admin account name |
| `KUMA_ADMIN_PASSWORD` | unset | Provisioning is skipped while unset |
| `PYTHON_IMAGE` | `python:3.12-slim` | Image the provisioning runs in |

## Requirements

A 64-bit OS on `aarch64` or `x86_64`. There is no 32-bit Uptime Kuma image, so the script
stops rather than fail partway.

Port 3001 must be free. If something else holds it, the script stops instead of
displacing it.

Provisioning runs inside a `--rm` container rather than a virtual environment, so nothing
is installed into the host's Python.

## Managing it

```
cd /opt/uptime-kuma && docker compose ps
```

```
cd /opt/uptime-kuma && docker compose logs -f
```

Monitor history lives in the `uptime-kuma-data` volume and survives `docker compose down`.
