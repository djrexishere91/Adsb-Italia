#!/usr/bin/env bash
set -euo pipefail

SERVER_IP="185.119.19.188"
MLAT_PORT="41113"
FEED_PORT="30004"
SITE_URL="https://adsbitalia.djrexishere.it"
MLAT_REPO="https://github.com/wiedehopf/mlat-client.git"
MLAT_BIN="/usr/local/bin/mlat-client"
REGISTER_URL="https://adsbitalia.djrexishere.it/api/register-feeder"
REGISTER_TOKEN="6oAEgkdPAYCn1QpgcU8pCNjb_pM3jBr6Zb9j2hKHnPZ4Obnn-RYrwz1o1kl43pEu"
PUBLIC_IP_SERVICES=("https://api.ipify.org" "https://ifconfig.me" "https://icanhazip.com")

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
        echo "Distribuzione non supportata automaticamente. Supportati: Debian/Ubuntu, Arch Linux."
        exit 1
    fi
}

install_packages() {
    msg "Installazione dipendenze..."
    if [[ "$DISTRO" == "arch" ]]; then
        sudo pacman -Syu --noconfirm --needed whiptail curl git socat python python-pip base-devel
    else
        sudo apt update
        sudo apt install -y whiptail curl git socat python3 python3-pip python3-setuptools python3-venv gcc
    fi
}

show_welcome() {
    whiptail --title "ADSB-Italia Network" \
        --msgbox "Benvenuto nello script di installazione ADSB-Italia.\n\nQuesto script configura:\n- il feed ADS-B verso la VPS centrale\n- il client MLAT verso il server MLAT centrale\n- la registrazione automatica del feeder sulla VPS\n\nVPS: ${SERVER_IP}" 16 72
}

collect_user_data() {
    UTENTE=$(whiptail --inputbox "Inserisci il tuo nome utente/feed name:" 10 60 --title "User Configuration" 3>&1 1>&2 2>&3) || exit 1
    LAT=$(whiptail --inputbox "Inserisci la tua latitudine decimale (es. 44.8300):" 10 60 --title "Coordinate Configuration" 3>&1 1>&2 2>&3) || exit 1
    LON=$(whiptail --inputbox "Inserisci la tua longitudine decimale (es. 11.6200):" 10 60 --title "Coordinate Configuration" 3>&1 1>&2 2>&3) || exit 1
    ALT=$(whiptail --inputbox "Inserisci l'altitudine in metri (es. 15):" 10 60 --title "Altitude Configuration" 3>&1 1>&2 2>&3) || exit 1

    [[ -n "$UTENTE" ]] || { echo "Nome utente vuoto."; exit 1; }
    [[ -n "$LAT" ]] || { echo "Latitudine vuota."; exit 1; }
    [[ -n "$LON" ]] || { echo "Longitudine vuota."; exit 1; }
    [[ -n "$ALT" ]] || { echo "Altitudine vuota."; exit 1; }
}

check_local_feed() {
    msg "Verifica feed locale su localhost:30005..."
    if ! timeout 3 bash -c '</dev/tcp/127.0.0.1/30005' 2>/dev/null; then
        whiptail --title "Feed locale non trovato" \
            --msgbox "Non trovo nessun feed Beast locale su localhost:30005.\n\nInstalla o avvia prima readsb/dump1090 e poi rilancia lo script." 12 70
        exit 1
    fi
}

install_mlat_client() {
    if [[ -x "$MLAT_BIN" ]]; then
        msg "mlat-client già presente in $MLAT_BIN"
        return
    fi

    msg "Installazione mlat-client..."
    TMPDIR=$(mktemp -d)
    trap 'rm -rf "$TMPDIR"' EXIT
    git clone "$MLAT_REPO" "$TMPDIR/mlat-client"
    cd "$TMPDIR/mlat-client"

    if [[ "$DISTRO" == "arch" ]]; then
        sudo python -m pip install .
    else
        sudo python3 -m pip install .
    fi

    if ! [[ -x "$MLAT_BIN" ]]; then
        ALT_BIN=$(command -v mlat-client || true)
        if [[ -n "$ALT_BIN" ]]; then
            MLAT_BIN="$ALT_BIN"
        else
            echo "Installazione mlat-client completata ma binario non trovato."
            exit 1
        fi
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
    msg "Registrazione automatica feeder sulla VPS..."

    if ! detect_public_ip; then
        whiptail --title "Registrazione feeder fallita" \
            --msgbox "Impossibile determinare l'IP pubblico di questo feeder.\n\nPuoi comunque completare l'installazione, ma dovrai aggiungere il feeder a mano sulla VPS." 12 72
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
        msg "Feeder registrato automaticamente sulla VPS: ${PUBLIC_IP}"
    else
        msg "Registrazione automatica non riuscita (HTTP ${HTTP_CODE:-errore})."
        msg "Continuo comunque con l'installazione locale."
    fi
}

write_services() {
    msg "Creazione servizi systemd..."

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
    msg "Abilitazione servizi..."
    sudo systemctl daemon-reload
    sudo systemctl enable --now mlat-italia.service
    sudo systemctl enable --now adsb-italia.service
}

show_status() {
    MLAT_STATE=$(systemctl is-active mlat-italia.service || true)
    FEED_STATE=$(systemctl is-active adsb-italia.service || true)

    whiptail --title "INSTALLAZIONE COMPLETATA" \
        --msgbox "Grazie ${UTENTE}!\n\nStato servizi:\n- MLAT: ${MLAT_STATE}\n- Feed ADS-B: ${FEED_STATE}\n\nDestinazioni:\n- MLAT server: ${SERVER_IP}:${MLAT_PORT}\n- Combine feed: ${SERVER_IP}:${FEED_PORT}\n\nRegistrazione automatica tentata verso:\n- ${REGISTER_URL}\n\nSito: ${SITE_URL}" 18 74
}

main() {
    detect_distro
    install_packages
    show_welcome
    collect_user_data
    check_local_feed
    install_mlat_client
    register_feeder
    write_services
    enable_services
    show_status
}

main "$@"
