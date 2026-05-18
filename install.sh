#!/usr/bin/env bash
set -euo pipefail

# Basic configuration
SERVER_IP="185.119.19.188"
MLAT_PORT="41113"
FEED_PORT="30004"
SITE_URL="https://adsbitalia.djrexishere.it"
MLAT_REPO="https://github.com/wiedehopf/mlat-client.git"
MLAT_VENV="/opt/adsbitalia-mlat"
MLAT_BIN="${MLAT_VENV}/bin/mlat-client"
CONFIG_FILE="/etc/adsbitalia/feeder.conf"
REGISTER_URL="https://adsbitalia.djrexishere.it/api/register-feeder"
REGISTER_TOKEN="6oAEgkdPAYCn1QpgcU8pCNjb_pM3jBr6Zb9j2hKHnPZ4Obnn-RYrwz1o1kl43pEu"
PUBLIC_IP_SERVICES=("https://api.ipify.org" "https://ifconfig.me" "https://icanhazip.com")

# Command‑line switches
NO_INTERACTIVE=""
SHOW_HELP=""

# Utility
require_cmd() {
    command -v "$1" >/dev/null 2>&1 || return 1
}

msg() {
    echo "[ADSB-Italia] $*"
}

detect_distro() {
    if [[ -f /etc/arch-release ]]; then
        DISTRO="arch"
    elif [[ -f /etc/debian_version ]]; then
        DISTRO="debian"
    else
        echo "Unsupported distribution. Supported: Debian/Ubuntu, Arch Linux."
        exit 1
    fi
}

install_packages() {
    msg "Installing dependencies..."
    if [[ "$DISTRO" == "arch" ]]; then
        sudo pacman -Syu --noconfirm --needed whiptail curl git socat python python-pip base-devel
    else
        sudo apt update
        sudo apt install -y whiptail curl git socat python3 python3-pip python3-setuptools python3-venv gcc
    fi
}

show_welcome() {
    whiptail --title "ADSB-Italia Network" \
        --msgbox "Welcome to the ADSB-Italia installer.\n\nThis script will configure:\n- ADS-B data forwarding\n- MLAT client setup\n- automatic feeder registration\n\nNo existing MLAT installation will be modified outside the dedicated service created by this script." 16 72 3>&1 1>&2 2>&3 || exit 1
}

check_whiptail() {
    if ! require_cmd whiptail; then
        echo "whiptail not installed. Please install whiptail first."
        echo "Alternatively, run the script with --no-interactive and set:"
        echo "  UTENTE, LAT, LON, ALT"
        echo "Example:"
        echo "  UTENTE=\"mio_nome\" LAT=\"44.8300\" LON=\"11.6200\" ALT=15 ./installer.sh --no-interactive"
        exit 1
    fi

    if ! echo "OK" | whiptail --title "Test" --msgbox "If you see this, press OK." 8 45 3>&1 1>&2 2>&3; then
        echo "whiptail test failed; your terminal may not support whiptail dialogs."
        echo "Try running the script from a different terminal, or use:"
        echo "  --no-interactive"
        echo "Example:"
        echo "  UTENTE=\"mio_nome\" LAT=\"44.8300\" LON=\"11.6200\" ALT=15 ./installer.sh --no-interactive"
        exit 1
    fi
}

collect_user_data() {
    UTENTE=$(whiptail --inputbox "Enter your feeder name:" 10 60 --title "User Configuration" 3>&1 1>&2 2>&3) || exit 1
    LAT=$(whiptail --inputbox "Enter your decimal latitude (example: 44.8300):" 10 60 --title "Coordinates" 3>&1 1>&2 2>&3) || exit 1
    LON=$(whiptail --inputbox "Enter your decimal longitude (example: 11.6200):" 10 60 --title "Coordinates" 3>&1 1>&2 2>&3) || exit 1
    ALT=$(whiptail --inputbox "Enter altitude in meters (example: 15):" 10 60 --title "Altitude" 3>&1 1>&2 2>&3) || exit 1

    [[ -n "$UTENTE" ]] || { echo "Feeder name cannot be empty."; exit 1; }
    [[ -n "$LAT" ]] || { echo "Latitude cannot be empty."; exit 1; }
    [[ -n "$LON" ]] || { echo "Longitude cannot be empty."; exit 1; }
    [[ -n "$ALT" ]] || { echo "Altitude cannot be empty."; exit 1; }
}

