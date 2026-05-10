
# 📡 ADSB-Italia Network

Benvenuto nella rete **ADSB-Italia**! Questo progetto nasce per creare una rete collaborativa di stazioni di ricezione ADS-B per il tracciamento dei voli nei cieli italiani. Il server di coordinamento e la mappa centrale sono situati a **Fiscaglia (FE)**.

Partecipando alla rete, i tuoi dati contribuiranno alla triangolazione **MLAT**, permettendo di localizzare anche gli aerei che non trasmettono la loro posizione GPS (Mode-S).

## 🗺️ Visualizza la Mappa Live
Puoi vedere tutti i dati aggregati della rete qui:
👉 [https://adsb.djrexishere.it/combine1090/](https://adsb.djrexishere.it/combine1090/)

---

## 🚀 Come unirsi alla rete

L'installazione è completamente automatizzata. Lo script scaricherà il `mlat-client`, configurerà i canali di comunicazione e inizierà a inviare i dati al server centrale.

### Prerequisiti
* Un Raspberry Pi o un Mini-PC con Linux (Debian/Ubuntu/Raspberry Pi OS).
* Un ricevitore SDR già configurato (es. con `dump1090-fa` o `readsb`) che trasmette dati sulla porta 30005.

### Installazione rapida
Copia e incolla il seguente comando nel tuo terminale:

```bash
curl -L [https://raw.githubusercontent.com/djrexishere91/Adsb-Italia/main/install.sh](https://raw.githubusercontent.com/djrexishere91/Adsb-Italia/main/install.sh) | sudo bash


🛠️ Comandi Utili
Dopo l'installazione, puoi verificare lo stato dei servizi con questi comandi:

Verificare il feed ADS-B (Dati grezzi):

Bash
sudo systemctl status adsb-italia
Verificare il client MLAT (Triangolazione):

Bash
sudo systemctl status mlat-italia
🔍 Cosa fa lo script?
Dipendenze: Installa socat, python3-dev e i tool di compilazione.

MLAT Client: Scarica e compila il software necessario per calcolare le posizioni senza GPS.

Bridge Dati: Configura un tunnel sicuro verso il server centrale sulla porta 30004 (ADS-B) e 31090 (MLAT).

Persistenza: Configura i servizi affinché si riavviino automaticamente all'accensione del dispositivo.

🤝 Contatti e Supporto
Se riscontri problemi o vuoi unirti alla community, apri una Issue su questa repository.

Grazie per il tuo contributo alla copertura dei cieli italiani! 🇮🇹
