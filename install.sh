#!/usr/bin/env bash

if [[ ! -t 0 || ! -t 1 ]]; then
    echo "This installer must be run in an interactive terminal."
    exit 1
fi

set -euo pipefail

# ADSBItalia public DNS endpoints
FEED_HOST="feed.adsbitalia.it"
MLAT_HOST="mlat.adsbitalia.it"

# ADSBItalia ports
FEED_PORT="31108"
MLAT_PORT="41113"
MLAT_RETURN_PORT="33106"

# Default local Beast OUT port from existing readsb/dump1090/ultrafeeder
LOCAL_BEAST_PORT_DEFAULT="30005"

SITE_URL="https://adsbitalia.it"

# MLAT client
MLAT_REPO="https://github.com/wiedehopf/mlat-client.git"
MLAT_VENV="/opt/adsbitalia-mlat"
MLAT_BIN="${MLAT_VENV}/bin/mlat-client"

# Config
CONFIG_DIR="/etc/adsbitalia"
CONFIG_FILE="${CONFIG_DIR}/feeder.conf"

# Registration API
REGISTER_URL="https://adsbitalia.it/api/register-feeder"

PUBLIC_IP_SERVICES=(
    "https://api.ipify.org"
    "https://ifconfig.me"
    "https://icanhazip.com"
)

msg() {
    echo "[ADSBItalia] $*"
}

fatal() {
    echo "[ADSBItalia] ERROR: $*" >&2
    exit 1
}

detect_distro() {
    if [[ -f /etc/arch-release ]]; then
        DISTRO="arch"
    elif [[ -f /etc/debian_version ]]; then
        DISTRO="debian"
    else
        fatal "Unsupported distribution. Supported: Debian/Ubuntu/Raspberry Pi OS/Arch."
    fi
}

install_packages() {
    msg "Installing dependencies..."

    if [[ "$DISTRO" == "arch" ]]; then
        sudo pacman -Syu --noconfirm --needed \
            whiptail curl git python python-pip base-devel iproute2 socat
    else
        sudo apt update
        sudo apt install -y \
            whiptail curl git python3 python3-pip python3-venv \
            python3-setuptools gcc build-essential iproute2 socat
    fi
}

load_existing_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        # shellcheck disable=SC1090
        source "$CONFIG_FILE" || true
    fi
}

show_welcome() {
    whiptail --title "ADSBItalia Network" \
        --msgbox "Welcome to the ADSBItalia installer.

This installer will configure:

- ADS-B feed forwarding to ADSBItalia
- MLAT client
- ADSBItalia systemd services
- Automatic feeder registration with a unique feeder identity

Your existing readsb/dump1090/ultrafeeder installation will NOT be modified.

The installer will use DNS endpoints:

Feed:
${FEED_HOST}:${FEED_PORT}

MLAT:
${MLAT_HOST}:${MLAT_PORT}" \
        24 78
}

validate_port() {
    local port="$1"
    [[ "$port" =~ ^[0-9]+$ ]] && (( port >= 1 && port <= 65535 ))
}

validate_float() {
    local value="$1"
    [[ "$value" =~ ^-?[0-9]+([.][0-9]+)?$ ]]
}

validate_feeder_name() {
    local name="$1"
    [[ "$name" =~ ^[A-Za-z0-9._-]+$ ]]
}

normalize_number() {
    local value="$1"
    value="${value//,/.}"
    echo "$value"
}

generate_feeder_identity() {
    sudo install -d -m 755 "$CONFIG_DIR"

    if [[ -z "${FEEDER_ID:-}" ]]; then
        if [[ -f /proc/sys/kernel/random/uuid ]]; then
            FEEDER_ID=$(cat /proc/sys/kernel/random/uuid)
        else
            FEEDER_ID=$(python3 - <<'PY'
import uuid
print(uuid.uuid4())
PY
)
        fi
    fi

    if [[ -z "${FEEDER_TOKEN:-}" ]]; then
        FEEDER_TOKEN=$(python3 - <<'PY'
import secrets
print(secrets.token_urlsafe(48))
PY
)
    fi
}

