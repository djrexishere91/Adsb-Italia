#!/usr/bin/env bash
set -euo pipefail

MLAT_SERVICE="mlat-italia.service"
ADSB_SERVICE="adsb-italia.service"
MLAT_VENV="/opt/adsbitalia-mlat"
MLAT_UNIT="/etc/systemd/system/${MLAT_SERVICE}"
ADSB_UNIT="/etc/systemd/system/${ADSB_SERVICE}"

msg() {
    echo "[ADSB-Italia] $*"
}

require_root() {
    if [[ "${EUID}" -ne 0 ]]; then
        echo "Please run this script as root."
        exit 1
    fi
}

stop_disable_remove_unit() {
    local svc="$1"
    local unit="$2"

    if systemctl list-unit-files | grep -q "^${svc}"; then
        msg "Stopping ${svc}..."
        systemctl stop "$svc" 2>/dev/null || true
        msg "Disabling ${svc}..."
        systemctl disable "$svc" 2>/dev/null || true
    fi

    if [[ -f "$unit" ]]; then
        msg "Removing unit file $unit..."
        rm -f "$unit"
    fi

    if [[ -L "/etc/systemd/system/multi-user.target.wants/${svc}" ]]; then
        rm -f "/etc/systemd/system/multi-user.target.wants/${svc}"
    fi
}

main() {
    require_root

    stop_disable_remove_unit "$MLAT_SERVICE" "$MLAT_UNIT"
    stop_disable_remove_unit "$ADSB_SERVICE" "$ADSB_UNIT"

    msg "Reloading systemd daemon..."
    systemctl daemon-reload

    if [[ -d "$MLAT_VENV" ]]; then
        msg "Removing dedicated MLAT virtual environment..."
        rm -rf "$MLAT_VENV"
    fi

    msg "Uninstall complete."
    msg "Local readsb/dump1090 was not modified."
}

main "$@"
