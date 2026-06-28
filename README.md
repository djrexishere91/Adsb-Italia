# ADSBItalia Network

Collaborative global ADS-B and MLAT feeder network born in Italy.

ADSBItalia allows contributors to forward local ADS-B data and, where available, MLAT results to the ADSBItalia aggregation server. The network supports classic Linux installations using dedicated `systemd` services and also supports Ultrafeeder/Docker configurations.

All connections to ADSBItalia are outbound from the feeder to the ADSBItalia servers. No router port forwarding is required on the feeder side.

## Live Map

[Open the live map](https://map.adsbitalia.it/)

## Website

[adsbitalia.it](https://adsbitalia.it/)

---

# Italiano

## Panoramica

ADSBItalia Network è una rete collaborativa globale ADS-B e MLAT nata in Italia.

Permette ai partecipanti di condividere i propri dati ADS-B locali e, dove disponibile, i risultati MLAT verso il server centrale ADSBItalia, senza stravolgere la propria installazione esistente.

La rete supporta due modalità principali:

- **Installazione classica**, tramite `install.sh`, con servizi `systemd` dedicati.
- **Ultrafeeder / Docker**, configurando ADSBItalia direttamente tra gli outbound feeder del container, senza usare `install.sh`.

Tutte le connessioni verso ADSBItalia avvengono in uscita: non è necessario aprire porte sul router del feeder.

## Modalità supportate

### Installazione classica

Usa questa modalità se hai un decoder ADS-B locale già attivo, come `readsb`, `dump1090-fa`, `dump1090-mutability` o sistemi compatibili, con una porta Beast OUT locale disponibile.

Lo script `install.sh` configura:

- inoltro ADS-B verso ADSBItalia;
- client MLAT dedicato;
- registrazione automatica del feeder;
- servizi `systemd`;
- mappa locale ADSBItalia basata su `tar1090`, opzionale.

### Ultrafeeder / Docker

Se usi Ultrafeeder/Docker, **non devi eseguire `install.sh`**.

In questo caso ADSBItalia va aggiunta direttamente alla configurazione outbound del container, usando i parametri pubblicati nella pagina:

[Come partecipare](https://adsbitalia.it/feeding.html)

Ultrafeeder mantiene la propria configurazione Docker e invia una copia del feed verso ADSBItalia.

## Funzioni principali

- Inoltro dei dati Beast al server ADSBItalia sulla porta `31108`.
- Connessione MLAT separata tramite `mlat-client` verso la porta `41113`.
- Possibilità di ricevere risultati MLAT locali sulla porta `33106`.
- Servizi `systemd` dedicati per installazioni classiche.
- Supporto a configurazioni Ultrafeeder/Docker.
- Configurazione semplice tramite script per installazioni classiche.
- Possibilità di aggiornare i dati del feeder senza reinstallare tutto.
- Registrazione automatica del feeder sul server ADSBItalia.
- Mappa locale opzionale basata su `tar1090`, personalizzata ADSBItalia.

## Script disponibili

- `install.sh` — installazione iniziale del feeder classico.
- `update.sh` — aggiornamento di nome feeder, coordinate e altitudine.
- `uninstall.sh` — rimozione dei servizi ADSBItalia e dell'ambiente MLAT dedicato.

## Installazione rapida

Esegui questo comando sul feeder classico:

```bash
curl -fsSL https://raw.githubusercontent.com/djrexishere91/Adsb-Italia/main/install.sh -o install.sh && bash install.sh
```

Durante l'installazione lo script chiede:

- nome del feeder;
- latitudine;
- longitudine;
- altitudine;
- porta Beast OUT locale;
- eventuale installazione facoltativa della mappa locale ADSBItalia basata su `tar1090`.

## Requisiti

Prima di eseguire l'installazione classica, assicurati di avere:

- Debian/Ubuntu/Raspberry Pi OS oppure Arch Linux;
- un decoder ADS-B locale attivo;
- un output Beast locale disponibile su `127.0.0.1` e su una porta TCP configurabile;
- connessione Internet attiva;
- privilegi `sudo`;
- posizione geografica utile alla copertura della rete, consigliata ma non obbligatoria.

Per Ultrafeeder/Docker non usare `install.sh`: segui la configurazione indicata nella pagina [Come partecipare](https://adsbitalia.it/feeding.html).

## Porte utilizzate

| Porta   | Uso                                                                                           |
| ------- | --------------------------------------------------------------------------------------------- |
| `30005` | Porta Beast locale predefinita del feeder, modificabile durante l'installazione classica       |
| `31108` | Porta ADS-B principale verso ADSBItalia                                                       |
| `31106` | Porta ADS-B legacy/mux per vecchi feeder non ancora aggiornati                                 |
| `41113` | Porta MLAT verso ADSBItalia                                                                   |
| `33106` | Porta locale per i risultati MLAT                                                             |

## Cosa fa lo script di installazione

Lo script `install.sh`:

- chiede nome feeder, coordinate, altitudine e porta Beast locale;
- verifica la presenza di un feed Beast locale su `127.0.0.1` e sulla porta scelta;
- installa i pacchetti necessari;
- installa `mlat-client` in un ambiente Python dedicato;
- registra il feeder sul server ADSBItalia;
- crea e abilita i servizi `systemd` locali;
- salva la configurazione in `/etc/adsbitalia/feeder.conf`;
- chiede se installare anche una mappa locale ADSBItalia basata su `tar1090`.

`install.sh` usa i repository ufficiali upstream per i componenti esterni:

- `mlat-client`: `https://github.com/wiedehopf/mlat-client.git`
- `tar1090`: `https://github.com/wiedehopf/tar1090.git`

La mappa `tar1090` è facoltativa. Se installata, viene personalizzata con branding ADSBItalia e lo script mostra l'URL locale per aprirla dalla rete LAN, ad esempio:

```text
http://192.168.1.50/tar1090/
```

Se viene rilevato Ultrafeeder/Docker, lo script non installa una mappa `tar1090` separata e consiglia di usare l'interfaccia già fornita dal container.

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

### Controllo connessioni verso ADSBItalia

```bash
ss -tnp | egrep '31108|41113'
```

## Stato del feeder

Puoi verificare lo stato del feeder dalla pagina:

[Stato del tuo feed](https://adsbitalia.it/status.html)

La pagina mostra registrazione, stato ADS-B, stato MLAT, modalità feed, porte configurate, traffico trasmesso e ultimo aggiornamento.

La pagina supporta:

- installazioni classiche ADSBItalia;
- feeder legacy/mux ancora non aggiornati;
- configurazioni Ultrafeeder/Docker.

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

| Percorso                                      | Descrizione                                             |
| --------------------------------------------- | ------------------------------------------------------- |
| `/opt/adsbitalia-mlat`                        | Ambiente Python dedicato a `mlat-client`                |
| `/etc/adsbitalia/feeder.conf`                 | Configurazione del feeder                               |
| `/etc/systemd/system/adsbitalia-feed.service` | Servizio `systemd` ADS-B forwarding                     |
| `/etc/systemd/system/adsbitalia-mlat.service` | Servizio `systemd` MLAT                                 |
| directory `tar1090` locale                    | Mappa locale opzionale, se scelta durante l'installazione |

## Risoluzione problemi

Comandi utili per la diagnostica delle installazioni classiche:

```bash
sudo systemctl status adsbitalia-feed.service
sudo systemctl status adsbitalia-mlat.service
sudo journalctl -u adsbitalia-feed.service -n 100 --no-pager
sudo journalctl -u adsbitalia-mlat.service -n 100 --no-pager
```

Verifica anche che il feeder locale stia effettivamente esponendo il feed Beast su `127.0.0.1` e sulla porta configurata durante l'installazione.

Per Ultrafeeder/Docker, controlla il container:

```bash
docker ps | grep -i ultrafeeder
docker logs -f ultrafeeder
```

oppure, se usi Docker Compose:

```bash
docker compose ps
docker compose logs -f ultrafeeder
```

## Supporto

Per supporto tecnico, problemi di configurazione, nuove stazioni feeder o collaborazioni:

[Contatta ADSBItalia](https://adsbitalia.it/contatti.html)

---

# English

## Overview

ADSBItalia Network is a collaborative global ADS-B and MLAT feeder network born in Italy.

It allows contributors to forward local ADS-B data and, where available, MLAT results to the ADSBItalia aggregation server without disrupting an existing local ADS-B setup.

The network supports two main modes:

- **Classic installation**, using `install.sh` and dedicated `systemd` services.
- **Ultrafeeder / Docker**, by adding ADSBItalia directly to the container outbound feeder configuration, without using `install.sh`.

All connections to ADSBItalia are outbound: no port forwarding is required on the feeder router.

## Supported modes

### Classic installation

Use this mode if you already have a local ADS-B decoder running, such as `readsb`, `dump1090-fa`, `dump1090-mutability` or a compatible system, with a local Beast OUT port available.

The `install.sh` script configures:

- ADS-B forwarding to ADSBItalia;
- a dedicated MLAT client;
- automatic feeder registration;
- `systemd` services;
- an optional local ADSBItalia map based on `tar1090`.

### Ultrafeeder / Docker

If you use Ultrafeeder/Docker, **do not run `install.sh`**.

In this case, add ADSBItalia directly to your container outbound feeder configuration using the parameters published on:

[How to join](https://adsbitalia.it/feeding.html)

Ultrafeeder keeps its own Docker configuration and sends a copy of the feed to ADSBItalia.

## Main features

- Beast data forwarding to the ADSBItalia server on port `31108`.
- Separate MLAT connection through `mlat-client` to port `41113`.
- Option to receive local MLAT results on port `33106`.
- Dedicated `systemd` services for classic installations.
- Support for Ultrafeeder/Docker configurations.
- Simple scripted setup for classic installations.
- Feeder details can be updated without a full reinstall.
- Automatic feeder registration on the ADSBItalia server.
- Optional local map based on `tar1090`, customized with ADSBItalia branding.

## Available scripts

- `install.sh` — initial classic feeder installation.
- `update.sh` — update feeder name, coordinates, and altitude.
- `uninstall.sh` — remove ADSBItalia services and the dedicated MLAT environment.

## Quick install

Run this command on the classic feeder host:

```bash
curl -fsSL https://raw.githubusercontent.com/djrexishere91/Adsb-Italia/main/install.sh -o install.sh && bash install.sh
```

During installation, the script asks for:

- feeder name;
- latitude;
- longitude;
- altitude;
- local Beast OUT port;
- optional installation of the local ADSBItalia map based on `tar1090`.

## Requirements

Before running the classic installer, make sure you have:

- Debian/Ubuntu/Raspberry Pi OS or Arch Linux;
- a working local ADS-B decoder;
- a local Beast output available on `127.0.0.1` on a configurable TCP port;
- Internet connectivity;
- `sudo` privileges;
- a useful geographic position for network coverage, recommended but not mandatory.

For Ultrafeeder/Docker, do not use `install.sh`: follow the configuration shown on [How to join](https://adsbitalia.it/feeding.html).

## Ports used

| Port    | Purpose                                                                                   |
| ------- | ----------------------------------------------------------------------------------------- |
| `30005` | Default local Beast port on the feeder, configurable during classic installation           |
| `31108` | Main ADS-B feed port to ADSBItalia                                                        |
| `31106` | Legacy/mux ADS-B port for old feeders not updated yet                                     |
| `41113` | MLAT port to ADSBItalia                                                                   |
| `33106` | Local MLAT results port                                                                   |

## What the installer does

The `install.sh` script:

- asks for feeder name, coordinates, altitude and local Beast port;
- checks for a local Beast feed on `127.0.0.1` and the selected port;
- installs the required packages;
- installs `mlat-client` in a dedicated Python environment;
- registers the feeder with the ADSBItalia server;
- creates and enables the required local `systemd` services;
- saves configuration in `/etc/adsbitalia/feeder.conf`;
- asks whether to install an optional local ADSBItalia map based on `tar1090`.

`install.sh` uses the official upstream repositories for external components:

- `mlat-client`: `https://github.com/wiedehopf/mlat-client.git`
- `tar1090`: `https://github.com/wiedehopf/tar1090.git`

The `tar1090` map is optional. If installed, it is customized with ADSBItalia branding and the script displays the local LAN URL to open it, for example:

```text
http://192.168.1.50/tar1090/
```

If Ultrafeeder/Docker is detected, the script does not install a separate `tar1090` map and suggests using the web interface already provided by the container.

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

### Check connections to ADSBItalia

```bash
ss -tnp | egrep '31108|41113'
```

## Feeder status

You can check your feeder status from:

[Your feed status](https://adsbitalia.it/status.html)

The page shows registration status, ADS-B status, MLAT status, feed mode, configured ports, transmitted traffic and last update time.

The page supports:

- classic ADSBItalia installations;
- legacy/mux feeders not updated yet;
- Ultrafeeder/Docker configurations.

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

| Path                                          | Description                                                   |
| --------------------------------------------- | ------------------------------------------------------------- |
| `/opt/adsbitalia-mlat`                        | Dedicated Python environment for `mlat-client`                |
| `/etc/adsbitalia/feeder.conf`                 | Feeder configuration                                          |
| `/etc/systemd/system/adsbitalia-feed.service` | ADS-B forwarding `systemd` service                            |
| `/etc/systemd/system/adsbitalia-mlat.service` | MLAT `systemd` service                                        |
| local `tar1090` directory                     | Optional local map, if selected during installation            |

## Troubleshooting

Useful diagnostic commands for classic installations:

```bash
sudo systemctl status adsbitalia-feed.service
sudo systemctl status adsbitalia-mlat.service
sudo journalctl -u adsbitalia-feed.service -n 100 --no-pager
sudo journalctl -u adsbitalia-mlat.service -n 100 --no-pager
```

Also make sure your local feeder is actually exposing Beast data on `127.0.0.1` and on the port configured during installation.

For Ultrafeeder/Docker, check the container:

```bash
docker ps | grep -i ultrafeeder
docker logs -f ultrafeeder
```

or, if you use Docker Compose:

```bash
docker compose ps
docker compose logs -f ultrafeeder
```

## Support

For technical support, configuration issues, new feeder stations or collaborations:

[Contact ADSBItalia](https://adsbitalia.it/contatti.html)

