# ADSBItalia Network

**Global ADS-B and MLAT feeder network born in Italy.**

ADSBItalia is an independent collaborative network that aggregates ADS-B feeds and, where available, MLAT data from feeders around the world.

The project currently supports three ways to contribute:

1. **Classic Linux feeder** using `install.sh`, `systemd`, `socat` and a dedicated `mlat-client` environment.
2. **Ultrafeeder / Docker feeder** by adding ADSBItalia to the outbound feeder configuration, without running `install.sh`.
3. **ADSB.im feeder** by adding ADSBItalia from the ADSB.im web interface, without running `install.sh`.

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

## Choose your setup

### 1. Classic Linux installation

Use this method if you already have a local ADS-B decoder such as:

- `readsb`
- `dump1090-fa`
- `dump1090-mutability`
- another decoder exposing a Beast OUT TCP port

The classic installer configures ADSBItalia services directly on the host.

Run:

```bash
curl -fsSL https://raw.githubusercontent.com/djrexishere91/Adsb-Italia/main/install.sh -o install.sh && bash install.sh
```

The installer asks for:

- feeder name;
- latitude;
- longitude;
- altitude;
- local Beast OUT port;
- optional local ADSBItalia map based on `tar1090`.

`30005` is only the default local Beast OUT port. A different Beast OUT port can be entered during installation.

### 2. Ultrafeeder / Docker

If you use Ultrafeeder/Docker, **do not run `install.sh`**.

Add ADSBItalia directly to your Ultrafeeder outbound configuration using the values published on the website:

