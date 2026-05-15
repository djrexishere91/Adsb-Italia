#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="/etc/adsbitalia/feeder.conf"
MLAT_SERVICE="mlat-italia.service"
ADSB_SERVICE="adsb-italia.service"
MLAT_UNIT="/etc/systemd/system/${MLAT_SERVICE}"
ADSB_UNIT="/etc/systemd/system/${ADSB_SERVICE}"

SERVER_IP="185.119.19.188"
MLAT_PORT="41113"
FEED_PORT="30004"
SITE_URL="https://adsbitalia.djrexishere.it"
REGISTER_URL="https://adsbitalia.djrexishere.it/api/register-feeder"
REGISTER_TOKEN="6oAEgkdPAYCn1QpgcU8pCNjb_pM3jBr6Zb9j2hKHnPZ4Obnn-RYrwz1o1kl43pEu"
PUBLIC_IP_SERVICES=("https://api.ipify.org" "https://ifconfig.me" "https://icanhazip.com")

msg() {
    echo "[ADSB-Italia] $*"
}

require_root() {
    if [[ "${EUID}" -ne 0 ]]; then
        echo "Please run this script as root."
        exit 1
    fi
}

require_cmd() {
    command -v "$1" >/dev/null 2>&1 || {
        echo "Missing required command: $1"
        exit 1
    }
}

check_local_feed() {
    msg "Checking local Beast feed on localhost:30005..."
    if ! timeout 3 bash -c '</dev/tcp/127.0.0.1/30005' 2>/dev/null; then
        whiptail --title "Local feed not found" \
            --msgbox "No local Beast feed was found on localhost:30005.\n\nPlease start readsb or dump1090 first, then run this script again." 12 70
        exit 1
    fi
}

load_existing_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        # shellcheck disable=SC1090
        source "$CONFIG_FILE"
    fi

    UTENTE="${UTENTE:-}"
    LAT="${LAT:-}"
    LON="${LON:-}"
    ALT="${ALT:-}"
}

prompt_with_default() {
    local title="$1"
    local prompt="$2"
    local default_value="$3"
    whiptail --inputbox "$prompt" 10 70 "$default_value" --title "$title" 3>&1 1>&2 2>&3
}

collect_user_data() {
    UTENTE=$(prompt_with_default "Feeder Configuration" "Enter your feeder name:" "$UTENTE") || exit 1
    LAT=$(prompt_with_default "Coordinates" "Enter your decimal latitude (example: 44.8300):" "$LAT") || exit 1
    LON=$(prompt_with_default "Coordinates" "Enter your decimal longitude (example: 11.6200):" "$LON") || exit 1
    ALT=$(prompt_with_default "Altitude" "Enter altitude in meters (example: 15):" "$ALT") || exit 1

    [[ -n "$UTENTE" ]] || { echo "Feeder name cannot be empty."; exit 1; }
    [[ -n "$LAT" ]] || { echo "Latitude cannot be empty."; exit 1; }
    [[ -n "$LON" ]] || { echo "Longitude cannot be empty."; exit 1; }
    [[ -n "$ALT" ]] || { echo "Altitude cannot be empty."; exit 1; }
}

save_config() {
    msg "Saving local feeder configuration..."
    install -d -m 755 /etc/adsbitalia
    cat > "$CONFIG_FILE" <<EOF
UTENTE=$(printf '%q' "$UTENTE")
LAT=$(printf '%q' "$LAT")
LON=$(printf '%q' "$LON")
ALT=$(printf '%q' "$ALT")
EOF
    chmod 600 "$CONFIG_FILE"
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
    msg "Updating feeder registration..."

    if ! detect_public_ip; then
        whiptail --title "Registration update failed" \
            --msgbox "Unable to detect this feeder's public IP address.\n\nLocal settings were updated, but the remote registration could not be refreshed automatically." 12 72
        return 0
    fi

    HOSTNAME_LOCAL=$(hostname -f 2>/dev/null || hostname)

    PAYLOAD=$(printf '{"user":"%s","host":"%s","hostname":"%s","beast_port":30005,"mlat_port":30105,"lat":"%s","lon":"%s","alt":"%s"}' \
        "$UTENTE" "$PUBLIC_IP" "$HOSTNAME_LOCAL" "$LAT" "$LON" "$ALT")

    HTTP_CODE=$(curl -kfsS -o /tmp/adsbitalia-register.out -w '%{http_code}' \
        -H 'Content-Type: application/json' \
        -H "X-Register-Token: ${REGISTER_TOKEN}" \
        -d "$PAYLOAD" \
        "$REGISTER_URL" || true)

    if [[ "$HTTP_CODE" == "200" || "$HTTP_CODE" == "201" ]]; then
        msg "Remote registration updated successfully."
    else
        msg "Remote registration update failed (HTTP ${HTTP_CODE:-error})."
        msg "Continuing with local service update."
    fi
}

write_services() {
    msg "Updating systemd services..."

    cat <<EOF2 > "$MLAT_UNIT"
[Unit]
Description=ADSB-Italia MLAT Client
Wants=network-online.target
After=network-online.target
StartLimitIntervalSec=300
StartLimitBurst=10

[Service]
Type=simple
ExecStart=/opt/adsbitalia-mlat/bin/mlat-client --input-type dump1090 --input-connect localhost:30005 --server ${SERVER_IP}:${MLAT_PORT} --user ${UTENTE} --lat ${LAT} --lon ${LON} --alt ${ALT} --results beast,listen,30105
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF2

    cat <<EOF2 > "$ADSB_UNIT"
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

reload_services() {
    msg "Reloading systemd and restarting feeder services..."
    systemctl daemon-reload
    systemctl enable --now "$MLAT_SERVICE"
    systemctl enable --now "$ADSB_SERVICE"
    systemctl restart "$MLAT_SERVICE"
    systemctl restart "$ADSB_SERVICE"
}

show_status() {
    MLAT_STATE=$(systemctl is-active "$MLAT_SERVICE" || true)
    FEED_STATE=$(systemctl is-active "$ADSB_SERVICE" || true)

    whiptail --title "UPDATE COMPLETED" \
        --msgbox "Your feeder settings have been updated.\n\nService status:\n- MLAT: ${MLAT_STATE}\n- ADS-B feed: ${FEED_STATE}\n\nUpdated values:\n- Feeder name: ${UTENTE}\n- Latitude: ${LAT}\n- Longitude: ${LON}\n- Altitude: ${ALT}\n\nWebsite:\n- ${SITE_URL}" 18 74
}

main() {
    require_root
    require_cmd whiptail
    require_cmd curl
    require_cmd systemctl

    load_existing_config
    check_local_feed
    collect_user_data
    save_config
    register_feeder
    write_services
    reload_services
    show_status
}

main "$@"