collect_user_data() {
    local feeder_default="${FEEDER_NAME:-}"
    local lat_default="${LAT:-}"
    local lon_default="${LON:-}"
    local alt_default="${ALT:-}"
    local beast_default="${LOCAL_BEAST_PORT:-$LOCAL_BEAST_PORT_DEFAULT}"

    FEEDER_NAME=$(whiptail --inputbox "Enter your feeder name.

Allowed characters:
A-Z a-z 0-9 . _ -

Spaces will be converted to underscores." \
        14 72 \
        "$feeder_default" \
        --title "Feeder Configuration" \
        3>&1 1>&2 2>&3) || exit 1

    FEEDER_NAME="${FEEDER_NAME// /_}"

    LAT=$(whiptail --inputbox "Enter your latitude.

Example:
44.8040" \
        12 60 \
        "$lat_default" \
        --title "Coordinates" \
        3>&1 1>&2 2>&3) || exit 1

    LON=$(whiptail --inputbox "Enter your longitude.

Example:
11.9730" \
        12 60 \
        "$lon_default" \
        --title "Coordinates" \
        3>&1 1>&2 2>&3) || exit 1

    ALT=$(whiptail --inputbox "Enter altitude in meters.

Example:
5" \
        12 60 \
        "$alt_default" \
        --title "Altitude" \
        3>&1 1>&2 2>&3) || exit 1

    LOCAL_BEAST_PORT=$(whiptail \
        --inputbox "Enter local Beast OUT port from your existing readsb/dump1090/ultrafeeder installation.

Common examples:
30005
30006
30105
31005

Any custom local Beast OUT port is accepted." \
        18 72 \
        "$beast_default" \
        --title "Local Beast OUT Port" \
        3>&1 1>&2 2>&3) || exit 1

    LAT=$(normalize_number "$LAT")
    LON=$(normalize_number "$LON")
    ALT=$(normalize_number "$ALT")

    [[ -n "$FEEDER_NAME" ]] || fatal "Feeder name cannot be empty."
    [[ -n "$LAT" ]] || fatal "Latitude cannot be empty."
    [[ -n "$LON" ]] || fatal "Longitude cannot be empty."
    [[ -n "$ALT" ]] || fatal "Altitude cannot be empty."
    [[ -n "$LOCAL_BEAST_PORT" ]] || fatal "Local Beast port cannot be empty."

    if ! validate_feeder_name "$FEEDER_NAME"; then
        whiptail \
            --title "Invalid feeder name" \
            --msgbox "Invalid feeder name.

Allowed characters:
A-Z a-z 0-9 . _ -

Please run the installer again." \
            13 72
        exit 1
    fi

    if ! validate_float "$LAT"; then
        fatal "Invalid latitude."
    fi

    if ! validate_float "$LON"; then
        fatal "Invalid longitude."
    fi

    if ! validate_float "$ALT"; then
        fatal "Invalid altitude."
    fi

    if ! validate_port "$LOCAL_BEAST_PORT"; then
        fatal "Invalid local Beast port."
    fi
}

check_local_feed() {
    msg "Checking local Beast OUT feed on localhost:${LOCAL_BEAST_PORT}..."

    if ! timeout 3 bash -c "</dev/tcp/127.0.0.1/${LOCAL_BEAST_PORT}" 2>/dev/null; then
        whiptail \
            --title "Local Beast feed not found" \
            --msgbox "No Beast feed detected on localhost:${LOCAL_BEAST_PORT}.

The selected port must be a local Beast OUT port from your existing decoder.

Common examples:
30005
30006
30105
31005

Please verify your readsb/dump1090/ultrafeeder installation and try again." \
            19 72
        exit 1
    fi

    msg "Local Beast feed reachable on port ${LOCAL_BEAST_PORT}."
}

check_adsbitalia_dns() {
    msg "Checking ADSBItalia DNS records..."

    if ! getent ahostsv4 "$FEED_HOST" >/dev/null 2>&1; then
        whiptail \
            --title "DNS error" \
            --msgbox "Unable to resolve:

${FEED_HOST}

Please verify that the DNS record exists and is set to DNS only, not proxied through Cloudflare." \
            14 72
        exit 1
    fi

    if ! getent ahostsv4 "$MLAT_HOST" >/dev/null 2>&1; then
        whiptail \
            --title "DNS error" \
            --msgbox "Unable to resolve:

${MLAT_HOST}

Please verify that the DNS record exists and is set to DNS only, not proxied through Cloudflare." \
            14 72
        exit 1
    fi

    FEED_IP=$(getent ahostsv4 "$FEED_HOST" | awk 'NR==1 {print $1}')
    MLAT_IP=$(getent ahostsv4 "$MLAT_HOST" | awk 'NR==1 {print $1}')

    msg "DNS OK:"
    msg "${FEED_HOST} -> ${FEED_IP}"
    msg "${MLAT_HOST} -> ${MLAT_IP}"
}

check_remote_ports() {
    msg "Checking ADSBItalia remote ports..."

    if timeout 5 bash -c "</dev/tcp/${FEED_HOST}/${FEED_PORT}" 2>/dev/null; then
        msg "Feed port reachable: ${FEED_HOST}:${FEED_PORT}"
    else
        msg "Warning: feed port not reachable now: ${FEED_HOST}:${FEED_PORT}"
        msg "Installation will continue, but the feed service may reconnect until the server is reachable."
    fi

    if timeout 5 bash -c "</dev/tcp/${MLAT_HOST}/${MLAT_PORT}" 2>/dev/null; then
        msg "MLAT port reachable: ${MLAT_HOST}:${MLAT_PORT}"
    else
        msg "Warning: MLAT port not reachable now: ${MLAT_HOST}:${MLAT_PORT}"
        msg "Installation will continue, but the MLAT service may reconnect until the server is reachable."
    fi
}

save_config() {
    msg "Saving configuration..."

    sudo install -d -m 755 "$CONFIG_DIR"

    sudo tee "$CONFIG_FILE" >/dev/null <<EOF
FEEDER_NAME=$FEEDER_NAME
FEEDER_ID=$FEEDER_ID
FEEDER_TOKEN=$FEEDER_TOKEN
LAT=$LAT
LON=$LON
ALT=$ALT
LOCAL_BEAST_PORT=$LOCAL_BEAST_PORT
FEED_HOST=$FEED_HOST
MLAT_HOST=$MLAT_HOST
FEED_PORT=$FEED_PORT
MLAT_PORT=$MLAT_PORT
MLAT_RETURN_PORT=$MLAT_RETURN_PORT
SITE_URL=$SITE_URL
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

    sudo "$MLAT_VENV/bin/pip" install \
        --upgrade \
        --timeout 120 \
        --retries 10 \
        pip setuptools wheel

    sudo "$MLAT_VENV/bin/python" -c "import asyncore" >/dev/null 2>&1 || \
        sudo "$MLAT_VENV/bin/pip" install \
            --timeout 120 \
            --retries 10 \
            pyasyncore

    git clone "$MLAT_REPO" "$TMPDIR/mlat-client"

    sudo "$MLAT_VENV/bin/pip" install "$TMPDIR/mlat-client"

    sudo rm -rf "$TMPDIR"
}

detect_public_ip() {
    PUBLIC_IP=""

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
        msg "Unable to detect public IP. Registration skipped."
        return 0
    fi

    HOSTNAME_LOCAL=$(hostname -f 2>/dev/null || hostname)

    PAYLOAD=$(printf '{"feeder_id":"%s","feeder_token":"%s","user":"%s","host":"%s","hostname":"%s","beast_port":%s,"local_beast_port":%s,"feed_host":"%s","feed_port":%s,"feed_mode":"push","mlat_host":"%s","mlat_port":%s,"mlat_return_port":%s,"lat":"%s","lon":"%s","alt":"%s"}' \
        "$FEEDER_ID" \
        "$FEEDER_TOKEN" \
        "$FEEDER_NAME" \
        "$PUBLIC_IP" \
        "$HOSTNAME_LOCAL" \
        "$LOCAL_BEAST_PORT" \
        "$LOCAL_BEAST_PORT" \
        "$FEED_HOST" \
        "$FEED_PORT" \
        "$MLAT_HOST" \
        "$MLAT_PORT" \
        "$MLAT_RETURN_PORT" \
        "$LAT" \
        "$LON" \
        "$ALT")

    if curl -fsS \
        -H "Content-Type: application/json" \
        -d "$PAYLOAD" \
        "$REGISTER_URL" >/dev/null; then

        msg "Feeder registration request sent successfully."
    else
        msg "Registration failed or was rejected by the server."
        msg "Installation will continue anyway."
    fi
}

write_feed_service() {
    msg "Creating ADSBItalia feed service..."

    sudo tee /etc/systemd/system/adsbitalia-feed.service >/dev/null <<EOF
[Unit]
Description=ADSBItalia Feed Service
Wants=network-online.target
After=network-online.target

[Service]
Type=simple

ExecStart=/usr/bin/socat -u TCP:127.0.0.1:${LOCAL_BEAST_PORT},connect-timeout=10 TCP:${FEED_HOST}:${FEED_PORT},connect-timeout=10

Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
}

write_mlat_service() {
    msg "Creating ADSBItalia MLAT service..."

    sudo tee /etc/systemd/system/adsbitalia-mlat.service >/dev/null <<EOF
[Unit]
Description=ADSBItalia MLAT Service
Wants=network-online.target
After=network-online.target

[Service]
Type=simple

ExecStart=${MLAT_BIN} \\
  --input-type dump1090 \\
  --input-connect 127.0.0.1:${LOCAL_BEAST_PORT} \\
  --server ${MLAT_HOST}:${MLAT_PORT} \\
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
        --msgbox "ADSBItalia feeder installation completed.

Feed service:
${FEED_STATE}

MLAT service:
${MLAT_STATE}

Local Beast OUT port:
${LOCAL_BEAST_PORT}

Feed destination:
${FEED_HOST}:${FEED_PORT}

MLAT destination:
${MLAT_HOST}:${MLAT_PORT}

MLAT return port:
${MLAT_RETURN_PORT}

Website:
${SITE_URL}

Useful commands:

sudo systemctl status adsbitalia-feed
sudo systemctl status adsbitalia-mlat

sudo journalctl -u adsbitalia-feed -n 50 --no-pager
sudo journalctl -u adsbitalia-mlat -n 50 --no-pager" \
        27 78
}

main() {
    detect_distro
    install_packages
    load_existing_config
    show_welcome
    collect_user_data
    generate_feeder_identity
    check_local_feed
    check_adsbitalia_dns
    check_remote_ports
    save_config
    install_mlat_client
    register_feeder
    write_feed_service
    write_mlat_service
    enable_services
    show_status
}

main "$@"
