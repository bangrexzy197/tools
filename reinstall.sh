#!/bin/bash
set -e

clear
echo "======================================="
echo "         AUTO REINSTALL PANEL "
echo "======================================="
echo ""

# ================= INPUT =================
read -p "Masukkan DOMAIN BARU: " DOMAIN

# ================= CLEAN DOMAIN =================
DOMAIN=$(echo "$DOMAIN" | sed 's|https\?://||g' | sed 's|/||g')

PANEL_DIR="/var/www/pterodactyl"
ENV_FILE="$PANEL_DIR/.env"
NGINX_CONF="/etc/nginx/sites-available/pterodactyl.conf"
NGINX_ENABLED="/etc/nginx/sites-enabled/pterodactyl.conf"

# ================= AUTO DETECT OLD DOMAIN =================
OLD_DOMAIN=$(grep -E "^APP_URL=" "$ENV_FILE" 2>/dev/null | cut -d '=' -f2 | sed 's|https\?://||g' | sed 's|/||g' || true)

# fallback dari nginx kalau env kosong
if [ -z "$OLD_DOMAIN" ]; then
  OLD_DOMAIN=$(grep -R "server_name" /etc/nginx/sites-enabled/ 2>/dev/null | head -n 1 | awk '{print $2}' | sed 's/;//g')
fi

echo "🔎 OLD DOMAIN terdeteksi: $OLD_DOMAIN"
echo ""

echo "🚀 Memproses..."
sleep 1

# ================= BACKUP =================
cp $ENV_FILE ${ENV_FILE}.bak 2>/dev/null || true
cp $NGINX_CONF ${NGINX_CONF}.bak 2>/dev/null || true

# ================= VALIDASI =================
if [ ! -f "$ENV_FILE" ]; then
  echo "❌ ERROR: .env tidak ditemukan"
  exit 1
fi

# ================= UPDATE ENV =================
echo "⚙️ Update ENV..."
sed -i "s|APP_URL=.*|APP_URL=https://${DOMAIN}|g" "$ENV_FILE"

grep -q "SESSION_DRIVER" "$ENV_FILE" \
  && sed -i "s|SESSION_DRIVER=.*|SESSION_DRIVER=file|g" "$ENV_FILE" \
  || echo "SESSION_DRIVER=file" >> "$ENV_FILE"

grep -q "SESSION_SECURE_COOKIE" "$ENV_FILE" \
  && sed -i "s|SESSION_SECURE_COOKIE=.*|SESSION_SECURE_COOKIE=true|g" "$ENV_FILE" \
  || echo "SESSION_SECURE_COOKIE=true" >> "$ENV_FILE"

# ================= CLEAR CACHE =================
echo "🧹 Clear cache..."
cd "$PANEL_DIR"
php artisan optimize:clear

# ================= PERMISSION =================
echo "🔐 Fix permission..."
chown -R www-data:www-data $PANEL_DIR
chmod -R 755 $PANEL_DIR/storage
chmod -R 755 $PANEL_DIR/bootstrap/cache

# ================= DETEKSI PHP =================
echo "🔍 Deteksi PHP..."
PHP_SOCK=$(ls /run/php/ | grep fpm.sock | head -n 1)

if [ -z "$PHP_SOCK" ]; then
  echo "❌ ERROR: php-fpm socket tidak ditemukan"
  exit 1
fi

# ================= NGINX CONFIG =================
echo "🌐 Konfigurasi NGINX..."
cat > $NGINX_CONF <<EOF
server {
    listen 80;
    server_name ${DOMAIN};

    root $PANEL_DIR/public;
    index index.php index.html;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/${PHP_SOCK};
    }
}

server {
    listen 80;
    server_name ${OLD_DOMAIN};
    return 444;
}
EOF

ln -sf $NGINX_CONF $NGINX_ENABLED
rm -f /etc/nginx/sites-enabled/default

nginx -t
systemctl restart nginx

# ================= SSL =================
echo "🔒 Install SSL..."
apt update -y
apt install certbot python3-certbot-nginx -y

certbot --nginx -d ${DOMAIN} \
  --non-interactive \
  --agree-tos \
  -m admin@${DOMAIN} \
  --redirect

# ================= RESTART =================
systemctl restart nginx
systemctl restart php* || true

echo ""
echo "======================================="
echo "✅ REINSTALL SUCCESS!"
echo "======================================="
echo "🌐 URL: https://${DOMAIN}"
echo "🔁 OLD: ${OLD_DOMAIN}"
echo "======================================="
