#!/usr/bin/env bash
set -euo pipefail

if [[ ! -t 0 || ! -t 1 ]]; then
    echo "This installer must be run in an interactive terminal."
    exit 1
fi

# ----------------------------
# CONFIG
# ----------------------------
SERVER_IP="185.119.19.188"
FEED_PORT="31108"
MLAT_PORT="41113"
MLAT_RETURN_PORT="33106"

SITE_URL="https://adsbitalia.djrexishere.it"

MLAT_REPO="https://github.com/wiedehopf/mlat-client.git"
MLAT_VENV="/opt/adsbitalia-mlat"
MLAT_BIN="${MLAT_VENV}/bin/mlat-client"

INSTALL_PREFIX="/usr/local/bin"
READSB_ADSBI="${INSTALL_PREFIX}/readsb-adsbitalia"

CONFIG_FILE="/etc/adsbitalia/feeder.conf"

PUBLIC_IP_SERVICES=("https://api.ipify.org" "https://ifconfig.me" "https://icanhazip.com")

# ----------------------------
msg(){ echo "[ADSB-Italia] $*"; }

# ----------------------------
detect_distro() {
    if [[ -f /etc/debian_version ]]; then
        DISTRO="debian"
    else
        DISTRO="arch"
    fi
}

# ----------------------------
install_packages() {
    msg "Installing dependencies..."

    if [[ "$DISTRO" == "arch" ]]; then
        sudo pacman -Syu --noconfirm --needed \
            git curl whiptail python python-pip base-devel
    else
        sudo apt update
        sudo apt install -y \
            git curl whiptail python3 python3-pip python3-venv build-essential
    fi
}

# ----------------------------
collect_user_data() {
    UTENTE=$(whiptail --inputbox "Feeder name:" 10 60 3>&1 1>&2 2>&3)
    LOCAL_BEAST_PORT=$(whiptail --inputbox "Porta BEAST locale readsb/dump1090 (es 30005):" 10 60 "30005" 3>&1 1>&2 2>&3)
    SERVER_PORT="31108"

    [[ -n "$UTENTE" ]] || exit 1
    [[ -n "$LOCAL_BEAST_PORT" ]] || exit 1
}

# ----------------------------
check_local_feed() {
    msg "Checking local feed on 127.0.0.1:${LOCAL_BEAST_PORT}..."
    timeout 2 bash -c "</dev/tcp/127.0.0.1/${LOCAL_BEAST_PORT}" || {
        echo "No local readsb/dump1090 feed found"
        exit 1
    }
}

# ----------------------------
install_sidecar_readsb() {
    msg "Installing ADSBItalia sidecar readsb..."

    TMP=$(mktemp -d)
    git clone https://github.com/wiedehopf/readsb.git "$TMP/readsb"

    cd "$TMP/readsb"
    make -j"$(nproc)"

    sudo install -m 755 readsb "$READSB_ADSBI"
}

# ----------------------------
install_mlat_client() {
    if [[ -x "$MLAT_BIN" ]]; then
        msg "MLAT already installed"
        return
    fi

    msg "Installing MLAT client..."

    sudo python3 -m venv "$MLAT_VENV"
    sudo "$MLAT_VENV/bin/pip" install --upgrade pip setuptools wheel

    TMP=$(mktemp -d)
    git clone "$MLAT_REPO" "$TMP/mlat-client"
    sudo "$MLAT_VENV/bin/pip" install "$TMP/mlat-client"
}

# ----------------------------
write_sidecar_service() {

    msg "Creating ADSBItalia sidecar readsb service..."

    sudo tee /etc/systemd/system/adsbitalia-sidecar.service >/dev/null <<EOF
[Unit]
Description=ADSBItalia Sidecar Readsb
After=network-online.target

[Service]
Type=simple

ExecStart=${READSB_ADSBI} \
  --net \
  --net-only \
  --net-connect 127.0.0.1:${LOCAL_BEAST_PORT} \
  --net-beast-reduce-out \
  --net-ro-size 5000 \
  --net-ro-interval 0.2 \
  --net-heartbeat 30 \
  --forward-addr ${SERVER_IP}:${FEED_PORT}

Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
}

# ----------------------------
write_mlat_service() {

    msg "Creating MLAT service..."

    sudo tee /etc/systemd/system/adsbitalia-mlat.service >/dev/null <<EOF
[Unit]
Description=ADSBItalia MLAT Client
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
enable_services() {
    msg "Enabling services..."

    sudo systemctl daemon-reload
    sudo systemctl enable --now adsbitalia-sidecar.service
    sudo systemctl enable --now adsbitalia-mlat.service
}

# ----------------------------
show_done() {
    echo ""
    echo "ADSBItalia V2 installed"
    echo "Sidecar readsb -> VPS:${FEED_PORT}"
    echo "MLAT -> active"
    echo "Local input -> ${LOCAL_BEAST_PORT}"
    echo ""
    echo "DONE"
}

# ----------------------------
main() {
    detect_distro
    install_packages
    collect_user_data
    check_local_feed
    install_sidecar_readsb
    install_mlat_client
    write_sidecar_service
    write_mlat_service
    enable_services
    show_done
}

main "$@"
