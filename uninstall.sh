#!/usr/bin/env bash
set -euo pipefail

FEED_SERVICE="adsbitalia-feed.service"
MLAT_SERVICE="adsbitalia-mlat.service"

FEED_UNIT="/etc/systemd/system/${FEED_SERVICE}"
MLAT_UNIT="/etc/systemd/system/${MLAT_SERVICE}"

MLAT_VENV="/opt/adsbitalia-mlat"

CONFIG_DIR="/etc/adsbitalia"

msg() {
    echo "[ADSB-Italia] $*"
}

require_root() {
    if [[ "${EUID}" -ne 0 ]]; then
        echo "Please run this script as root."
        exit 1
    fi
}

remove_service() {

    local service="$1"
    local unit="$2"

    if systemctl list-unit-files | grep -q "^${service}"; then

        msg "Stopping ${service}..."
        systemctl stop "${service}" 2>/dev/null || true

        msg "Disabling ${service}..."
        systemctl disable "${service}" 2>/dev/null || true
    fi

    if [[ -f "${unit}" ]]; then
        msg "Removing ${unit}..."
        rm -f "${unit}"
    fi

    if [[ -L "/etc/systemd/system/multi-user.target.wants/${service}" ]]; then
        rm -f "/etc/systemd/system/multi-user.target.wants/${service}"
    fi
}

main() {

    require_root

    msg "Removing ADSB-Italia services..."

    remove_service "${FEED_SERVICE}" "${FEED_UNIT}"
    remove_service "${MLAT_SERVICE}" "${MLAT_UNIT}"

    msg "Reloading systemd..."
    systemctl daemon-reload

    if [[ -d "${MLAT_VENV}" ]]; then
        msg "Removing MLAT virtual environment..."
        rm -rf "${MLAT_VENV}"
    fi

    if [[ -d "${CONFIG_DIR}" ]]; then
        msg "Removing ADSB-Italia configuration..."
        rm -rf "${CONFIG_DIR}"
    fi

    msg "Cleanup completed."
    msg "Your main readsb/dump1090 installation was NOT modified."
}

main "$@"