save_config() {
    msg "Saving local feeder configuration..."
    sudo install -d -m 755 /etc/adsbitalia
    sudo bash -c "cat > '$CONFIG_FILE' <<EOF
UTENTE=$(printf '%q' "$UTENTE")
LAT=$(printf '%q' "$LAT")
LON=$(printf '%q' "$LON")
ALT=$(printf '%q' "$ALT")
EOF"
    sudo chmod 600 "$CONFIG_FILE"
}

check_local_feed() {
    msg "Checking local Beast feed on localhost:30005..."
    if ! timeout 3 bash -c '</dev/tcp/127.0.0.1/30005' 2>/dev/null; then
        whiptail --title "Local feed not found" \
            --msgbox "No local Beast feed was found on localhost:30005.\n\nPlease start readsb or dump1090 first, then run this installer again." 12 70 3>&1 1>&2 2>&3
        exit 1
    fi
}

install_mlat_client() {
    if [[ -x "$MLAT_BIN" ]]; then
        msg "Dedicated mlat-client already present in $MLAT_BIN"
        return
    fi

    msg "Installing dedicated mlat-client virtual environment..."
    TMPDIR=$(mktemp -d)
    trap 'rm -rf "$TMPDIR"' EXIT

    sudo mkdir -p "$MLAT_VENV"
    sudo python3 -m venv "$MLAT_VENV"
    sudo "$MLAT_VENV/bin/pip" install --upgrade pip setuptools wheel

    git clone "$MLAT_REPO" "$TMPDIR/mlat-client"
    sudo "$MLAT_VENV/bin/pip" install "$TMPDIR/mlat-client"

    if ! [[ -x "$MLAT_BIN" ]]; then
        echo "mlat-client installation completed but binary was not found in the dedicated virtual environment."
        exit 1
    fi
}

detect_public_ip() {
    for url in "${PUBLIC_IP_SERVICES[@]}"; do
        PUBLIC_IP=$(curl -4fsS --max-time 10 "$url" 2>/dev/null | tr -d '[:space:]' || true)
        if [[ "$PUBLIC_IP" =~ ^([0-9]{1,3}\\.){3}[0-9]{1,3}$ ]]; then
            return 0
        fi
    done
    return 1
}

register_feeder() {
    msg "Registering feeder..."

    if ! detect_public_ip; then
        whiptail --title "Feeder registration failed" \
            --msgbox "Unable to detect this feeder's public IP address.\n\nInstallation can still continue, but registration must be completed manually on the server." 12 72 3>&1 1>&2 2>&3
        return 0
    fi

    HOSTNAME_LOCAL=$(hostname -f 2>/dev/null || hostname)

    PAYLOAD=$(printf '{"user":"%s","host":"%s","hostname":"%s","beast_port":30005,"lat":"%s","lon":"%s","alt":"%s"}' \
        "$UTENTE" "$PUBLIC_IP" "$HOSTNAME_LOCAL" "$LAT" "$LON" "$ALT")

    HTTP_CODE=$(curl -kfsS -o /tmp/adsbitalia-register.out -w '%{http_code}' \
        -H 'Content-Type: application/json' \
        -H "X-Register-Token: ${REGISTER_TOKEN}" \
        -d "$PAYLOAD" \
        "$REGISTER_URL" || true)

    if [[ "$HTTP_CODE" == "200" || "$HTTP_CODE" == "201" ]]; then
        msg "Feeder registration completed."
    else
        msg "Feeder registration failed (HTTP ${HTTP_CODE:-error})."
        msg "Continuing with local installation."
    fi
}

