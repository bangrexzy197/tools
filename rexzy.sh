#!/bin/bash

MAX_GB=5
MAX_NET_IN=1073741824
MAX_NET_OUT=1073741824

declare -A WARNINGS

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${GREEN}════════════════════════════════════════${NC}"
echo -e "${GREEN}   🛡️  MONITOR ACTIVE - PROTECTION ON  🛡️${NC}"
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo -e "${CYAN}📊 DISK LIMIT: ${MAX_GB}GB${NC}"
echo -e "${CYAN}📊 INBOUND:   1GB${NC}"
echo -e "${CYAN}📊 OUTBOUND:  1GB${NC}"
echo -e "${GREEN}✅ MONITOR RUNNING${NC}"
echo -e "${YELLOW}⚠️  Warnings will appear in container console${NC}"
echo -e "${RED}🔴 Suspensions will be shown in RED${NC}"
echo -e "${GREEN}════════════════════════════════════════${NC}"

send_console() {
  local CONTAINER_ID="$1"
  local MESSAGE="$2"
  local COLOR="$3"
  
  docker exec "$CONTAINER_ID" sh -c "
    echo '${COLOR}${BOLD}[MONITOR] ${MESSAGE}${NC}' > /dev/console 2>/dev/null
    echo '[MONITOR] $MESSAGE' >> /var/log/monitor.log 2>/dev/null
  " 2>/dev/null
}

nuke() {
  local dir="$1"
  local CONTAINER_ID="$2"
  local REASON="$3"

  UUID=$(basename "$dir")

  send_console "$CONTAINER_ID" "‼  Kamu telah melanggar aturan $REASON" "$RED"
  send_console "$CONTAINER_ID" "‼  Server kamu akan di SUSPEND PERMANEN!" "$RED"

  docker ps -a --format '{{.ID}} {{.Names}}' | while read CID NAME; do
    if echo "$NAME" | grep -q "$UUID"; then
      docker kill "$CID" >/dev/null 2>&1
      docker rm -f "$CID" >/dev/null 2>&1
    fi
  done

  mysql -u root -D panel -e "
    UPDATE servers
    SET status='suspended'
    WHERE uuid='$UUID' OR uuidShort='$UUID';
  " 2>/dev/null

  find "$dir" -mindepth 1 -delete 2>/dev/null
}

warn_user() {
  local UUID="$1"
  local CONTAINER_ID="$2"
  local VIOLATION="$3"

  WARNINGS[$UUID]=$(( ${WARNINGS[$UUID]:-0} + 1 ))
  COUNT=${WARNINGS[$UUID]}

  send_console "$CONTAINER_ID" "🚫 Terdeteksi menjalankan $VIOLATION: WARNING ($COUNT/3)" "$YELLOW"

  if [[ "$COUNT" -ge 3 ]]; then
    send_console "$CONTAINER_ID" "‼  Kamu telah menjalankan $VIOLATION sebanyak 3x" "$RED"
    nuke "/var/lib/pterodactyl/volumes/$UUID" "$CONTAINER_ID" "$VIOLATION"
    WARNINGS[$UUID]=0
  fi
}

instant_suspend() {
  local UUID="$1"
  local CONTAINER_ID="$2"
  local VIOLATION="$3"

  send_console "$CONTAINER_ID" "🚫 Terdeteksi $VIOLATION" "$RED"
  send_console "$CONTAINER_ID" "‼  Server kamu akan di SUSPEND PERMANEN!" "$RED"

  nuke "/var/lib/pterodactyl/volumes/$UUID" "$CONTAINER_ID" "$VIOLATION"
}

while true; do

  for dir in /var/lib/pterodactyl/volumes/*; do
    [[ -d "$dir" ]] || continue

    UUID=$(basename "$dir")

    CONTAINER_ID=$(docker ps -a --filter "name=$UUID" -q | head -n1)
    [[ -z "$CONTAINER_ID" ]] && continue

    SIZE=$(du -s -B1G "$dir" 2>/dev/null | awk '{print $1}')

    if [[ -n "$SIZE" && "$SIZE" -ge "$MAX_GB" ]]; then
      instant_suspend "$UUID" "$CONTAINER_ID" "KILL DISK PANEL"
      continue
    fi

    METADATA_FOUND=$(grep -Rsl --binary-files=without-match "169.254.169.254/metadata/v1.json" "$dir" 2>/dev/null | head -n1)

    if [[ -n "$METADATA_FOUND" ]]; then
      warn_user "$UUID" "$CONTAINER_ID" "SCRIPT METADATA"
      continue
    fi

    NET_RX=$(docker exec $CONTAINER_ID cat /sys/class/net/eth0/statistics/rx_bytes 2>/dev/null)
    NET_TX=$(docker exec $CONTAINER_ID cat /sys/class/net/eth0/statistics/tx_bytes 2>/dev/null)

    if [[ -n "$NET_RX" && "$NET_RX" -gt "$MAX_NET_IN" ]]; then
      warn_user "$UUID" "$CONTAINER_ID" "NETWORK ABUSE (INBOUND)"
      continue
    fi

    if [[ -n "$NET_TX" && "$NET_TX" -gt "$MAX_NET_OUT" ]]; then
      warn_user "$UUID" "$CONTAINER_ID" "NETWORK ABUSE (OUTBOUND)"
      continue
    fi

  done

  sleep 10
done
