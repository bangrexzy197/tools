#!/bin/bash

CF_API_TOKEN="${CF_API_TOKEN}"
ZONE_ID="${ZONE_ID}"
DOMAIN="${DOMAIN}"

SUB="${1}"

if [[ -z "$SUB" ]]; then
  read -p "📌 Masukkan subdomain: " SUB
fi

if [[ -z "$CF_API_TOKEN" || -z "$ZONE_ID" || -z "$DOMAIN" ]]; then
  echo "❌ ERROR: set CF_API_TOKEN, ZONE_ID, DOMAIN"
  exit 1
fi

FULL_DOMAIN="${SUB}.${DOMAIN}"

echo "🔎 Mengecek domain: $FULL_DOMAIN"

RESPONSE=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records?type=A&name=${FULL_DOMAIN}" \
  -H "Authorization: Bearer ${CF_API_TOKEN}" \
  -H "Content-Type: application/json")

COUNT=$(echo "$RESPONSE" | grep -o '"count":[0-9]*' | cut -d':' -f2)

if [[ "$COUNT" -gt 0 ]]; then
  IP=$(echo "$RESPONSE" | grep -o '"content":"[^"]*"' | head -n1 | cut -d':' -f2 | tr -d '"')
  echo "✅ EXISTS: $FULL_DOMAIN"
  echo "🌐 IP: $IP"
else
  echo "❌ NOT FOUND: $FULL_DOMAIN"
fi
