#!/bin/bash

set -e

echo "=================================================="
echo "       FIX WINGS + SSL CERTIFICATE"
echo "=================================================="
echo

read -rp "🌐 Masukkan domain node: " DOMAIN

DOMAIN=$(echo "$DOMAIN" | xargs)

if [ -z "$DOMAIN" ]; then
    echo "❌ Domain tidak boleh kosong."
    exit 1
fi

CERT="/etc/letsencrypt/live/$DOMAIN/fullchain.pem"
KEY="/etc/letsencrypt/live/$DOMAIN/privkey.pem"

echo
echo "🌐 Domain : $DOMAIN"

echo
echo "🌐 [1] CEK DNS"

VPS_IP=$(curl -4 -s --max-time 10 https://api.ipify.org)
DOMAIN_IP=$(getent ahostsv4 "$DOMAIN" | awk 'NR==1 {print $1}')

echo "IP VPS    : $VPS_IP"
echo "IP DOMAIN : ${DOMAIN_IP:-TIDAK DITEMUKAN}"

if [ -z "$DOMAIN_IP" ]; then
    echo "❌ Domain tidak bisa di-resolve."
    exit 1
fi

if [ "$VPS_IP" != "$DOMAIN_IP" ]; then
    echo "❌ DNS belum mengarah ke VPS ini."
    echo "Domain : $DOMAIN_IP"
    echo "VPS    : $VPS_IP"
    exit 1
fi

echo "✅ DNS benar."

echo
echo "🛑 [2] STOP WINGS"
systemctl stop wings 2>/dev/null || true

echo
echo "🛑 [3] STOP NGINX SEMENTARA"
systemctl stop nginx 2>/dev/null || true

sleep 2

echo
echo "🔍 [4] CEK PORT 80"

if ss -lntp 2>/dev/null | grep -q ':80 '; then
    echo "❌ Port 80 masih digunakan."
    ss -lntp 2>/dev/null | grep ':80 ' || true
    systemctl start nginx 2>/dev/null || true
    exit 1
fi

echo "✅ Port 80 kosong."

echo
echo "🔐 [5] REQUEST SSL"

if [ -f "$CERT" ] && [ -f "$KEY" ]; then
    echo "✅ Sertifikat sudah ada."
else
    certbot certonly \
        --standalone \
        --non-interactive \
        --agree-tos \
        --register-unsafely-without-email \
        -d "$DOMAIN"
fi

echo
echo "🔎 [6] CEK FILE SSL"

if [ ! -f "$CERT" ] || [ ! -f "$KEY" ]; then
    echo "❌ Sertifikat gagal dibuat."
    systemctl start nginx 2>/dev/null || true
    exit 1
fi

echo "✅ Certificate:"
echo "$CERT"

echo "✅ Private key:"
echo "$KEY"

echo
echo "🌐 [7] START NGINX"

systemctl start nginx 2>/dev/null || true

if systemctl is-active --quiet nginx; then
    echo "✅ Nginx aktif."
else
    echo "⚠️ Nginx tidak aktif."
fi

echo
echo "🦅 [8] START WINGS"

systemctl daemon-reload
systemctl reset-failed wings 2>/dev/null || true
systemctl enable wings
systemctl restart wings

sleep 5

echo
echo "📊 [9] STATUS WINGS"

if systemctl is-active --quiet wings; then
    echo "=================================================="
    echo "🟢 WINGS BERHASIL MENYALA"
    echo "=================================================="
else
    echo "🔴 WINGS MASIH GAGAL"
    echo
    systemctl status wings --no-pager -l

    echo
    echo "📜 LOG:"
    journalctl -u wings -n 50 --no-pager

    exit 1
fi

echo
echo "🔌 [10] PORT WINGS"

ss -lntp 2>/dev/null | grep -E ':8080 |:2022 ' || true

echo
echo "=================================================="
echo "              SELESAI"
echo "=================================================="
echo "🌐 Node : $DOMAIN"
echo "🔐 SSL  : AKTIF"
echo "🦅 Wings: AKTIF"
echo "=================================================="
