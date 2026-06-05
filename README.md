# ADSBItalia Network

Collaborative ADS-B and MLAT feeder network with a central aggregation server in Italy.

ADSBItalia allows contributors to forward local ADS-B data and MLAT results to the ADSBItalia aggregation server using dedicated systemd services and a separate `mlat-client` environment.

## Live Map

[Open the live map](https://map.adsbitalia.it/)

## Website

[adsbitalia.it](https://adsbitalia.it/)

---

# Italiano

## Panoramica

ADSBItalia Network è una rete collaborativa ADS-B e MLAT con server centrale in Italia.

Permette ai partecipanti di condividere i propri dati ADS-B locali e, dove disponibile, i risultati MLAT verso il server centrale ADSBItalia, senza stravolgere la propria installazione esistente.

Tutte le connessioni verso ADSBItalia avvengono in uscita: non è necessario aprire porte sul router del feeder.

## Funzioni principali

* Inoltro dei dati Beast al server ADSBItalia sulla porta `31108`
* Connessione MLAT separata tramite `mlat-client` verso la porta `41113`
* Possibilità di ricevere risultati MLAT locali sulla porta `33106`
* Servizi systemd dedicati
* Configurazione semplice tramite script
* Possibilità di aggiornare i dati del feeder senza reinstallare tutto
* Registrazione automatica del feeder sul server ADSBItalia

## Script disponibili

* `install.sh` — installazione iniziale del feeder
* `update.sh` — aggiornamento di nome feeder, coordinate e altitudine
* `uninstall.sh` — rimozione dei servizi ADSBItalia e dell'ambiente MLAT dedicato

## Installazione rapida

Esegui questo comando sul feeder:

```bash
curl -fsSL https://raw.githubusercontent.com/djrexishere91/Adsb-Italia/main/install.sh -o install.sh && bash install.sh
```

## Requisiti

Prima di eseguire l'installazione, assicurati di avere:

* Debian/Ubuntu oppure Arch Linux
* Un decoder ADS-B locale attivo
* Un output Beast locale disponibile su `127.0.0.1` e su una porta TCP configurabile
* Connessione Internet attiva
* Privilegi `sudo`
* Posizione geografica utile alla copertura della rete, consigliata ma non obbligatoria

## Porte utilizzate

| Porta   | Uso                                                                             |
| ------- | ------------------------------------------------------------------------------- |
| `30005` | Porta Beast locale predefinita del feeder, modificabile durante l'installazione |
| `31108` | Porta ADS-B verso ADSBItalia                                                    |
| `41113` | Porta MLAT verso ADSBItalia                                                     |
| `33106` | Porta locale per i risultati MLAT                                               |

## Cosa fa lo script di installazione

Lo script:

* chiede nome feeder, coordinate, altitudine e porta Beast locale
* verifica la presenza di un feed Beast locale su `127.0.0.1` e sulla porta scelta
* installa i pacchetti necessari
* installa `mlat-client` in un ambiente Python dedicato
* registra il feeder sul server ADSBItalia
* crea e abilita i servizi systemd locali
* salva la configurazione in `/etc/adsbitalia/feeder.conf`

## Comandi di gestione

### Stato dei servizi

```bash
sudo systemctl status adsbitalia-feed.service
sudo systemctl status adsbitalia-mlat.service
```

### Log in tempo reale

```bash
sudo journalctl -u adsbitalia-feed.service -f
sudo journalctl -u adsbitalia-mlat.service -f
```

### Controllo porte locali

```bash
ss -tlnp | egrep '30005|31108|33106|41113'
```

## Stato del feeder

Puoi verificare lo stato del feeder dalla pagina:

[Stato del tuo feed](https://adsbitalia.it/status.html)

La pagina mostra registrazione, stato ADS-B, stato MLAT, porte configurate, traffico trasmesso e ultimo aggiornamento.

## Aggiornare i dati del feeder

Se vuoi cambiare nome feeder, coordinate o altitudine, esegui:

```bash
curl -fsSL https://raw.githubusercontent.com/djrexishere91/Adsb-Italia/main/update.sh -o update.sh && bash update.sh
```

Questo script aggiorna i dati salvati localmente e rigenera la configurazione necessaria senza reinstallare tutto.

## Disinstallazione

Per rimuovere ADSBItalia dal feeder:

```bash
curl -fsSL https://raw.githubusercontent.com/djrexishere91/Adsb-Italia/main/uninstall.sh | sudo bash
```

La disinstallazione rimuove solo l'integrazione ADSBItalia e non il decoder ADS-B locale già presente nel sistema.

## File creati localmente

| Percorso                                      | Descrizione                              |
| --------------------------------------------- | ---------------------------------------- |
| `/opt/adsbitalia-mlat`                        | Ambiente Python dedicato a `mlat-client` |
| `/etc/adsbitalia/feeder.conf`                 | Configurazione del feeder                |
| `/etc/systemd/system/adsbitalia-feed.service` | Servizio systemd ADS-B forwarding        |
| `/etc/systemd/system/adsbitalia-mlat.service` | Servizio systemd MLAT                    |

## Risoluzione problemi

Comandi utili per la diagnostica:

```bash
sudo systemctl status adsbitalia-feed.service
sudo systemctl status adsbitalia-mlat.service
sudo journalctl -u adsbitalia-feed.service -n 100 --no-pager
sudo journalctl -u adsbitalia-mlat.service -n 100 --no-pager
```

Verifica anche che il tuo feeder locale stia effettivamente esponendo il feed Beast su `127.0.0.1` e sulla porta configurata durante l'installazione.

## Supporto

Per supporto tecnico, problemi di configurazione, nuove stazioni feeder o collaborazioni:

[Contatta ADSBItalia](https://adsbitalia.it/contatti.html)

---

# English

## Overview

ADSBItalia Network is a collaborative ADS-B and MLAT feeder network with a central aggregation server in Italy.

It allows contributors to forward local ADS-B data and, where available, MLAT results to the ADSBItalia aggregation server without disrupting an existing local ADS-B setup.

All connections to ADSBItalia are outbound: no port forwarding is required on the feeder router.

## Main features

* Beast data forwarding to the ADSBItalia server on port `31108`
* Separate MLAT connection through `mlat-client` to port `41113`
* Option to receive local MLAT results on port `33106`
* Dedicated systemd services
* Simple scripted installation
* Feeder details can be updated without a full reinstall
* Automatic feeder registration on the ADSBItalia server

## Available scripts

* `install.sh` — initial feeder installation
* `update.sh` — update feeder name, coordinates, and altitude
* `uninstall.sh` — remove ADSBItalia services and the dedicated MLAT environment

## Quick install

Run this command on the feeder host:

```bash
curl -fsSL https://raw.githubusercontent.com/djrexishere91/Adsb-Italia/main/install.sh -o install.sh && bash install.sh
```

## Requirements

Before installing, make sure you have:

* Debian/Ubuntu or Arch Linux
* A working local ADS-B decoder
* A local Beast output available on `127.0.0.1` on a configurable TCP port
* Internet connectivity
* `sudo` privileges
* A useful geographic position for network coverage, recommended but not mandatory

## Ports used

| Port    | Purpose                                                                  |
| ------- | ------------------------------------------------------------------------ |
| `30005` | Default local Beast port on the feeder, configurable during installation |
| `31108` | ADS-B feed port to ADSBItalia                                            |
| `41113` | MLAT port to ADSBItalia                                                  |
| `33106` | Local MLAT results port                                                  |

## What the installer does

The installation script:

* asks for feeder name, coordinates, altitude and local Beast port
* checks for a local Beast feed on `127.0.0.1` and the selected port
* installs the required packages
* installs `mlat-client` in a dedicated Python environment
* registers the feeder with the ADSBItalia server
* creates and enables the required local systemd services
* saves configuration in `/etc/adsbitalia/feeder.conf`

## Management commands

### Service status

```bash
sudo systemctl status adsbitalia-feed.service
sudo systemctl status adsbitalia-mlat.service
```

### Follow logs

```bash
sudo journalctl -u adsbitalia-feed.service -f
sudo journalctl -u adsbitalia-mlat.service -f
```

### Local port check

```bash
ss -tlnp | egrep '30005|31108|33106|41113'
```

## Feeder status

You can check your feeder status from:

[Your feed status](https://adsbitalia.it/status.html)

The page shows registration status, ADS-B status, MLAT status, configured ports, transmitted traffic and last update time.

## Update feeder details

If you need to change feeder name, coordinates, or altitude, run:

```bash
curl -fsSL https://raw.githubusercontent.com/djrexishere91/Adsb-Italia/main/update.sh -o update.sh && bash update.sh
```

This updates the locally saved feeder information and refreshes the related configuration without requiring a full reinstall.

## Uninstall

To remove ADSBItalia from the feeder host:

```bash
curl -fsSL https://raw.githubusercontent.com/djrexishere91/Adsb-Italia/main/uninstall.sh | sudo bash
```

The uninstall process removes only the ADSBItalia integration and does not remove the local ADS-B decoder already installed on the system.

## Local files

| Path                                          | Description                                    |
| --------------------------------------------- | ---------------------------------------------- |
| `/opt/adsbitalia-mlat`                        | Dedicated Python environment for `mlat-client` |
| `/etc/adsbitalia/feeder.conf`                 | Feeder configuration                           |
| `/etc/systemd/system/adsbitalia-feed.service` | ADS-B forwarding systemd service               |
| `/etc/systemd/system/adsbitalia-mlat.service` | MLAT systemd service                           |

## Troubleshooting

Useful diagnostic commands:

```bash
sudo systemctl status adsbitalia-feed.service
sudo systemctl status adsbitalia-mlat.service
sudo journalctl -u adsbitalia-feed.service -n 100 --no-pager
sudo journalctl -u adsbitalia-mlat.service -n 100 --no-pager
```

Also make sure your local feeder is actually exposing Beast data on `127.0.0.1` and on the port configured during installation.

## Support

For technical support, configuration issues, new feeder stations or collaborations:

[Contact ADSBItalia](https://adsbitalia.it/contatti.html)

