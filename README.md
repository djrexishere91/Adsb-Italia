# ADSB-Italia Network

Collaborative ADS-B feeder network with a central server in Fiscaglia (FE), Italy.

ADSB-Italia Network allows contributors to forward local ADS-B data and MLAT results to the ADSB-Italia aggregation server using dedicated systemd services and a separate `mlat-client` environment.

## Live Map

[Open the live map](https://adsbitalia.djrexishere.it/combine1090/)

---

# Italiano

## Panoramica

ADSB-Italia Network è una rete collaborativa ADS-B con server centrale a Fiscaglia (FE), Italia.

Permette ai partecipanti di condividere i propri dati ADS-B locali e i risultati MLAT verso il server centrale ADSB-Italia, senza stravolgere la propria installazione esistente.

## Funzioni principali

- Inoltro dei dati Beast al server ADSB-Italia
- Connessione MLAT separata tramite `mlat-client`
- Servizi systemd dedicati
- Configurazione semplice tramite script
- Possibilità di aggiornare i dati del feeder senza reinstallare tutto

## Script disponibili

- `install.sh` — installazione iniziale del feeder
- `update.sh` — aggiornamento di nome feeder, coordinate e altitudine
- `uninstall.sh` — rimozione dei servizi ADSB-Italia e dell'ambiente MLAT dedicato

## Installazione rapida

Esegui questo comando sul feeder:

```bash
curl -fsSL https://raw.githubusercontent.com/djrexishere91/Adsb-Italia/main/install.sh | sudo bash
```

## Requisiti

Prima di eseguire l'installazione, assicurati di avere:

- Debian/Ubuntu oppure Arch Linux
- Un decoder ADS-B locale attivo
- Output Beast disponibile su `127.0.0.1:30005`
- Connessione Internet attiva
- Privilegi `sudo`

## Cosa fa lo script di installazione

Lo script:

- verifica la presenza di un feed Beast locale su `127.0.0.1:30005`
- installa i pacchetti necessari
- installa `mlat-client` in un ambiente dedicato
- registra il feeder sul server ADSB-Italia
- crea e abilita i servizi systemd locali

## Comandi di gestione

### Stato dei servizi

```bash
sudo systemctl status adsb-italia.service
sudo systemctl status mlat-italia.service
```

### Visualizzare i log in tempo reale

```bash
sudo journalctl -u adsb-italia.service -f
sudo journalctl -u mlat-italia.service -f
```

## Aggiornare i dati del feeder

Se vuoi cambiare nome feeder, coordinate o altitudine, esegui:

```bash
curl -fsSL https://raw.githubusercontent.com/djrexishere91/Adsb-Italia/main/update.sh | sudo bash
```

Questo script aggiorna i dati salvati localmente e rigenera la configurazione necessaria senza reinstallare tutto.

## Disinstallazione

Per rimuovere ADSB-Italia dal feeder:

```bash
curl -fsSL [https://raw.githubusercontent.com/djrexishere91/Adsb-Italia/main/uninstall.sh](https://raw.githubusercontent.com/djrexishere91/Adsb-Italia/refs/heads/main/unistall.sh) | sudo bash
```

La disinstallazione rimuove solo l'integrazione ADSB-Italia e non il decoder ADS-B locale già presente nel sistema.

## File creati localmente

| Percorso | Descrizione |
|---|---|
| `/opt/adsbitalia-mlat` | Ambiente Python dedicato a `mlat-client` |
| `/etc/adsbitalia/feeder.conf` | Configurazione del feeder |
| `/etc/systemd/system/mlat-italia.service` | Servizio systemd MLAT |
| `/etc/systemd/system/adsb-italia.service` | Servizio systemd ADS-B |

## Risoluzione problemi

Comandi utili per la diagnostica:

```bash
sudo systemctl status adsb-italia.service
sudo systemctl status mlat-italia.service
sudo journalctl -u adsb-italia.service -n 100 --no-pager
sudo journalctl -u mlat-italia.service -n 100 --no-pager
```

Verifica anche che il tuo feeder locale stia effettivamente esponendo il feed Beast su `127.0.0.1:30005`.

---

# English

## Overview

ADSB-Italia Network is a collaborative ADS-B feeder network with a central server located in Fiscaglia (FE), Italy.

It allows contributors to forward local ADS-B data and MLAT results to the ADSB-Italia aggregation server without disrupting an existing local ADS-B setup.

## Main features

- Beast data forwarding to the ADSB-Italia server
- Separate MLAT connection through `mlat-client`
- Dedicated systemd services
- Simple scripted installation
- Feeder details can be updated without a full reinstall

## Available scripts

- `install.sh` — initial feeder installation
- `update.sh` — update feeder name, coordinates, and altitude
- `uninstall.sh` — remove ADSB-Italia services and the dedicated MLAT environment

## Quick install

Run this command on the feeder host:

```bash
curl -fsSL https://raw.githubusercontent.com/djrexishere91/Adsb-Italia/main/install.sh | sudo bash
```

## Requirements

Before installing, make sure you have:

- Debian/Ubuntu or Arch Linux
- A working local ADS-B decoder
- Beast output available on `127.0.0.1:30005`
- Internet connectivity
- `sudo` privileges

## What the installer does

The installation script:

- checks for a local Beast feed on `127.0.0.1:30005`
- installs the required packages
- installs `mlat-client` in a dedicated environment
- registers the feeder with the ADSB-Italia server
- creates and enables the required local systemd services

## Management commands

### Service status

```bash
sudo systemctl status adsb-italia.service
sudo systemctl status mlat-italia.service
```

### Follow logs

```bash
sudo journalctl -u adsb-italia.service -f
sudo journalctl -u mlat-italia.service -f
```

## Update feeder details

If you need to change feeder name, coordinates, or altitude, run:

```bash
curl -fsSL https://raw.githubusercontent.com/djrexishere91/Adsb-Italia/main/update.sh | sudo bash
```

This updates the locally saved feeder information and refreshes the related configuration without requiring a full reinstall.

## Uninstall

To remove ADSB-Italia from the feeder host:

```bash
curl -fsSL https://raw.githubusercontent.com/djrexishere91/Adsb-Italia/main/uninstall.sh | sudo bash
```

The uninstall process removes only the ADSB-Italia integration and does not remove the local ADS-B decoder already installed on the system.

## Local files

| Path | Description |
|---|---|
| `/opt/adsbitalia-mlat` | Dedicated Python environment for `mlat-client` |
| `/etc/adsbitalia/feeder.conf` | Feeder configuration |
| `/etc/systemd/system/mlat-italia.service` | MLAT systemd service |
| `/etc/systemd/system/adsb-italia.service` | ADS-B forwarding systemd service |

## Troubleshooting

Useful diagnostic commands:

```bash
sudo systemctl status adsb-italia.service
sudo systemctl status mlat-italia.service
sudo journalctl -u adsb-italia.service -n 100 --no-pager
sudo journalctl -u mlat-italia.service -n 100 --no-pager
```

Also make sure your local feeder is actually exposing Beast data on `127.0.0.1:30005`.
