📡 ADSB-Italia Network
Rete collaborativa ADS-B con server a Fiscaglia (FE).

🗺️ Mappa Live
https://adsb.djrexishere.it/combine1090/

🚀 Installazione rapida
Copia e incolla questo comando nel terminale:

curl -L https://raw.githubusercontent.com/djrexishere91/Adsb-Italia/main/install.sh | sudo bash

🛠️ Comandi di controllo
Stato ADS-B:
sudo systemctl status adsb-italia

Stato MLAT:
sudo systemctl status mlat-italia

🔍 Cosa fa lo script?
Installa socat e python3.

Compila mlat-client.

Collega i tuoi dati al server centrale.
