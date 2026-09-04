#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Please run this script with sudo: sudo bash update.sh"
  exit 1
fi

CONFIG_DIR="/etc/adsbitalia"
CONFIG_FILE="${CONFIG_DIR}/feeder.conf"

FEED_HOST="feed.adsbitalia.it"
MLAT_HOST="mlat.adsbitalia.it"
FEED_PORT="31108"
MLAT_PORT="41113"
LOCAL_BEAST_PORT_DEFAULT="30005"
MLAT_RETURN_PORT_DEFAULT="33106"
SITE_URL="https://adsbitalia.it"
REGISTER_URL="${SITE_URL}/api/register-feeder"

if [[ -f "$CONFIG_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$CONFIG_FILE"
fi

FEEDER_NAME="${FEEDER_NAME:-}"
LAT="${LAT:-}"
LON="${LON:-}"
ALT="${ALT:-}"
LOCAL_BEAST_PORT="${LOCAL_BEAST_PORT:-$LOCAL_BEAST_PORT_DEFAULT}"
MLAT_RETURN_PORT="${MLAT_RETURN_PORT:-$MLAT_RETURN_PORT_DEFAULT}"
FEEDER_ID="${FEEDER_ID:-}"
FEEDER_TOKEN="${FEEDER_TOKEN:-}"

FEEDER_NAME="$(whiptail --inputbox "Enter feeder name:" 12 60 "$FEEDER_NAME" --title "Update Feeder Configuration" 3>&1 1>&2 2>&3)" || exit 1
FEEDER_NAME="${FEEDER_NAME// /_}"

LAT="$(whiptail --inputbox "Enter latitude (e.g. 44.8040):" 12 60 "$LAT" --title "Coordinates" 3>&1 1>&2 2>&3)" || exit 1
LON="$(whiptail --inputbox "Enter longitude (e.g. 11.9730):" 12 60 "$LON" --title "Coordinates" 3>&1 1>&2 2>&3)" || exit 1
ALT="$(whiptail --inputbox "Enter altitude in meters (e.g. 15):" 12 60 "$ALT" --title "Altitude" 3>&1 1>&2 2>&3)" || exit 1

LOCAL_BEAST_PORT="$(whiptail --inputbox "Enter local Beast OUT port (e.g. 30005):" 12 60 "$LOCAL_BEAST_PORT" --title "Local Beast OUT Port" 3>&1 1>&2 2>&3)" || exit 1
MLAT_RETURN_PORT="$(whiptail --inputbox "Enter local MLAT results return port (e.g. 33106):" 12 60 "$MLAT_RETURN_PORT" --title "MLAT Results Return Port" 3>&1 1>&2 2>&3)" || exit 1

cat > "$CONFIG_FILE" <<EOFCONF
FEEDER_ID=${FEEDER_ID}
FEEDER_TOKEN=${FEEDER_TOKEN}
FEEDER_NAME=${FEEDER_NAME}
LAT=${LAT}
LON=${LON}
ALT=${ALT}
LOCAL_BEAST_PORT=${LOCAL_BEAST_PORT}
FEED_HOST=${FEED_HOST}
MLAT_HOST=${MLAT_HOST}
FEED_PORT=${FEED_PORT}
MLAT_PORT=${MLAT_PORT}
MLAT_RETURN_PORT=${MLAT_RETURN_PORT}
SITE_URL=${SITE_URL}
REGISTER_URL=${REGISTER_URL}
TAR1090_LOCAL_URL=${TAR1090_LOCAL_URL:-}
EOFCONF
chmod 600 "$CONFIG_FILE"

# Re-generate systemd services if present
if [[ -f "/etc/systemd/system/adsbitalia-mlat.service" ]]; then
  sed -i "s|--user .*|--user ${FEEDER_NAME} \\|g" /etc/systemd/system/adsbitalia-mlat.service
  sed -i "s|--lat .*|--lat ${LAT} \\|g" /etc/systemd/system/adsbitalia-mlat.service
  sed -i "s|--lon .*|--lon ${LON} \\|g" /etc/systemd/system/adsbitalia-mlat.service
  sed -i "s|--alt .*|--alt ${ALT} \\|g" /etc/systemd/system/adsbitalia-mlat.service
  sed -i "s|--input-connect 127.0.0.1:.*|--input-connect 127.0.0.1:${LOCAL_BEAST_PORT} \\|g" /etc/systemd/system/adsbitalia-mlat.service
  sed -i "s|--results beast,listen:.*|--results beast,listen,${MLAT_RETURN_PORT}|g" /etc/systemd/system/adsbitalia-mlat.service
  sed -i "s|--results beast,listen,.*|--results beast,listen,${MLAT_RETURN_PORT}|g" /etc/systemd/system/adsbitalia-mlat.service
fi

if [[ -f "/etc/systemd/system/adsbitalia-feed.service" ]]; then
  sed -i "s|TCP:127.0.0.1:[0-9]*|TCP:127.0.0.1:${LOCAL_BEAST_PORT}|g" /etc/systemd/system/adsbitalia-feed.service
fi

systemctl daemon-reload
systemctl restart adsbitalia-feed.service 2>/dev/null || true
systemctl restart adsbitalia-mlat.service 2>/dev/null || true
systemctl start adsbitalia-registration.service 2>/dev/null || true

whiptail --title "Update Completed" --msgbox "ADSBItalia feeder settings updated successfully!

Feeder: ${FEEDER_NAME}
Coordinates: ${LAT}, ${LON} (${ALT}m)
Beast OUT port: ${LOCAL_BEAST_PORT}
MLAT Return port: ${MLAT_RETURN_PORT}

Services have been reloaded and restarted." 16 68
