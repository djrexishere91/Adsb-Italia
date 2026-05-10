#!/bin/bash

# --- CONFIGURAZIONE SERVER ADSB-ITALIA ---
SERVER_IP="195.32.10.68"
MLAT_PORT="31090"
FEED_PORT="30004"
# -----------------------------------------

# Funzione per installare pacchetti in base alla distro
install_dependencies() {
    if [ -f /etc/arch-release ]; then
        echo "Rilevato Arch Linux. Installazione con pacman..."
        sudo pacman -Syu --noconfirm --needed whiptail socat git python gcc python-setuptools
    elif [ -f /etc/debian_version ]; then
        echo "Rilevato Debian/Ubuntu. Installazione con apt..."
        sudo apt update
        sudo apt install -y whiptail socat git python3-dev python3-setuptools gcc
    else
        echo "Distribuzione non supportata ufficialmente. Prova a installare whiptail a mano."
        exit 1
    fi
}

# 1. Installazione preliminare per la grafica
if [ -f /etc/arch-release ]; then
    sudo pacman -Syu --noconfirm --needed whiptail
else
    sudo apt update && sudo apt install -y whiptail
fi

# Schermata di Benvenuto
whiptail --title "ADSB-Italia Network" --msgbox "Benvenuto nello script di installazione della rete ADSB-Italia.\n\nIl server centrale si trova a Fiscaglia (FE)." 10 60

# 2. Input Utente
UTENTE=$(whiptail --inputbox "Inserisci il tuo nome utente:" 10 60 --title "User Configuration" 3>&1 1>&2 2>&3)
LAT=$(whiptail --inputbox "Inserisci la tua Latitudine:" 10 60 --title "Coordinate Configuration" 3>&1 1>&2 2>&3)
LON=$(whiptail --inputbox "Inserisci la tua Longitudine:" 10 60 --title "Coordinate Configuration" 3>&1 1>&2 2>&3)
ALT=$(whiptail --inputbox "Inserisci l'Altitudine (metri):" 10 60 --title "Altitude Configuration" 3>&1 1>&2 2>&3)

# 3. Installazione dipendenze specifiche
install_dependencies

# 4. Installazione mlat-client
if [ ! -f "/usr/local/bin/mlat-client" ]; then
    echo "Compilazione mlat-client..."
    cd /tmp
    sudo rm -rf mlat-client
    git clone https://github.com/wiedehopf/mlat-client.git
    cd mlat-client
    # Su Arch python3 è il comando standard
    sudo python setup.py install
fi

# 5. Creazione Servizi (Il contenuto rimane uguale, systemd è standard)
# ... [Qui rimangono i punti 4 e 5 del vecchio script per creare i file .service] ...

# 6. Attivazione
sudo systemctl daemon-reload
sudo systemctl enable mlat-italia adsb-italia
sudo systemctl restart mlat-italia adsb-italia || true

whiptail --title "INSTALLAZIONE COMPLETATA" --msgbox "Grazie $UTENTE!\n\nStazione collegata. Mappa: adsb.djrexishere.it" 12 60
