#!/usr/bin/env bash

if [[ ! -t 0 || ! -t 1 ]]; then
    echo "This installer must be run in an interactive terminal."
    exit 1
fi

set -euo pipefail

SERVER_IP="185.119.19.188"

FEED_PORT="31108"
MLAT_PORT="41113"
MLAT_RETURN_PORT="33106"

LOCAL_BEAST_PORT="30005"

SITE_URL="https://adsbitalia.djrexishere.it"

MLAT_REPO="https://github.com/wiedehopf/mlat-client.git"
MLAT_VENV="/opt/adsbitalia-mlat"
MLAT_BIN="${MLAT_VENV}/bin/mlat-client"

CONFIG_FILE="/etc/adsbitalia/feeder.conf"

REGISTER_URL="https://adsbitalia.djrexishere.it/api/register-feeder"
REGISTER_TOKEN="6oAEgkdPAYCn1QpgcU8pCNjb_pM3jBr6Zb9j2hKHnPZ4Obnn-RYrwz1o1kl43pEu"

PUBLIC_IP_SERVICES=(
    "https://api.ipify.org"
    "https://ifconfig.me"
    "https://icanhazip.com"
)

msg() {
    echo "[ADSB-Italia] $*"
}

detect_distro() {

    if [[ -f /etc/arch-release ]]; then
        DISTRO="arch"
    elif [[ -f /etc/debian_version ]]; then
        DISTRO="debian"
    else
        echo "Unsupported distribution."
        exit 1
    fi
}

install_packages() {

    msg "Installing dependencies..."

    if [[ "$DISTRO" == "arch" ]]; then

        sudo pacman -Syu --noconfirm --needed \
            whiptail \
            curl \
            git \
            python \
            python-pip \
            base-devel

    else

        sudo apt update

        sudo apt install -y \
            whiptail \
            curl \
            git \
            python3 \
            python3-pip \
            python3-venv \
            python3-setuptools \
            gcc \
            build-essential
    fi
}

show_welcome() {

    whiptail --title "ADSB-Italia Network" \
        --msgbox "Welcome to the ADSB-Italia installer.

This installer will configure:

- ADS-B feed forwarding
- MLAT client
- ADSB-Italia dedicated readsb feeder instance
- Automatic feeder registration

Your existing readsb/dump1090 installation will NOT be modified." \
        20 78
}

validate_port() {

    local port="$1"

    [[ "$port" =~ ^[0-9]+$ ]] && (( port >= 1 && port <= 65535 ))
}

collect_user_data() {

    FEEDER_NAME=$(whiptail \
        --inputbox "Enter your feeder name:" \
        10 60 \
        --title "Feeder Configuration" \
        3>&1 1>&2 2>&3) || exit 1

    LAT=$(whiptail \
        --inputbox "Enter your latitude:" \
        10 60 \
        --title "Coordinates" \
        3>&1 1>&2 2>&3) || exit 1

    LON=$(whiptail \
        --inputbox "Enter your longitude:" \
        10 60 \
        --title "Coordinates" \
        3>&1 1>&2 2>&3) || exit 1

    ALT=$(whiptail \
        --inputbox "Enter altitude in meters:" \
        10 60 \
        --title "Altitude" \
        3>&1 1>&2 2>&3) || exit 1

    LOCAL_BEAST_PORT=$(whiptail \
        --inputbox "Enter local Beast input port from your existing readsb/dump1090 installation:" \
        12 72 \
        "$LOCAL_BEAST_PORT" \
        --title "Local Beast Port" \
        3>&1 1>&2 2>&3) || exit 1

    [[ -n "$FEEDER_NAME" ]] || exit 1
    [[ -n "$LAT" ]] || exit 1
    [[ -n "$LON" ]] || exit 1
    [[ -n "$ALT" ]] || exit 1
    [[ -n "$LOCAL_BEAST_PORT" ]] || exit 1

    if ! validate_port "$LOCAL_BEAST_PORT"; then
        echo "Invalid local Beast port."
        exit 1
    fi
}

check_local_feed() {

    msg "Checking local Beast feed on localhost:${LOCAL_BEAST_PORT}..."

    if ! timeout 3 bash -c "</dev/tcp/127.0.0.1/${LOCAL_BEAST_PORT}" 2>/dev/null; then

        whiptail \
            --title "Local Beast feed not found" \
            --msgbox "No Beast feed detected on localhost:${LOCAL_BEAST_PORT}.

Please verify your readsb/dump1090 installation and try again." \
            12 72

        exit 1
    fi
}

