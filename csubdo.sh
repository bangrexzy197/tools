#!/bin/bash

CF_API_TOKEN="cfut_Ik5XO3g6ELZdnnUAh8VG4rwbXLIrOnoQG0wg0HEC6eb86645"
ZONE_ID="fb9b0bde2e5bbf5e819ce0ccfa8f9a1d"
DOMAIN="rexzystr.my.id"

SUB="${1}"
IP="${2}"

if [[ -z "$SUB" ]]; then
  read -p "📌 Masukkan subdomain: " SUB
fi

if [[ -z "$IP" ]]; then
  read -p "🌐 Masukkan IP tujuan: " IP
fi

if [[ -z "$CF_API_TOKEN" || -z "$ZONE_ID" || -z "$DOMAIN" ]]; then
  echo "❌ ERROR: set CF_API_TOKEN, ZONE_ID, DOMAIN"
  exit 1
fi

FULL_DOMAIN="${SUB}.${DOMAIN}"

echo "🚀 Membuat subdomain: $FULL_DOMAIN -> $IP"

RESPONSE=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records" \
  -H "Authorization: Bearer ${CF_API_TOKEN}" \
  -H "Content-Type: application/json" \
  --data "{
    \"type\":\"A\",
    \"name\":\"${FULL_DOMAIN}\",
    \"content\":\"${IP}\",
    \"ttl\":120,
    \"proxied\":false
  }")

if echo "$RESPONSE" | grep -q '"success":true'; then
  echo "✅ SUCCESS: $FULL_DOMAIN berhasil dibuat"
else
  echo "❌ FAILED:"
  echo "$RESPONSE"
fi
