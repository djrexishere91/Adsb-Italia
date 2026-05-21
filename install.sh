#!/usr/bin/env bash
if [[ ! -t 0 || ! -t 1 ]]; then
    echo "This installer must be run in an interactive terminal."
    exit 1
fi
set -euo pipefail

SERVER_IP="185.119.19.188"
MLAT_PORT="41113"
FEED_PORT="31106"
MLAT_RETURN_PORT="33106"
LOCAL_BEAST_PORT="30005"
SITE_URL="https://adsbitalia.djrexishere.it"
MLAT_REPO="https://github.com/wiedehopf/mlat-client.git"
MLAT_VENV="/opt/adsbitalia-mlat"
MLAT_BIN="${MLAT_VENV}/bin/mlat-client"
CONFIG_FILE="/etc/adsbitalia/feeder.conf"
REGISTER_URL="https://adsbitalia.djrexishere.it/api/register-feeder"
REGISTER_TOKEN="6oAEgkdPAYCn1QpgcU8pCNjb_pM3jBr6Zb9j2hKHnPZ4Obnn-RYrwz1o1kl43pEu"
PUBLIC_IP_SERVICES=("https://api.ipify.org" "https://ifconfig.me" "https://icanhazip.com")

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
        --msgbox "Welcome to the ADSB-Italia installer.\n\nThis script will configure:\n- ADS-B push feed forwarding to ADSBItalia on port ${FEED_PORT}\n- MLAT client setup\n- MLAT results exposed locally on port ${MLAT_RETURN_PORT}\n- automatic feeder registration\n\nThis installer uses PUSH mode for ADS-B feed delivery: your feeder sends data outbound to the ADSBItalia VPS, so no inbound router port forwarding is required on your side." 20 78
}

validate_port() {
    local port="$1"
    [[ "$port" =~ ^[0-9]+$ ]] && (( port >= 1 && port <= 65535 ))
}

collect_user_data() {
    UTENTE=$(whiptail --inputbox "Enter your feeder name:" 10 60 --title "User Configuration" 3>&1 1>&2 2>&3) || exit 1
    LAT=$(whiptail --inputbox "Enter your decimal latitude (example: 44.8300):" 10 60 --title "Coordinates" 3>&1 1>&2 2>&3) || exit 1
    LON=$(whiptail --inputbox "Enter your decimal longitude (example: 11.6200):" 10 60 --title "Coordinates" 3>&1 1>&2 2>&3) || exit 1
    ALT=$(whiptail --inputbox "Enter altitude in meters (example: 15):" 10 60 --title "Altitude" 3>&1 1>&2 2>&3) || exit 1
    LOCAL_BEAST_PORT=$(whiptail --inputbox "Enter local Beast port from readsb/dump1090:" 10 70 "$LOCAL_BEAST_PORT" --title "Local Beast Port" 3>&1 1>&2 2>&3) || exit 1

    [[ -n "$UTENTE" ]] || { echo "Feeder name cannot be empty."; exit 1; }
    [[ -n "$LAT" ]] || { echo "Latitude cannot be empty."; exit 1; }
    [[ -n "$LON" ]] || { echo "Longitude cannot be empty."; exit 1; }
    [[ -n "$ALT" ]] || { echo "Altitude cannot be empty."; exit 1; }
    [[ -n "$LOCAL_BEAST_PORT" ]] || { echo "Local Beast port cannot be empty."; exit 1; }

    if ! validate_port "$LOCAL_BEAST_PORT"; then
        echo "Invalid local Beast port: $LOCAL_BEAST_PORT"
        exit 1
    fi
}

check_local_feed() {
    msg "Checking local Beast feed on localhost:${LOCAL_BEAST_PORT}..."
    if ! timeout 3 bash -c "</dev/tcp/127.0.0.1/${LOCAL_BEAST_PORT}" 2>/dev/null; then
        whiptail --title "Local feed not found" \
            --msgbox "No local Beast feed was found on localhost:${LOCAL_BEAST_PORT}.\n\nPlease start readsb or dump1090 first, or enter the correct local Beast port, then run this installer again." 12 76
        exit 1
    fi
}