[How to join ADSBItalia](https://adsbitalia.it/feeding.html)

Example lines:

```text
adsb,adsbitalia.it,31108,beast_reduce_plus_out;
mlat,mlat.adsbitalia.it,41113,39008
```

The last value in the MLAT line is the local MLAT results port inside your Ultrafeeder configuration. Use a free port that matches your setup.

### 3. ADSB.im

If you use ADSB.im, **do not run `install.sh`**.

ADSB.im can send data to ADSBItalia from its web interface:

1. Open the ADSB.im web interface.
2. Go to **Setup**.
3. Select **Expert**.
4. Find **Add additional Ultrafeeder arguments**.
5. Paste the ADSBItalia lines.
6. Press **Apply**.

![ADSB.im: click Setup and select Expert](https://www.adsbitalia.it/images/adsbim1en.png)

![ADSB.im: paste the ADSBItalia lines and press Apply](https://www.adsbitalia.it/images/adsbim2en.png)

Lines to paste:

```text
adsb,adsbitalia.it,31108,beast_reduce_plus_out;
mlat,mlat.adsbitalia.it,41113,39008;
```

After applying the change, check your feeder status here:

[Your feed status](https://adsbitalia.it/status.html)

## Main ports

| Port | Use |
| --- | --- |
| `30005` | Default local Beast OUT port on classic feeders. It can be changed during installation. |
| `31108` | Main ADS-B Beast input port to ADSBItalia. |
| `31106` | Legacy/mux ADS-B port for old feeders not updated yet. Do not use it for new installations. |
| `41113` | MLAT server port. |
| `33106` | Local MLAT results port on the feeder side for classic installations. |
| `39008` | Example local MLAT results port for Ultrafeeder/ADSB.im configurations. |

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

If you use Ultrafeeder/Docker or ADSB.im, do not install a separate `tar1090` map from the ADSBItalia script. Use the web interface already provided by your existing platform.

## Management commands

### Classic installation

Service status:

```bash
sudo systemctl status adsbitalia-feed.service
sudo systemctl status adsbitalia-mlat.service
```

Live logs:

```bash
sudo journalctl -u adsbitalia-feed.service -f
sudo journalctl -u adsbitalia-mlat.service -f
```

Check local and remote connections:

```bash
ss -tlnp | egrep '30005|33106'
ss -tnp | egrep '31108|41113'
```

### Ultrafeeder / Docker

```bash
docker ps | grep -i ultrafeeder
docker logs -f ultrafeeder
```

Docker Compose:

```bash
docker compose ps
docker compose logs -f ultrafeeder
```

### ADSB.im

Use the ADSB.im web interface:

```text
Setup → Expert → Add additional Ultrafeeder arguments
```

Then check:

[Your feed status](https://adsbitalia.it/status.html)

## Feeder status page

You can check the status of your feeder here:

[Your feed status](https://adsbitalia.it/status.html)

The status page supports:

- classic ADSBItalia feeders;
- legacy/mux feeders still using the old port;
- Ultrafeeder/Docker feeders;
- ADSB.im feeders.

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

To update feeder name, coordinates or altitude on a classic installation:

```bash
curl -fsSL https://raw.githubusercontent.com/djrexishere91/Adsb-Italia/main/update.sh -o update.sh && bash update.sh
```

For Ultrafeeder/Docker or ADSB.im, update the details in your existing platform/configuration.

## Uninstall

To remove ADSBItalia from a classic feeder:

```bash
curl -fsSL https://raw.githubusercontent.com/djrexishere91/Adsb-Italia/main/uninstall.sh | sudo bash
```

The uninstall process removes only the ADSBItalia integration. It does not remove your local ADS-B decoder.

If the optional ADSBItalia `tar1090` local map was installed by the ADSBItalia installer, the uninstall script also removes that optional local map.

For Ultrafeeder/Docker or ADSB.im, remove the ADSBItalia lines from the configuration and apply/restart the service.

## Files created by the classic installer

| Path | Description |
| --- | --- |
| `/etc/adsbitalia/feeder.conf` | ADSBItalia feeder configuration. |
| `/opt/adsbitalia-mlat` | Dedicated Python environment for `mlat-client`. |
| `/etc/systemd/system/adsbitalia-feed.service` | ADS-B forwarding service. |
| `/etc/systemd/system/adsbitalia-mlat.service` | MLAT service. |
| local `tar1090` directory | Optional local map, only if selected during installation. |

These files are not created when joining through Ultrafeeder/Docker or ADSB.im.

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
docker compose logs -f ultrafeeder
```

ADSB.im:

- verify that the ADSBItalia lines are still present in **Setup → Expert**;
- verify that every line ends with a semicolon;
- press **Apply** again after editing;
- check the ADSBItalia status page.

Also verify that your local feeder is generating ADS-B data and that outbound connections to ADSBItalia are allowed.

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

- nome feeder;
- latitudine;
- longitudine;
- altitudine;
- porta Beast OUT locale;
- eventuale mappa locale ADSBItalia basata su `tar1090`.

Durante l’installazione classica la porta Beast OUT locale è modificabile. `30005` è solo il valore predefinito.

### 2. Ultrafeeder / Docker

Se usi Ultrafeeder/Docker, **non devi eseguire `install.sh`**.

Gli utenti Ultrafeeder devono aggiungere ADSBItalia direttamente nella configurazione Docker usando i dati pubblicati sul sito:

[Come partecipare ad ADSBItalia](https://adsbitalia.it/feeding.html)

In questo modo Ultrafeeder resta pulito e non vengono installati servizi duplicati sull’host.

Righe di esempio:

```text
adsb,adsbitalia.it,31108,beast_reduce_plus_out;
mlat,mlat.adsbitalia.it,41113,39008
```

L’ultimo valore della riga MLAT è la porta locale dei risultati MLAT dentro la configurazione Ultrafeeder. Usa una porta libera coerente con il tuo setup.

### 3. ADSB.im

Se usi ADSB.im, **non devi eseguire `install.sh`**.

ADSB.im può inviare dati ad ADSBItalia direttamente dalla sua interfaccia web:

1. Apri l’interfaccia web di ADSB.im.
2. Vai su **Setup**.
3. Seleziona **Expert**.
4. Trova **Add additional Ultrafeeder arguments**.
5. Incolla le righe ADSBItalia.
6. Premi **Apply**.

![ADSB.im: clicca Setup e seleziona Expert](https://www.adsbitalia.it/images/adsbim1it.png)

![ADSB.im: incolla le righe ADSBItalia e premi Apply](https://www.adsbitalia.it/images/adsbim2it.png)

Righe da incollare:

```text
adsb,adsbitalia.it,31108,beast_reduce_plus_out;
mlat,mlat.adsbitalia.it,41113,39008;
```

Dopo aver applicato la modifica, controlla lo stato del feeder qui:

[Stato del tuo feed](https://adsbitalia.it/status.html)

## Porte principali

| Porta | Uso |
| --- | --- |
| `30005` | Porta Beast OUT locale predefinita sui feeder classici. Può essere cambiata durante l’installazione. |
| `31108` | Porta ADS-B Beast principale verso ADSBItalia. |
| `31106` | Porta ADS-B legacy/mux per vecchi feeder non ancora aggiornati. Non usarla per nuove installazioni. |
| `41113` | Porta server MLAT. |
| `33106` | Porta locale dei risultati MLAT lato feeder per installazioni classiche. |
| `39008` | Esempio di porta locale risultati MLAT per configurazioni Ultrafeeder/ADSB.im. |

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

Se usi Ultrafeeder/Docker o ADSB.im, non installare una mappa `tar1090` separata tramite lo script ADSBItalia. Usa l’interfaccia web già fornita dalla tua piattaforma.

## Comandi di gestione

### Installazione classica

Stato servizi:

```bash
sudo systemctl status adsbitalia-feed.service
sudo systemctl status adsbitalia-mlat.service
```

Log live:

```bash
sudo journalctl -u adsbitalia-feed.service -f
sudo journalctl -u adsbitalia-mlat.service -f
```

Controllo porte e connessioni:

```bash
ss -tlnp | egrep '30005|33106'
ss -tnp | egrep '31108|41113'
```

### Ultrafeeder / Docker

```bash
docker ps | grep -i ultrafeeder
docker logs -f ultrafeeder
```

Docker Compose:

```bash
docker compose ps
docker compose logs -f ultrafeeder
```

### ADSB.im

Usa l’interfaccia web ADSB.im:

```text
Setup → Expert → Add additional Ultrafeeder arguments
```

Poi controlla:

[Stato del tuo feed](https://adsbitalia.it/status.html)

## Stato del feeder

Puoi controllare lo stato del feeder qui:

[Stato del tuo feed](https://adsbitalia.it/status.html)

La pagina stato supporta:

- feeder classici ADSBItalia;
- feeder legacy/mux ancora sulla vecchia porta;
- feeder Ultrafeeder/Docker;
- feeder ADSB.im.

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

Per aggiornare nome feeder, coordinate o altitudine su un’installazione classica:

```bash
curl -fsSL https://raw.githubusercontent.com/djrexishere91/Adsb-Italia/main/update.sh -o update.sh && bash update.sh
```

Per Ultrafeeder/Docker o ADSB.im, aggiorna i dati dalla piattaforma o dalla configurazione che stai usando.

## Disinstallazione

Per rimuovere ADSBItalia da un feeder classico:

```bash
curl -fsSL https://raw.githubusercontent.com/djrexishere91/Adsb-Italia/main/uninstall.sh | sudo bash
```

La disinstallazione rimuove solo l’integrazione ADSBItalia. Non rimuove il decoder ADS-B locale.

Se la mappa locale opzionale `tar1090` ADSBItalia era stata installata dallo script ADSBItalia, lo script di disinstallazione rimuove anche quella mappa opzionale.

Per Ultrafeeder/Docker o ADSB.im basta rimuovere le righe ADSBItalia dalla configurazione e applicare/riavviare il servizio.

## File creati dall’installer classico

| Percorso | Descrizione |
| --- | --- |
| `/etc/adsbitalia/feeder.conf` | Configurazione feeder ADSBItalia. |
| `/opt/adsbitalia-mlat` | Ambiente Python dedicato a `mlat-client`. |
| `/etc/systemd/system/adsbitalia-feed.service` | Servizio ADS-B forwarding. |
| `/etc/systemd/system/adsbitalia-mlat.service` | Servizio MLAT. |
| directory locale `tar1090` | Mappa locale opzionale, solo se scelta durante l’installazione. |

Questi file non vengono creati se partecipi tramite Ultrafeeder/Docker o ADSB.im.

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
docker compose logs -f ultrafeeder
```

ADSB.im:

- verifica che le righe ADSBItalia siano ancora presenti in **Setup → Expert**;
- verifica che ogni riga finisca con il punto e virgola;
- premi di nuovo **Apply** dopo eventuali modifiche;
- controlla la pagina stato ADSBItalia.

Verifica anche che il feeder locale stia generando dati ADS-B e che le connessioni in uscita verso ADSBItalia siano consentite.

## Supporto

Per supporto tecnico, configurazione feeder, problemi di connessione, MLAT o collaborazioni:

[Contatta ADSBItalia](https://adsbitalia.it/contatti.html)
