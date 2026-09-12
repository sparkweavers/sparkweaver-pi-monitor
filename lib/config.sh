#!/usr/bin/env bash

readonly INSTALL_DIR="${INSTALL_DIR:-/opt/uptime-kuma}"
readonly IMAGE="${IMAGE:-louislam/uptime-kuma:1}"
readonly PORT="${PORT:-3001}"
readonly CONTAINER="${CONTAINER:-uptime-kuma}"
readonly VOLUME="${VOLUME:-uptime-kuma-data}"
readonly DOCKER_INSTALL_URL="${DOCKER_INSTALL_URL:-https://get.docker.com}"

readonly CONTAINER_PORT=3001
readonly WAIT_ATTEMPTS=60
readonly WAIT_INTERVAL=2
readonly SUPPORTED_ARCHS=(aarch64 arm64 x86_64 amd64)
readonly HEALTHY_CODES=(200 302)
readonly MANAGE_COMMANDS=(ps "logs -f" restart)

readonly NETBIRD_SETUP_KEY="${NETBIRD_SETUP_KEY:-}"
readonly NETBIRD_INSTALL_URL="${NETBIRD_INSTALL_URL:-https://pkgs.netbird.io/install.sh}"
readonly NETBIRD_WAIT_ATTEMPTS=10
readonly TUNNEL_PEER_FQDN="${TUNNEL_PEER_FQDN:-database-server.netbird.cloud}"
readonly TUNNEL_HOSTNAMES=(supabase.sparkweaver.app supabase-staging.sparkweaver.app)

readonly DATA_MOUNT=/app/data
readonly DATABASE_FILE=kuma.db
readonly BACKUP_DIR="${BACKUP_DIR:-$HOME/uptime-kuma-backups}"
readonly BACKUP_IMAGE="${BACKUP_IMAGE:-alpine:3.20}"
readonly BACKUP_KEEP="${BACKUP_KEEP:-5}"
readonly ALLOW_MAJOR_UPGRADE="${ALLOW_MAJOR_UPGRADE:-0}"

readonly KUMA_ADMIN_USER="${KUMA_ADMIN_USER:-}"
readonly KUMA_ADMIN_PASSWORD="${KUMA_ADMIN_PASSWORD:-}"
readonly MONITORS_FILE="${MONITORS_FILE:-$SCRIPT_DIR/monitors.json}"
readonly PYTHON_IMAGE="${PYTHON_IMAGE:-python:3.12-slim}"
readonly API_PACKAGE="${API_PACKAGE:-uptime-kuma-api}"