write_services() {
    msg "Creating systemd services..."

    cat <<EOF2 | sudo tee /etc/systemd/system/mlat-italia.service >/dev/null
[Unit]
Description=ADSB-Italia MLAT Client
Wants=network-online.target
After=network-online.target
StartLimitIntervalSec=300
StartLimitBurst=10

[Service]
Type=simple
ExecStart=${MLAT_BIN} --input-type dump1090 --input-connect localhost:30005 --server ${SERVER_IP}:${MLAT_PORT} --user ${UTENTE} --lat ${LAT} --lon ${LON} --alt ${ALT} --results beast,listen,30105
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF2

    cat <<EOF2 | sudo tee /etc/systemd/system/adsb-italia.service >/dev/null
[Unit]
Description=ADSB-Italia Beast Feed
Wants=network-online.target
After=network-online.target
StartLimitIntervalSec=300
StartLimitBurst=10

[Service]
Type=simple
ExecStart=/usr/bin/socat -u TCP:127.0.0.1:30005 TCP:${SERVER_IP}:${FEED_PORT}
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF2
}

enable_services() {
    msg "Enabling services..."
    sudo systemctl daemon-reload
    sudo systemctl enable --now mlat-italia.service
    sudo systemctl enable --now adsb-italia.service
}

show_status() {
    MLAT_STATE=$(systemctl is-active mlat-italia.service || true)
    FEED_STATE=$(systemctl is-active adsb-italia.service || true)

    whiptail --title "INSTALLATION COMPLETED" \
        --msgbox "Thank you ${UTENTE}!\n\nService status:\n- MLAT: ${MLAT_STATE}\n- ADS-B feed: ${FEED_STATE}\n\nAutomatic registration was attempted at:\n- ${REGISTER_URL}\n\nWebsite:\n- ${SITE_URL}" 18 74 3>&1 1>&2 2>&3
}

print_help() {
    cat <<EOF
ADSB-Italia Feeder Installer

Usage:
  ./installer.sh [OPTIONS]

Options:
  --no-interactive, --no-interactive-dialogs
    Run without whiptail dialogs, using environment variables:
      UTENTE, LAT, LON, ALT
    Example:
      UTENTE="mio_nome" LAT="44.8300" LON="11.6200" ALT=15 ./installer.sh --no-interactive

  --help
    Show this help message.

This script will:
  - Install required packages (whiptail, git, python3, socat, etc.)
  - Setup a dedicated mlat-client virtual environment
  - Register the feeder on the ADSB-Italia server (if reachable)
  - Create and enable two systemd services:
    - mlat-italia.service
    - adsb-italia.service
EOF
    exit 0
}

main() {
    # Parse flags
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --no-interactive|--no-interactive-dialogs)
                NO_INTERACTIVE=1
                shift
                ;;
            --help)
                SHOW_HELP=1
                shift
                ;;
            *)
                echo "Unknown option: $1"
                echo "Run with --help to see usage."
                exit 1
                ;;
        esac
    done

    [[ -n "${SHOW_HELP}" ]] && print_help

    # Global variables (also in no‑interactive mode)
    if [[ -z "${UTENTE:-}" ]]; then
        UTENTE=""
    fi
    if [[ -z "${LAT:-}" ]]; then
        LAT=""
    fi
    if [[ -z "${LON:-}" ]]; then
        LON=""
    fi
    if [[ -z "${ALT:-}" ]]; then
        ALT=""
    fi

    detect_distro
    install_packages

    if [[ -z "${NO_INTERACTIVE}" ]]; then
        check_whiptail  # already includes the message about --no-interactive
        show_welcome
        collect_user_data
    else
        [[ -n "$UTENTE"  ]] || { echo "Set UTENTE env var"; exit 1; }
        [[ -n "$LAT"     ]] || { echo "Set LAT env var";  exit 1; }
        [[ -n "$LON"     ]] || { echo "Set LON env var";  exit 1; }
        [[ -n "$ALT"     ]] || { echo "Set ALT env var";  exit 1; }
    fi

    save_config
    check_local_feed
    install_mlat_client
    register_feeder
    write_services
    enable_services
    show_status
}

main "$@"
