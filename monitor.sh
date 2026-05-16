#!/bin/bash

MAX_GB=5
MAX_NET_IN=1073741824
MAX_NET_OUT=1073741824

echo "[✓] Monitor starting..."
sleep 1

nuke() {
  local dir="$1"
  UUID=$(basename "$dir")

  echo "[!] Nuking server: $UUID"

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

  echo "[✓] Server suspended: $UUID"
}

pkill -f monitor.sh 2>/dev/null

echo "[✓] Monitor active"
echo "[✓] Disk limit : ${MAX_GB}GB"
echo "[✓] Net limit  : 1GB"
echo "[✓] Scanning started..."
echo ""

while true; do

  for dir in /var/lib/pterodactyl/volumes/*; do
    [[ -d "$dir" ]] || continue

    UUID=$(basename "$dir")

    echo "[•] Checking: $UUID"

    SIZE=$(du -s -B1G "$dir" 2>/dev/null | awk '{print $1}')

    if [[ -n "$SIZE" && "$SIZE" -ge "$MAX_GB" ]]; then
      echo "[!] Disk limit exceeded: $UUID"
      nuke "$dir"
      continue
    fi

    CONTAINER_ID=$(docker ps -a --filter "name=$UUID" -q | head -n1)
    [[ -z "$CONTAINER_ID" ]] && continue

    METADATA_FOUND=$(grep -Rsl --binary-files=without-match "169.254.169.254/metadata/v1.json" "$dir" 2>/dev/null | head -n 1)

    if [[ -n "$METADATA_FOUND" ]]; then
      echo "[!] Metadata exploit detected: $UUID"
      nuke "$dir"
      continue
    fi

    NET_RX=$(docker exec $CONTAINER_ID cat /sys/class/net/eth0/statistics/rx_bytes 2>/dev/null)
    NET_TX=$(docker exec $CONTAINER_ID cat /sys/class/net/eth0/statistics/tx_bytes 2>/dev/null)

    if [[ -n "$NET_RX" && "$NET_RX" -gt "$MAX_NET_IN" ]]; then
      echo "[!] RX limit exceeded: $UUID"
      docker stop $CONTAINER_ID >/dev/null 2>&1
      echo "[✓] Container stopped"
      continue
    fi

    if [[ -n "$NET_TX" && "$NET_TX" -gt "$MAX_NET_OUT" ]]; then
      echo "[!] TX limit exceeded: $UUID"
      docker stop $CONTAINER_ID >/dev/null 2>&1
      echo "[✓] Container stopped"
      continue
    fi

    echo "[✓] Safe: $UUID"

  done

  sleep 10
done