check_server_reachability() {
    msg "Checking ADSBItalia server reachability on ${SERVER_IP}:${FEED_PORT}..."
    if ! socat -T3 /dev/null TCP:${SERVER_IP}:${FEED_PORT},connect-timeout=3 >/dev/null 2>&1; then
        whiptail --title "Server unreachable" \
            --msgbox "The ADSBItalia server ${SERVER_IP}:${FEED_PORT} is not reachable from this feeder.\n\nPlease verify that the VPS listener is active and that outbound connectivity is available, then run the installer again." 12 76
        exit 1
    fi
}

save_config() {
    msg "Saving local feeder configuration..."
    sudo install -d -m 755 /etc/adsbitalia
    sudo tee "$CONFIG_FILE" >/dev/null <<EOF
UTENTE=$UTENTE
LAT=$LAT
LON=$LON
ALT=$ALT
SERVER_IP=$SERVER_IP
MLAT_PORT=$MLAT_PORT
FEED_PORT=$FEED_PORT
MLAT_RETURN_PORT=$MLAT_RETURN_PORT
LOCAL_BEAST_PORT=$LOCAL_BEAST_PORT
FEED_MODE=push
EOF
    sudo chmod 600 "$CONFIG_FILE"
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
        if [[ "$PUBLIC_IP" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
            return 0
        fi
    done
    return 1
}

register_feeder() {
    msg "Registering feeder..."

    if ! detect_public_ip; then
        whiptail --title "Feeder registration failed" \
            --msgbox "Unable to detect this feeder's public IP address.\n\nInstallation can still continue, but registration must be completed manually on the server." 12 72
        return 0
    fi

    HOSTNAME_LOCAL=$(hostname -f 2>/dev/null || hostname)

    PAYLOAD=$(printf '{"user":"%s","host":"%s","hostname":"%s","beast_port":%s,"feed_port":%s,"feed_mode":"push","mlat_return_port":%s,"lat":"%s","lon":"%s","alt":"%s"}' \
        "$UTENTE" "$PUBLIC_IP" "$HOSTNAME_LOCAL" "$LOCAL_BEAST_PORT" "$FEED_PORT" "$MLAT_RETURN_PORT" "$LAT" "$LON" "$ALT")

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
ExecStart=${MLAT_BIN} --input-type dump1090 --input-connect localhost:${LOCAL_BEAST_PORT} --server ${SERVER_IP}:${MLAT_PORT} --user ${UTENTE} --lat ${LAT} --lon ${LON} --alt ${ALT} --results beast,listen,${MLAT_RETURN_PORT}
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF2

    cat <<EOF2 | sudo tee /etc/systemd/system/adsb-italia.service >/dev/null
[Unit]
Description=ADSB-Italia Beast Feed (push mode)
Wants=network-online.target
After=network-online.target
StartLimitIntervalSec=300
StartLimitBurst=10

[Service]
Type=simple
ExecStart=/usr/bin/socat -u TCP:127.0.0.1:${LOCAL_BEAST_PORT} TCP:${SERVER_IP}:${FEED_PORT}
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
        --msgbox "Thank you ${UTENTE}!\n\nService status:\n- MLAT: ${MLAT_STATE}\n- ADS-B feed: ${FEED_STATE}\n\nFeed mode:\n- PUSH to ${SERVER_IP}:${FEED_PORT}\n- Local Beast source: localhost:${LOCAL_BEAST_PORT}\n- Local MLAT results: localhost:${MLAT_RETURN_PORT}\n\nAutomatic registration was attempted at:\n- ${REGISTER_URL}\n\nWebsite:\n- ${SITE_URL}" 22 78
}

main() {
    detect_distro
    install_packages
    show_welcome
    collect_user_data
    check_local_feed
    check_server_reachability
    save_config
    install_mlat_client
    register_feeder
    write_services
    enable_services
    show_status
}

main "$@"
