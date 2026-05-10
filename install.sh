#!/bin/bash

# --- CONFIGURAZIONE SERVER ADSB-ITALIA ---
SERVER_IP="195.32.10.68"
MLAT_PORT="31090"
FEED_PORT="30004"
# -----------------------------------------

GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}>>> Installazione Feed ADSB-Italia Network <<<${NC}"

# 1. Input Utente
echo "Configurazione stazione..."
read -p "Inserisci il tuo nome utente: " UTENTE
read -p "Latitudine: " LAT
read -p "Longitudine: " LON
read -p "Altitudine (metri): " ALT

# 2. Installazione dipendenze
echo "Installazione componenti di sistema..."
sudo apt update && sudo apt install -y socat git python3-dev gcc

# 3. Installazione mlat-client (se non presente)
if [ ! -f "/usr/local/bin/mlat-client" ]; then
    echo "Compilazione mlat-client in corso (potrebbe richiedere qualche minuto)..."
    cd /tmp
    git clone https://github.com/wiedehopf/mlat-client.git
    cd mlat-client
    sudo python3 setup.py install
fi

# 4. Creazione Servizio MLAT
cat <<EOF | sudo tee /etc/systemd/system/mlat-italia.service
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
cat <<EOF | sudo tee /etc/systemd/system/adsb-italia.service
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

echo -e "${GREEN}>>> SETUP COMPLETATO! <<<${NC}"
