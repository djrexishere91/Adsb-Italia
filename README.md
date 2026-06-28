# ADSBItalia Network

**Global ADS-B and MLAT feeder network born in Italy.**

ADSBItalia is an independent collaborative network that aggregates ADS-B feeds and, where available, MLAT data from feeders around the world.

The project supports two different ways to contribute:

1. **Classic Linux feeder** using `install.sh`, `systemd`, `socat` and a dedicated `mlat-client` environment.
2. **Ultrafeeder / Docker feeder** using the configuration published on the ADSBItalia website, without running `install.sh`.

All feeder connections are outbound. You do **not** need to open ports on your router.

## Links

- Live map: [map.adsbitalia.it](https://map.adsbitalia.it/)
- Website: [adsbitalia.it](https://adsbitalia.it/)
- Feed status: [adsbitalia.it/status.html](https://adsbitalia.it/status.html)
- How to join: [adsbitalia.it/feeding.html](https://adsbitalia.it/feeding.html)
- Contact: [adsbitalia.it/contatti.html](https://adsbitalia.it/contatti.html)

---

# English

## Overview

ADSBItalia Network is a global collaborative ADS-B and MLAT feeder network born in Italy.

It allows contributors to send a copy of their local ADS-B data, and where available MLAT results, to the ADSBItalia aggregation server without replacing or breaking their existing local setup.

ADSBItalia is not limited to Italian feeders. The project is open to stable and useful feeder stations from anywhere in the world.

## Choose your installation type

### 1. Classic Linux installation

Use this method if you already have a local ADS-B decoder such as:

- `readsb`
- `dump1090-fa`
- `dump1090-mutability`
- another decoder exposing a Beast OUT TCP port

The classic installer configures ADSBItalia services on the host.

Use:

```bash
curl -fsSL https://raw.githubusercontent.com/djrexishere91/Adsb-Italia/main/install.sh -o install.sh && bash install.sh
```

The installer will ask for:

- feeder name
- latitude
- longitude
- altitude
- local Beast OUT port
- optional local ADSBItalia map based on `tar1090`

### 2. Ultrafeeder / Docker

If you use Ultrafeeder/Docker, **do not run `install.sh`**.

Ultrafeeder users must add ADSBItalia directly to their Docker configuration using the values published on the website:

[How to join ADSBItalia](https://adsbitalia.it/feeding.html)

This keeps the Ultrafeeder setup clean and avoids installing duplicate services on the host.

## Main ports

| Port | Use |
| --- | --- |
| `30005` | Default local Beast OUT port on classic feeders. It can be changed during installation. |
| `31108` | Main ADS-B Beast input port to ADSBItalia. |
| `31106` | Legacy/mux ADS-B port for old feeders not updated yet. Do not use it for new installations. |
| `41113` | MLAT server port. |
| `33106` | Local MLAT results port on the feeder side. |

## What `install.sh` does

The classic installer:

- checks the local Beast OUT feed on `127.0.0.1`;
- installs required packages;
- installs `mlat-client` in `/opt/adsbitalia-mlat`;
- creates a unique feeder identity;
- registers the feeder with the ADSBItalia API;
- creates `adsbitalia-feed.service`;
- creates `adsbitalia-mlat.service`;
- saves configuration in `/etc/adsbitalia/feeder.conf`;
- optionally installs a local ADSBItalia-branded `tar1090` map.

The installer uses the official upstream repositories for external components:

- `mlat-client`: `https://github.com/wiedehopf/mlat-client.git`
- `tar1090`: `https://github.com/wiedehopf/tar1090.git`

## Optional local tar1090 map

During the classic installation, the script can optionally install a local web map based on `tar1090`.

This is optional and is meant only for classic host-based installations.

If installed, the map is customized with ADSBItalia branding and the installer displays the local LAN URL, for example:

```text
http://192.168.1.50/tar1090/
```

If Ultrafeeder/Docker is detected, the script skips this optional map and recommends using the web interface already provided by Ultrafeeder.

## Management commands

### Service status

```bash
sudo systemctl status adsbitalia-feed.service
sudo systemctl status adsbitalia-mlat.service
```

### Live logs

```bash
sudo journalctl -u adsbitalia-feed.service -f
sudo journalctl -u adsbitalia-mlat.service -f
```

### Check local and remote connections

```bash
ss -tlnp | egrep '30005|33106'
ss -tnp | egrep '31108|41113'
```

## Feeder status page

You can check the status of your feeder here:

[Your feed status](https://adsbitalia.it/status.html)

The status page supports:

- classic ADSBItalia feeders;
- legacy/mux feeders still using the old port;
- Ultrafeeder/Docker feeders.

It shows:

- detected public IP;
- feeder name;
- hostname;
- feed mode;
- ADS-B connection status;
- MLAT connection status;
- configured ports;
- transmitted traffic;
- last update time.

## Update feeder details

To update feeder name, coordinates or altitude:

```bash
curl -fsSL https://raw.githubusercontent.com/djrexishere91/Adsb-Italia/main/update.sh -o update.sh && bash update.sh
```

## Uninstall

To remove ADSBItalia from a classic feeder:

```bash
curl -fsSL https://raw.githubusercontent.com/djrexishere91/Adsb-Italia/main/uninstall.sh | sudo bash
```

The uninstall process removes only the ADSBItalia integration. It does not remove your local ADS-B decoder.

## Files created by the classic installer

| Path | Description |
| --- | --- |
| `/etc/adsbitalia/feeder.conf` | ADSBItalia feeder configuration. |
| `/opt/adsbitalia-mlat` | Dedicated Python environment for `mlat-client`. |
| `/etc/systemd/system/adsbitalia-feed.service` | ADS-B forwarding service. |
| `/etc/systemd/system/adsbitalia-mlat.service` | MLAT service. |
| local `tar1090` directory | Optional local map, only if selected during installation. |

## Troubleshooting

Classic installation:

```bash
sudo systemctl status adsbitalia-feed.service
sudo systemctl status adsbitalia-mlat.service
sudo journalctl -u adsbitalia-feed.service -n 100 --no-pager
sudo journalctl -u adsbitalia-mlat.service -n 100 --no-pager
```

Ultrafeeder / Docker:

```bash
docker ps | grep -i ultrafeeder
docker logs -f ultrafeeder
```

Docker Compose:

```bash
docker compose ps
docker compose logs -f ultrafeeder
```

Also verify that the local Beast OUT feed exists on the port you configured.

## Support

For technical support, feeder setup, connection issues, MLAT problems or collaborations:

[Contact ADSBItalia](https://adsbitalia.it/contatti.html)

---

# Italiano

## Panoramica

ADSBItalia Network è una rete collaborativa globale ADS-B e MLAT nata in Italia.

Permette ai feeder di inviare una copia dei dati ADS-B locali e, dove disponibili, i risultati MLAT verso il server centrale ADSBItalia, senza sostituire o rompere l’installazione già esistente.

ADSBItalia non è limitata ai feeder italiani. La rete è aperta a stazioni stabili e utili da tutto il mondo.

## Scegli il tipo di installazione

### 1. Installazione classica Linux

Usa questo metodo se hai già un decoder ADS-B locale, per esempio:

- `readsb`
- `dump1090-fa`
- `dump1090-mutability`
- altro decoder con porta TCP Beast OUT

L’installer classico configura i servizi ADSBItalia direttamente sull’host.

Comando:

```bash
curl -fsSL https://raw.githubusercontent.com/djrexishere91/Adsb-Italia/main/install.sh -o install.sh && bash install.sh
```

Lo script chiede:

- nome feeder
- latitudine
- longitudine
- altitudine
- porta Beast OUT locale
- eventuale mappa locale ADSBItalia basata su `tar1090`

### 2. Ultrafeeder / Docker

Se usi Ultrafeeder/Docker, **non devi eseguire `install.sh`**.

Gli utenti Ultrafeeder devono aggiungere ADSBItalia direttamente nella configurazione Docker usando i dati pubblicati sul sito:

[Come partecipare ad ADSBItalia](https://adsbitalia.it/feeding.html)

In questo modo Ultrafeeder resta pulito e non vengono installati servizi duplicati sull’host.

## Porte principali

| Porta | Uso |
| --- | --- |
| `30005` | Porta Beast OUT locale predefinita sui feeder classici. Può essere cambiata durante l’installazione. |
| `31108` | Porta ADS-B Beast principale verso ADSBItalia. |
| `31106` | Porta ADS-B legacy/mux per vecchi feeder non ancora aggiornati. Non usarla per nuove installazioni. |
| `41113` | Porta server MLAT. |
| `33106` | Porta locale dei risultati MLAT lato feeder. |

## Cosa fa `install.sh`

L’installer classico:

- controlla il feed Beast OUT locale su `127.0.0.1`;
- installa i pacchetti necessari;
- installa `mlat-client` in `/opt/adsbitalia-mlat`;
- crea un’identità feeder univoca;
- registra il feeder tramite API ADSBItalia;
- crea `adsbitalia-feed.service`;
- crea `adsbitalia-mlat.service`;
- salva la configurazione in `/etc/adsbitalia/feeder.conf`;
- opzionalmente installa una mappa locale `tar1090` personalizzata ADSBItalia.

Lo script usa i repository ufficiali upstream per i componenti esterni:

- `mlat-client`: `https://github.com/wiedehopf/mlat-client.git`
- `tar1090`: `https://github.com/wiedehopf/tar1090.git`

## Mappa locale tar1090 opzionale

Durante l’installazione classica, lo script può installare facoltativamente una mappa locale basata su `tar1090`.

È opzionale ed è pensata solo per installazioni classiche sull’host.

Se installata, la mappa viene personalizzata con branding ADSBItalia e lo script mostra l’URL locale LAN, per esempio:

```text
http://192.168.1.50/tar1090/
```

Se viene rilevato Ultrafeeder/Docker, lo script salta questa mappa opzionale e consiglia di usare l’interfaccia web già fornita da Ultrafeeder.

## Comandi di gestione

### Stato servizi

```bash
sudo systemctl status adsbitalia-feed.service
sudo systemctl status adsbitalia-mlat.service
```

### Log live

```bash
sudo journalctl -u adsbitalia-feed.service -f
sudo journalctl -u adsbitalia-mlat.service -f
```

### Controllo porte e connessioni

```bash
ss -tlnp | egrep '30005|33106'
ss -tnp | egrep '31108|41113'
```

## Stato del feeder

Puoi controllare lo stato del feeder qui:

[Stato del tuo feed](https://adsbitalia.it/status.html)

La pagina stato supporta:

- feeder classici ADSBItalia;
- feeder legacy/mux ancora sulla vecchia porta;
- feeder Ultrafeeder/Docker.

Mostra:

- IP pubblico rilevato;
- nome feeder;
- hostname;
- modalità feed;
- stato ADS-B;
- stato MLAT;
- porte configurate;
- traffico trasmesso;
- ultimo aggiornamento.

## Aggiornare i dati del feeder

Per aggiornare nome feeder, coordinate o altitudine:

```bash
curl -fsSL https://raw.githubusercontent.com/djrexishere91/Adsb-Italia/main/update.sh -o update.sh && bash update.sh
```

## Disinstallazione

Per rimuovere ADSBItalia da un feeder classico:

```bash
curl -fsSL https://raw.githubusercontent.com/djrexishere91/Adsb-Italia/main/uninstall.sh | sudo bash
```

La disinstallazione rimuove solo l’integrazione ADSBItalia. Non rimuove il decoder ADS-B locale.

## File creati dall’installer classico

| Percorso | Descrizione |
| --- | --- |
| `/etc/adsbitalia/feeder.conf` | Configurazione feeder ADSBItalia. |
| `/opt/adsbitalia-mlat` | Ambiente Python dedicato a `mlat-client`. |
| `/etc/systemd/system/adsbitalia-feed.service` | Servizio ADS-B forwarding. |
| `/etc/systemd/system/adsbitalia-mlat.service` | Servizio MLAT. |
| directory locale `tar1090` | Mappa locale opzionale, solo se scelta durante l’installazione. |

## Risoluzione problemi

Installazione classica:

```bash
sudo systemctl status adsbitalia-feed.service
sudo systemctl status adsbitalia-mlat.service
sudo journalctl -u adsbitalia-feed.service -n 100 --no-pager
sudo journalctl -u adsbitalia-mlat.service -n 100 --no-pager
```

Ultrafeeder / Docker:

```bash
docker ps | grep -i ultrafeeder
docker logs -f ultrafeeder
```

Docker Compose:

```bash
docker compose ps
docker compose logs -f ultrafeeder
```

Verifica anche che il feed Beast OUT locale esista sulla porta configurata.

## Supporto

Per supporto tecnico, configurazione feeder, problemi di connessione, MLAT o collaborazioni:

[Contatta ADSBItalia](https://adsbitalia.it/contatti.html)
