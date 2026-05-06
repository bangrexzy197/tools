#!/bin/bash
set -e

# ================= COLOR =================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m'

clear
echo -e "${CYAN}=======================================${NC}"
echo -e "${MAGENTA}         AUTO REINSTALL PANEL ${NC}"
echo -e "${CYAN}=======================================${NC}"
echo ""

# ================= INPUT =================
echo -e "${YELLOW}➤ Masukkan DOMAIN BARU:${NC}"
read DOMAIN

# ================= CLEAN DOMAIN =================
DOMAIN=$(echo "$DOMAIN" | sed 's|https\?://||g' | sed 's|/||g')

PANEL_DIR="/var/www/pterodactyl"
ENV_FILE="$PANEL_DIR/.env"
NGINX_CONF="/etc/nginx/sites-available/pterodactyl.conf"
NGINX_ENABLED="/etc/nginx/sites-enabled/pterodactyl.conf"

# ================= AUTO DETECT OLD DOMAIN =================
OLD_DOMAIN=$(grep -E "^APP_URL=" "$ENV_FILE" 2>/dev/null | cut -d '=' -f2 | sed 's|https\?://||g' | sed 's|/||g' || true)

if [ -z "$OLD_DOMAIN" ]; then
  OLD_DOMAIN=$(grep -R "server_name" /etc/nginx/sites-enabled/ 2>/dev/null | grep -v "$DOMAIN" | head -n 1 | awk '{print $2}' | sed 's/;//g')
fi

if [ -z "$OLD_DOMAIN" ] || [ "$OLD_DOMAIN" = "$DOMAIN" ]; then
  OLD_DOMAIN=""
fi

echo -e "${BLUE}🔎 OLD DOMAIN:${NC} ${WHITE}${OLD_DOMAIN:-NONE}${NC}"
echo ""

echo -e "${CYAN}🚀 Memproses...${NC}"
sleep 1

# ================= BACKUP =================
echo -e "${YELLOW}📦 Backup config...${NC}"
cp "$ENV_FILE" "${ENV_FILE}.bak" 2>/dev/null || true
cp "$NGINX_CONF" "${NGINX_CONF}.bak" 2>/dev/null || true

# ================= VALIDASI =================
if [ ! -f "$ENV_FILE" ]; then
  echo -e "${RED}❌ ERROR: .env tidak ditemukan${NC}"
  exit 1
fi

# ================= UPDATE ENV =================
echo -e "${CYAN}⚙️ Update ENV...${NC}"
sed -i "s|APP_URL=.*|APP_URL=https://${DOMAIN}|g" "$ENV_FILE"

grep -q "SESSION_DRIVER" "$ENV_FILE" \
  && sed -i "s|SESSION_DRIVER=.*|SESSION_DRIVER=file|g" "$ENV_FILE" \
  || echo "SESSION_DRIVER=file" >> "$ENV_FILE"

grep -q "SESSION_SECURE_COOKIE" "$ENV_FILE" \
  && sed -i "s|SESSION_SECURE_COOKIE=.*|SESSION_SECURE_COOKIE=true|g" "$ENV_FILE" \
  || echo "SESSION_SECURE_COOKIE=true" >> "$ENV_FILE"

# ================= CLEAR CACHE =================
echo -e "${MAGENTA}🧹 Clear cache...${NC}"
cd "$PANEL_DIR"
php artisan optimize:clear

# ================= PERMISSION =================
echo -e "${YELLOW}🔐 Fix permission...${NC}"
chown -R www-data:www-data "$PANEL_DIR"
chmod -R 755 "$PANEL_DIR/storage"
chmod -R 755 "$PANEL_DIR/bootstrap/cache"

# ================= DETEKSI PHP =================
echo -e "${CYAN}🔍 Deteksi PHP...${NC}"
PHP_SOCK=$(find /run/php -type s -name "*fpm.sock" | head -n 1)

if [ -z "$PHP_SOCK" ]; then
  echo -e "${RED}❌ ERROR: php-fpm socket tidak ditemukan${NC}"
  exit 1
fi

# ================= NGINX CONFIG =================
echo -e "${BLUE}🌐 Konfigurasi NGINX...${NC}"

if [ -n "$OLD_DOMAIN" ]; then
cat > "$NGINX_CONF" <<EOF
server {
    listen 80;
    server_name ${DOMAIN};

    root ${PANEL_DIR}/public;
    index index.php index.html;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:${PHP_SOCK};
    }
}

server {
    listen 80;
    server_name ${OLD_DOMAIN};
    return 444;
}
EOF
else
cat > "$NGINX_CONF" <<EOF
server {
    listen 80;
    server_name ${DOMAIN};

    root ${PANEL_DIR}/public;
    index index.php index.html;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:${PHP_SOCK};
    }
}
EOF
fi

ln -sf "$NGINX_CONF" "$NGINX_ENABLED"
rm -f /etc/nginx/sites-enabled/default

echo -e "${CYAN}🧪 Test config nginx...${NC}"
nginx -t
systemctl restart nginx

# ================= SSL =================
echo -e "${MAGENTA}🔒 Install SSL...${NC}"
apt update -y
apt install certbot python3-certbot-nginx -y

certbot --nginx -d "${DOMAIN}" \
  --non-interactive \
  --agree-tos \
  -m admin@"${DOMAIN}" \
  --redirect

# ================= RESTART =================
echo -e "${YELLOW}🔄 Restart service...${NC}"
systemctl restart nginx
systemctl restart php* || true

# ================= AUTO RESTART WINGS =================
echo -e "${CYAN}🪽 Restart Wings...${NC}"
if systemctl list-unit-files | grep -q "^wings.service"; then
  systemctl restart wings
  echo -e "${GREEN}✅ Wings berhasil direstart${NC}"
else
  echo -e "${YELLOW}⚠️ Wings tidak ditemukan${NC}"
fi

echo ""
echo -e "${GREEN}=======================================${NC}"
echo -e "${GREEN}✅ REINSTALL SUCCESS!${NC}"
echo -e "${GREEN}=======================================${NC}"
echo -e "${CYAN}🌐 URL:${NC} ${WHITE}https://${DOMAIN}${NC}"
echo -e "${YELLOW}🔁 OLD:${NC} ${WHITE}${OLD_DOMAIN:-NONE}${NC}"
echo -e "${GREEN}=======================================${NC}"
