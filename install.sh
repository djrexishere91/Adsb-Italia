#!/usr/bin/env bash
if [[ ! -t 0 || ! -t 1 ]]; then
    echo "This installer must be run in an interactive terminal."
    exit 1
fi

set -euo pipefail

SERVER_IP="185.119.19.188"

MLAT_PORT="41113"
FEED_PORT="31108"
MLAT_RETURN_PORT="33106"

LOCAL_BEAST_PORT="30005"

SITE_URL="https://adsbitalia.djrexishere.it"

MLAT_REPO="https://github.com/wiedehopf/mlat-client.git"
MLAT_VENV="/opt/adsbitalia-mlat"
MLAT_BIN="${MLAT_VENV}/bin/mlat-client"

CONFIG_FILE="/etc/adsbitalia/feeder.conf"

REGISTER_URL="https://adsbitalia.djrexishere.it/api/register-feeder"
REGISTER_TOKEN="6oOEgkdPAYCn1QpgcU8pCNjb_pM3jBr6Zb9j2hKHnPZ4Obnn-RYrwz1o1kl43pEu"

PUBLIC_IP_SERVICES=("https://api.ipify.org" "https://ifconfig.me" "https://icanhazip.com")

msg(){ echo "[ADSB-Italia] $*"; }

detect_distro() {
    if [[ -f /etc/debian_version ]]; then
        DISTRO="debian"
    else
        DISTRO="arch"
    fi
}

install_packages() {
    msg "Installing dependencies (NO socat at all)..."

    if [[ "$DISTRO" == "arch" ]]; then
        sudo pacman -Syu --noconfirm --needed \
            whiptail curl git python python-pip base-devel
    else
        sudo apt update
        sudo apt install -y \
            whiptail curl git python3 python3-pip python3-venv gcc build-essential
    fi
}

# ----------------------------
# READSB FEEDER INSTANCE
# ----------------------------
install_readsb_feeder() {

    if command -v readsb-feeder >/dev/null 2>&1; then
        msg "readsb feeder already installed"
        return
    fi

    msg "Building readsb feeder instance..."

    TMP=$(mktemp -d)
    git clone https://github.com/wiedehopf/readsb.git "$TMP/readsb"

    cd "$TMP/readsb"
    make -j"$(nproc)"

    sudo install -m 755 readsb /usr/local/bin/readsb-feeder
}

write_readsb_service() {

    msg "Creating readsb feeder service..."

    sudo tee /etc/systemd/system/readsb-feeder.service >/dev/null <<EOF
[Unit]
Description=ADSB-Italia Readsb Feeder
After=network-online.target

[Service]
Type=simple

ExecStart=/usr/local/bin/readsb-feeder \
  --net \
  --net-only \
  --net-bind-address 127.0.0.1 \
  --net-sbs-in-port ${LOCAL_BEAST_PORT} \
  --net-bo-port ${FEED_PORT} \
  --write-json /run/readsb-feeder \
  --write-json-every 1

Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
}

# ----------------------------
# MLAT CLIENT
# ----------------------------
install_mlat_client() {

    if [[ -x "$MLAT_BIN" ]]; then return; fi

    msg "Installing MLAT client..."

    sudo python3 -m venv "$MLAT_VENV"
    sudo "$MLAT_VENV/bin/pip" install --upgrade pip setuptools wheel

    TMP=$(mktemp -d)
    git clone "$MLAT_REPO" "$TMP/mlat-client"
    sudo "$MLAT_VENV/bin/pip" install "$TMP/mlat-client"
}

write_mlat_service() {

    sudo tee /etc/systemd/system/adsbitalia-mlat.service >/dev/null <<EOF
[Unit]
Description=ADSB-Italia MLAT Service
After=network-online.target

[Service]
Type=simple

ExecStart=${MLAT_BIN} \
  --input-type dump1090 \
  --input-connect 127.0.0.1:${LOCAL_BEAST_PORT} \
  --server ${SERVER_IP}:${MLAT_PORT} \
  --results beast,listen,${MLAT_RETURN_PORT}

Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
}

# ----------------------------
# DIRECT FEED (NO SOCAT, NO RELAYS)
# ----------------------------
write_feed_service() {

    msg "Creating direct feed service (pure TCP)..."

    sudo tee /etc/systemd/system/adsbitalia-feed.service >/dev/null <<EOF
[Unit]
Description=ADSB-Italia Feed Service (direct readsb TCP stream)
After=network-online.target readsb-feeder.service

[Service]
Type=simple

ExecStart=/bin/bash -c 'while true; do nc ${SERVER_IP} ${FEED_PORT} < /dev/tcp/127.0.0.1/${FEED_PORT}; sleep 2; done'

Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
}

enable_services() {

    msg "Enabling services..."

    sudo systemctl daemon-reload

    sudo systemctl enable --now readsb-feeder.service
    sudo systemctl enable --now adsbitalia-mlat.service
    sudo systemctl enable --now adsbitalia-feed.service
}

main() {
    detect_distro
    install_packages
    install_readsb_feeder
    install_mlat_client
    write_readsb_service
    write_mlat_service
    write_feed_service
    enable_services

    msg "Installation completed (NO SOCAT anywhere)"
}

main "$@"
