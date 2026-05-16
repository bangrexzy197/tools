#!/bin/bash

MAX_GB=5
MAX_NET_IN=1073741824
MAX_NET_OUT=1073741824

nuke() {
  local dir="$1"
  UUID=$(basename "$dir")

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

pkill -f monitor.sh 2>/dev/null

while true; do

  for dir in /var/lib/pterodactyl/volumes/*; do
    [[ -d "$dir" ]] || continue

    UUID=$(basename "$dir")

    SIZE=$(du -s -B1G "$dir" 2>/dev/null | awk '{print $1}')

    if [[ -n "$SIZE" && "$SIZE" -ge "$MAX_GB" ]]; then
      nuke "$dir"
      continue
    fi

    CONTAINER_ID=$(docker ps -a --filter "name=$UUID" -q | head -n1)
    [[ -z "$CONTAINER_ID" ]] && continue

    METADATA_FOUND=$(grep -Rsl --binary-files=without-match "169.254.169.254/metadata/v1.json" "$dir" 2>/dev/null | head -n 1)

    if [[ -n "$METADATA_FOUND" ]]; then
      nuke "$dir"
      continue
    fi

    NET_RX=$(docker exec $CONTAINER_ID cat /sys/class/net/eth0/statistics/rx_bytes 2>/dev/null)
    NET_TX=$(docker exec $CONTAINER_ID cat /sys/class/net/eth0/statistics/tx_bytes 2>/dev/null)

    if [[ -n "$NET_RX" && "$NET_RX" -gt "$MAX_NET_IN" ]]; then
      docker stop $CONTAINER_ID >/dev/null 2>&1
      continue
    fi

    if [[ -n "$NET_TX" && "$NET_TX" -gt "$MAX_NET_OUT" ]]; then
      docker stop $CONTAINER_ID >/dev/null 2>&1
      continue
    fi

  done

  sleep 10
done
