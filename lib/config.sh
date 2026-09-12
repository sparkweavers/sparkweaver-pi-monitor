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

readonly KUMA_ADMIN_USER="${KUMA_ADMIN_USER:-}"
readonly KUMA_ADMIN_PASSWORD="${KUMA_ADMIN_PASSWORD:-}"
readonly MONITORS_FILE="${MONITORS_FILE:-$SCRIPT_DIR/monitors.json}"
readonly PYTHON_IMAGE="${PYTHON_IMAGE:-python:3.12-slim}"
readonly API_PACKAGE="${API_PACKAGE:-uptime-kuma-api}"
