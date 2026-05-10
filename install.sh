#!/bin/bash

# --- CONFIGURAZIONE SERVER ADSB-ITALIA ---
SERVER_IP="195.32.10.68"
MLAT_PORT="31090"
FEED_PORT="30004"
# -----------------------------------------

# Controllo se whiptail è installato
sudo apt update && sudo apt install -y whiptail

# Schermata di Benvenuto
whiptail --title "ADSB-Italia Network" --msgbox "Benvenuto nello script di installazione della rete ADSB-Italia.\n\nIl server centrale si trova a Fiscaglia (FE)." 10 60

# 1. Input Utente con finestre blu
UTENTE=$(whiptail --inputbox "Inserisci il tuo nome utente (es. Pilota_Fiscaglia):" 10 60 --title "User Configuration" 3>&1 1>&2 2>&3)
LAT=$(whiptail --inputbox "Inserisci la tua Latitudine (es. 44.83):" 10 60 --title "Coordinate Configuration" 3>&1 1>&2 2>&3)
LON=$(whiptail --inputbox "Inserisci la tua Longitudine (es. 11.62):" 10 60 --title "Coordinate Configuration" 3>&1 1>&2 2>&3)
ALT=$(whiptail --inputbox "Inserisci l'Altitudine in metri (es. 15):" 10 60 --title "Altitude Configuration" 3>&1 1>&2 2>&3)

# 2. Installazione dipendenze (testo normale a scorrimento)
echo "Installazione componenti di sistema in corso..."
sudo apt install -y socat git python3-dev gcc

# 3. Installazione mlat-client
if [ ! -f "/usr/local/bin/mlat-client" ]; then
    echo "Compilazione mlat-client in corso..."
    cd /tmp
    sudo rm -rf mlat-client
    git clone https://github.com/wiedehopf/mlat-client.git
    cd mlat-client
    sudo python3 setup.py install
fi

# 4. Creazione Servizio MLAT
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

# 5. Creazione Servizio ADS-B
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

# 6. Attivazione
sudo systemctl daemon-reload
sudo systemctl enable mlat-italia adsb-italia
sudo systemctl restart mlat-italia adsb-italia

# Messaggio finale di successo
whiptail --title "INSTALLAZIONE COMPLETATA" --msgbox "Grazie $UTENTE!\n\nLa tua stazione è ora collegata alla rete ADSB-Italia.\nControlla la tua posizione sulla mappa: https://adsb.djrexishere.it/combine1090" 12 60
