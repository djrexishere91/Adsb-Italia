#!/bin/bash

# --- CONFIGURAZIONE SERVER ADSB-ITALIA ---
SERVER_IP="195.32.10.68"
MLAT_PORT="31090"
FEED_PORT="30004"
# -----------------------------------------

# 1. RILEVAMENTO DISTRIBUZIONE E INSTALLAZIONE WHIPTAIL
if [ -f /etc/arch-release ]; then
    DISTRO="arch"
    echo "Rilevato Arch Linux. Preparazione grafica..."
    sudo pacman -Syu --noconfirm --needed whiptail curl
elif [ -f /etc/debian_version ]; then
    DISTRO="debian"
    echo "Rilevato Debian/Ubuntu. Preparazione grafica..."
    sudo apt update && sudo apt install -y whiptail curl
else
    echo "Distribuzione non supportata automaticamente."
    exit 1
fi

# 2. SCHERMATA DI BENVENUTO
whiptail --title "ADSB-Italia Network" --msgbox "Benvenuto nello script di installazione della rete ADSB-Italia.\n\nIl server centrale si trova a Fiscaglia (FE)." 10 60

# 3. RACCOLTA DATI UTENTE
UTENTE=$(whiptail --inputbox "Inserisci il tuo nome utente (es. Pilota_Fiscaglia):" 10 60 --title "User Configuration" 3>&1 1>&2 2>&3)
LAT=$(whiptail --inputbox "Inserisci la tua Latitudine (es. 44.83):" 10 60 --title "Coordinate Configuration" 3>&1 1>&2 2>&3)
LON=$(whiptail --inputbox "Inserisci la tua Longitudine (es. 11.62):" 10 60 --title "Coordinate Configuration" 3>&1 1>&2 2>&3)
ALT=$(whiptail --inputbox "Inserisci l'Altitudine in metri (es. 15):" 10 60 --title "Altitude Configuration" 3>&1 1>&2 2>&3)

# 4. INSTALLAZIONE DIPENDENZE SPECIFICHE
echo "Installazione componenti di sistema in corso..."
if [ "$DISTRO" == "arch" ]; then
    sudo pacman -S --noconfirm --needed socat git python gcc python-setuptools
else
    sudo apt install -y socat git python3-dev python3-setuptools gcc
fi

# 5. COMPILAZIONE MLAT-CLIENT (Se non presente)
if [ ! -f "/usr/local/bin/mlat-client" ]; then
    echo "Compilazione mlat-client in corso..."
    cd /tmp
    sudo rm -rf mlat-client
    git clone https://github.com/wiedehopf/mlat-client.git
    cd mlat-client
    if [ "$DISTRO" == "arch" ]; then
        sudo python setup.py install
    else
        sudo python3 setup.py install
    fi
fi

# 6. CREAZIONE SERVIZIO MLAT
cat <<EOF | sudo tee /etc/systemd/system/mlat-italia.service > /dev/null
[Unit]
Description=MLAT Italia Client
After=network.target

[Service]
ExecStart=/usr/local/bin/mlat-client --input-type dump1090 --input-connect localhost:30005 --server $SERVER_IP:$MLAT_PORT --user $UTENTE --lat $LAT --lon $LON --alt $ALT --results beast,listen,30105
Restart=always
RestartSec=30

[Install]
WantedBy=multi-user.target
EOF

# 7. CREAZIONE SERVIZIO ADS-B (SOCAT)
cat <<EOF | sudo tee /etc/systemd/system/adsb-italia.service > /dev/null
[Unit]
Description=ADS-B Feed Italia
After=network.target

[Service]
ExecStart=/usr/bin/socat -u TCP:localhost:30005 TCP:$SERVER_IP:$FEED_PORT
Restart=always
RestartSec=60

[Install]
WantedBy=multi-user.target
EOF

# 8. ATTIVAZIONE SERVIZI
echo "Attivazione servizi..."
sudo systemctl daemon-reload
sudo systemctl enable mlat-italia adsb-italia
sudo systemctl restart mlat-italia adsb-italia || true

# 9. MESSAGGIO FINALE
whiptail --title "INSTALLAZIONE COMPLETATA" --msgbox "Grazie $UTENTE!\n\nLa tua stazione è ora configurata.\n\nControlla il sito: adsb.djrexishere.it" 12 60