save_config() {

    msg "Saving configuration..."

    sudo install -d -m 755 /etc/adsbitalia

    sudo tee "$CONFIG_FILE" >/dev/null <<EOF
FEEDER_NAME=$FEEDER_NAME
LAT=$LAT
LON=$LON
ALT=$ALT
LOCAL_BEAST_PORT=$LOCAL_BEAST_PORT
SERVER_IP=$SERVER_IP
FEED_PORT=$FEED_PORT
MLAT_PORT=$MLAT_PORT
MLAT_RETURN_PORT=$MLAT_RETURN_PORT
EOF

    sudo chmod 600 "$CONFIG_FILE"
}

install_mlat_client() {

    if [[ -x "$MLAT_BIN" ]]; then
        msg "MLAT client already installed."
        return
    fi

    msg "Installing MLAT client..."

    TMPDIR=$(mktemp -d)

    sudo mkdir -p "$MLAT_VENV"

    sudo python3 -m venv "$MLAT_VENV"

    sudo "$MLAT_VENV/bin/pip" install --upgrade \
        pip setuptools wheel

    git clone "$MLAT_REPO" "$TMPDIR/mlat-client"

    sudo "$MLAT_VENV/bin/pip" install \
        "$TMPDIR/mlat-client"

    sudo rm -rf "$TMPDIR"
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
        msg "Unable to detect public IP."
        return 0
    fi

    HOSTNAME_LOCAL=$(hostname -f 2>/dev/null || hostname)

    PAYLOAD=$(printf '{"user":"%s","host":"%s","hostname":"%s","beast_port":%s,"feed_port":%s,"feed_mode":"push","mlat_return_port":%s,"lat":"%s","lon":"%s","alt":"%s"}' \
        "$FEEDER_NAME" \
        "$PUBLIC_IP" \
        "$HOSTNAME_LOCAL" \
        "$LOCAL_BEAST_PORT" \
        "$FEED_PORT" \
        "$MLAT_RETURN_PORT" \
        "$LAT" \
        "$LON" \
        "$ALT")

    curl -kfsS \
        -H 'Content-Type: application/json' \
        -H "X-Register-Token: ${REGISTER_TOKEN}" \
        -d "$PAYLOAD" \
        "$REGISTER_URL" >/dev/null || true
}

write_feed_service() {

    msg "Creating ADSB-Italia feed service..."

    sudo tee /etc/systemd/system/adsbitalia-feed.service >/dev/null <<EOF
[Unit]
Description=ADSB-Italia Feed Service
Wants=network-online.target
After=network-online.target

[Service]
Type=simple

ExecStart=/usr/bin/readsb \\
  --net \\
  --net-only \\
  --net-bind-address 127.0.0.1 \\
  --net-connector=127.0.0.1,${LOCAL_BEAST_PORT},beast_in \\
  --net-bo-port ${FEED_PORT} \\
  --net-ro-size 1280 \\
  --net-ro-interval 0.05

Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
}

write_mlat_service() {

    msg "Creating ADSB-Italia MLAT service..."

    sudo tee /etc/systemd/system/adsbitalia-mlat.service >/dev/null <<EOF
[Unit]
Description=ADSB-Italia MLAT Service
Wants=network-online.target
After=network-online.target

[Service]
Type=simple

ExecStart=${MLAT_BIN} \\
  --input-type dump1090 \\
  --input-connect 127.0.0.1:${LOCAL_BEAST_PORT} \\
  --server ${SERVER_IP}:${MLAT_PORT} \\
  --user ${FEEDER_NAME} \\
  --lat ${LAT} \\
  --lon ${LON} \\
  --alt ${ALT} \\
  --results beast,listen,${MLAT_RETURN_PORT}

Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
}

enable_services() {

    msg "Enabling services..."

    sudo systemctl daemon-reload

    sudo systemctl enable --now adsbitalia-feed.service
    sudo systemctl enable --now adsbitalia-mlat.service
}

show_status() {

    FEED_STATE=$(systemctl is-active adsbitalia-feed.service || true)
    MLAT_STATE=$(systemctl is-active adsbitalia-mlat.service || true)

    whiptail \
        --title "Installation Completed" \
        --msgbox "ADSB-Italia feeder installation completed successfully.

Feed service: ${FEED_STATE}
MLAT service: ${MLAT_STATE}

Feed destination:
${SERVER_IP}:${FEED_PORT}

MLAT destination:
${SERVER_IP}:${MLAT_PORT}

Website:
${SITE_URL}" \
        20 78
}

main() {

    detect_distro
    install_packages
    show_welcome
    collect_user_data
    check_local_feed
    save_config
    install_mlat_client
    register_feeder
    write_feed_service
    write_mlat_service
    enable_services
    show_status
}

main "$@"
