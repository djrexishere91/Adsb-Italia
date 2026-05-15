ADSB-Italia Network
Collaborative ADS-B feeder network with a central server in Fiscaglia (FE), Italy. The project lets contributors forward local ADS-B data and MLAT results to the ADSB-Italia aggregation server using a dedicated mlat-client virtual environment and two systemd services.

Live map
Open the live map

What this project does
The installer configures a feeder to send Beast data to the ADSB-Italia server and runs a separate MLAT client that connects to the central MLAT server.
 The setup is designed to avoid interfering with an existing local ADS-B stack by keeping the MLAT client inside its own virtual environment and service.

Main components
install.sh — first installation of the feeder node.

update.sh — change feeder name, latitude, longitude, and altitude without reinstalling everything.

uninstall.sh — remove the ADSB-Italia local services and dedicated MLAT virtual environment.

Quick install
Run this command on the feeder host:

bash
curl -fsSL https://raw.githubusercontent.com/djrexishere91/Adsb-Italia/main/install.sh | sudo bash
The installer checks for a local Beast feed on 127.0.0.1:30005, installs required packages, installs mlat-client in /opt/adsbitalia-mlat, attempts remote feeder registration, and creates the adsb-italia.service and mlat-italia.service systemd units.

Requirements
Before running the installer, make sure the feeder host has:

Debian/Ubuntu or Arch Linux.

A working local ADS-B decoder exposing Beast data on 127.0.0.1:30005.

Internet access for package installation, GitHub download, and feeder registration.

sudo privileges.

Management commands
Service status
bash
sudo systemctl status adsb-italia.service
sudo systemctl status mlat-italia.service
Follow logs
bash
sudo journalctl -u adsb-italia.service -f
sudo journalctl -u mlat-italia.service -f
Update feeder details
Use this when the feeder name, coordinates, or altitude change:

bash
curl -fsSL https://raw.githubusercontent.com/djrexishere91/Adsb-Italia/main/update.sh | sudo bash
update.sh reads the current values from /etc/adsbitalia/feeder.conf, proposes them as defaults, updates the local config, refreshes remote registration, rewrites the local systemd units, and restarts the services.

Uninstall
Use this to remove the ADSB-Italia feeder integration from the local machine:

bash
curl -fsSL https://raw.githubusercontent.com/djrexishere91/Adsb-Italia/main/uninstall.sh | sudo bash
The uninstall script stops and disables the ADSB-Italia systemd services, removes their unit files, reloads systemd, and deletes the dedicated MLAT virtual environment.

Files created locally
Path	Purpose
/opt/adsbitalia-mlat	Dedicated Python virtual environment for mlat-client.
/etc/adsbitalia/feeder.conf	Saved feeder name, latitude, longitude, and altitude.
/etc/systemd/system/mlat-italia.service	MLAT client service.
/etc/systemd/system/adsb-italia.service	ADS-B forwarding service.
English
Overview
ADSB-Italia Network is a collaborative ADS-B and MLAT aggregation project with a central server in Fiscaglia (FE), Italy. Contributors can connect their receiver to the network and feed both Beast data and MLAT data to the central server.

Installation
Run:

bash
curl -fsSL https://raw.githubusercontent.com/djrexishere91/Adsb-Italia/main/install.sh | sudo bash
During installation, the script asks for feeder name, latitude, longitude, and altitude, verifies that a local Beast feed is available on 127.0.0.1:30005, installs dependencies, installs a dedicated mlat-client, attempts feeder registration through the ADSB-Italia API, and enables the local services.

Update
Run:

bash
curl -fsSL https://raw.githubusercontent.com/djrexishere91/Adsb-Italia/main/update.sh | sudo bash
This updates feeder metadata without a full reinstall. It keeps the existing installation, reloads the saved values from /etc/adsbitalia/feeder.conf, lets the user change them, updates remote registration, rewrites the systemd units, and restarts the services.

Uninstall
Run:

bash
curl -fsSL https://raw.githubusercontent.com/djrexishere91/Adsb-Italia/main/uninstall.sh | sudo bash
This removes only the ADSB-Italia integration from the local machine. It does not remove the user's local ADS-B decoder such as readsb or dump1090.

Troubleshooting
Useful commands:

bash
sudo systemctl status adsb-italia.service
sudo systemctl status mlat-italia.service
sudo journalctl -u adsb-italia.service -n 100 --no-pager
sudo journalctl -u mlat-italia.service -n 100 --no-pager
If MLAT is connected correctly, the central MLAT server should report an active client and synchronization activity in its logs.
​

Italiano
Panoramica
ADSB-Italia Network è una rete collaborativa ADS-B e MLAT con server centrale a Fiscaglia (FE). I partecipanti possono collegare il proprio ricevitore alla rete e inviare sia i dati Beast sia i dati MLAT al server centrale.

Installazione
Eseguire:

bash
curl -fsSL https://raw.githubusercontent.com/djrexishere91/Adsb-Italia/main/install.sh | sudo bash
Durante l'installazione, lo script chiede nome feeder, latitudine, longitudine e altitudine, verifica la presenza di un feed Beast locale su 127.0.0.1:30005, installa le dipendenze, installa un mlat-client dedicato, tenta la registrazione del feeder tramite API ADSB-Italia e abilita i servizi locali.

Aggiornamento
Eseguire:

bash
curl -fsSL https://raw.githubusercontent.com/djrexishere91/Adsb-Italia/main/update.sh | sudo bash
Questo script aggiorna i metadati del feeder senza reinstallare tutto da capo. Mantiene l'installazione esistente, rilegge i valori salvati in /etc/adsbitalia/feeder.conf, permette di modificarli, aggiorna la registrazione remota, riscrive i file systemd e riavvia i servizi.

Disinstallazione
Eseguire:

bash
curl -fsSL https://raw.githubusercontent.com/djrexishere91/Adsb-Italia/main/uninstall.sh | sudo bash
Questo rimuove soltanto l'integrazione ADSB-Italia dalla macchina locale. Non rimuove il decoder ADS-B locale dell'utente, come readsb o dump1090.

Risoluzione problemi
Comandi utili:

bash
sudo systemctl status adsb-italia.service
sudo systemctl status mlat-italia.service
sudo journalctl -u adsb-italia.service -n 100 --no-pager
sudo journalctl -u mlat-italia.service -n 100 --no-pager
Se la connessione MLAT è corretta, il server MLAT centrale dovrebbe mostrare un client attivo e attività di sincronizzazione nei propri log.
​
