#!/bin/bash
set -e

# ================= WARNA =================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

clear
echo -e "${CYAN}=======================================${NC}"
echo -e "${GREEN}         AUTO REINSTALL PANEL${NC}"
echo -e "${CYAN}=======================================${NC}"
echo ""

# ================= INPUT =================
read -p "Masukkan DOMAIN BARU: " DOMAIN

# ================= CLEAN DOMAIN =================
DOMAIN=$(echo "$DOMAIN" | sed 's|https\?://||g' | sed 's|/||g')

PANEL_DIR="/var/www/pterodactyl"
ENV_FILE="$PANEL_DIR/.env"
NGINX_CONF="/etc/nginx/sites-available/pterodactyl.conf"
NGINX_ENABLED="/etc/nginx/sites-enabled/pterodactyl.conf"

# ================= VPS IP =================
VPS_IP=$(curl -s ifconfig.me)

echo -e "${BLUE}🌍 VPS IP terdeteksi: ${NC}${VPS_IP}"

# ================= CHECK DOMAIN DNS =================
DOMAIN_IP=$(dig +short A "$DOMAIN" | head -n 1)

echo -e "${BLUE}🔎 DNS domain mengarah ke: ${NC}${DOMAIN_IP}"

if [ -z "$DOMAIN_IP" ]; then
  echo -e "${RED}❌ ERROR: Domain tidak memiliki A record${NC}"
  exit 1
fi

if [ "$DOMAIN_IP" != "$VPS_IP" ]; then
  echo ""
  echo -e "${RED}❌ DOMAIN BELUM MENGARAH KE VPS!${NC}"
  echo -e "${YELLOW}👉 Harusnya: ${VPS_IP}${NC}"
  echo -e "${YELLOW}👉 Saat ini:  ${DOMAIN_IP}${NC}"
  echo ""
  echo -e "${RED}STOP INSTALL (DNS belum propagasi)${NC}"
  exit 1
fi

echo -e "${GREEN}✅ DOMAIN SUDAH MENGARAH KE VPS${NC}"
echo ""

# ================= AUTO DETECT OLD DOMAIN =================
OLD_DOMAIN=$(grep -E "^APP_URL=" "$ENV_FILE" 2>/dev/null | cut -d '=' -f2 | sed 's|https\?://||g' | sed 's|/||g' || true)

if [ -z "$OLD_DOMAIN" ]; then
  OLD_DOMAIN=$(grep -R "server_name" /etc/nginx/sites-enabled/ 2>/dev/null | head -n 1 | awk '{print $2}' | sed 's/;//g')
fi

echo -e "${YELLOW}🔎 OLD DOMAIN terdeteksi: ${NC}${OLD_DOMAIN}"
echo ""

echo -e "${BLUE}🚀 Memproses...${NC}"
sleep 1

# ================= BACKUP =================
cp $ENV_FILE ${ENV_FILE}.bak 2>/dev/null || true
cp $NGINX_CONF ${NGINX_CONF}.bak 2>/dev/null || true

# ================= VALIDASI =================
if [ ! -f "$ENV_FILE" ]; then
  echo -e "${RED}❌ ERROR: .env tidak ditemukan${NC}"
  exit 1
fi

# ================= UPDATE ENV =================
echo -e "${BLUE}⚙️ Update ENV...${NC}"
sed -i "s|APP_URL=.*|APP_URL=https://${DOMAIN}|g" "$ENV_FILE"

grep -q "SESSION_DRIVER" "$ENV_FILE" \
  && sed -i "s|SESSION_DRIVER=.*|SESSION_DRIVER=file|g" "$ENV_FILE" \
  || echo "SESSION_DRIVER=file" >> "$ENV_FILE"

grep -q "SESSION_SECURE_COOKIE" "$ENV_FILE" \
  && sed -i "s|SESSION_SECURE_COOKIE=.*|SESSION_SECURE_COOKIE=true|g" "$ENV_FILE" \
  || echo "SESSION_SECURE_COOKIE=true" >> "$ENV_FILE"

# ================= CACHE =================
echo -e "${BLUE}🧹 Clear cache...${NC}"
cd "$PANEL_DIR"
php artisan optimize:clear

# ================= PERMISSION =================
echo -e "${BLUE}🔐 Fix permission...${NC}"
chown -R www-data:www-data $PANEL_DIR
chmod -R 755 $PANEL_DIR/storage
chmod -R 755 $PANEL_DIR/bootstrap/cache

# ================= PHP =================
echo -e "${BLUE}🔍 Deteksi PHP...${NC}"
PHP_SOCK=$(ls /run/php/ | grep fpm.sock | head -n 1)

if [ -z "$PHP_SOCK" ]; then
  echo -e "${RED}❌ ERROR: php-fpm socket tidak ditemukan${NC}"
  exit 1
fi

# ================= NGINX =================
echo -e "${BLUE}🌐 Konfigurasi NGINX...${NC}"
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
echo -e "${GREEN}🔒 Install SSL...${NC}"
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

# ================= OUTPUT =================
echo ""
echo -e "${CYAN}=======================================${NC}"
echo -e "${GREEN}✅ REINSTALL SUCCESS!${NC}"
echo -e "${CYAN}=======================================${NC}"
echo -e "${GREEN}🌐 URL: https://${DOMAIN}${NC}"
echo -e "${YELLOW}🔁 OLD: ${OLD_DOMAIN}${NC}"
echo -e "${CYAN}=======================================${NC}"
