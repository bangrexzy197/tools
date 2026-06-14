#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

clear
echo -e "${CYAN}${BOLD}=======================================${NC}"
echo -e "${MAGENTA}${BOLD}       AUTO REINSTALL PANEL 🚀${NC}"
echo -e "${CYAN}${BOLD}=======================================${NC}"
echo ""

# ================= INPUT =================
echo -e "${YELLOW}📝 Masukkan DOMAIN BARU:${NC}"
read -p "➡️  " DOMAIN

# ================= CLEAN DOMAIN =================
DOMAIN=$(echo "$DOMAIN" | sed 's|https\?://||g' | sed 's|/||g')

PANEL_DIR="/var/www/pterodactyl"
ENV_FILE="$PANEL_DIR/.env"
NGINX_CONF="/etc/nginx/sites-available/pterodactyl.conf"
NGINX_ENABLED="/etc/nginx/sites-enabled/pterodactyl.conf"

# ================= AUTO DETECT OLD DOMAIN =================
OLD_DOMAIN=$(grep -E "^APP_URL=" "$ENV_FILE" 2>/dev/null | cut -d '=' -f2 | sed 's|https\?://||g' | sed 's|/||g' || true)

if [ -z "$OLD_DOMAIN" ]; then
  OLD_DOMAIN=$(grep -R "server_name" /etc/nginx/sites-enabled/ 2>/dev/null | head -n 1 | awk '{print $2}' | sed 's/;//g')
fi

echo -e "${CYAN}🔎 OLD DOMAIN terdeteksi: ${YELLOW}$OLD_DOMAIN${NC}"
echo ""

echo -e "${GREEN}🚀 Memproses...${NC}"
sleep 1

# ================= BACKUP =================
echo -e "${YELLOW}📦 Membuat backup...${NC}"
cp $ENV_FILE ${ENV_FILE}.bak 2>/dev/null || true
cp $NGINX_CONF ${NGINX_CONF}.bak 2>/dev/null || true
echo -e "${GREEN}✅ Backup selesai${NC}"

# ================= VALIDASI =================
if [ ! -f "$ENV_FILE" ]; then
  echo -e "${RED}❌ ERROR: .env tidak ditemukan${NC}"
  exit 1
fi

# ================= UPDATE ENV =================
echo -e "${YELLOW}⚙️ Update ENV...${NC}"
sed -i "s|APP_URL=.*|APP_URL=https://${DOMAIN}|g" "$ENV_FILE"

grep -q "SESSION_DRIVER" "$ENV_FILE" \
  && sed -i "s|SESSION_DRIVER=.*|SESSION_DRIVER=file|g" "$ENV_FILE" \
  || echo "SESSION_DRIVER=file" >> "$ENV_FILE"

grep -q "SESSION_SECURE_COOKIE" "$ENV_FILE" \
  && sed -i "s|SESSION_SECURE_COOKIE=.*|SESSION_SECURE_COOKIE=true|g" "$ENV_FILE" \
  || echo "SESSION_SECURE_COOKIE=true" >> "$ENV_FILE"
echo -e "${GREEN}✅ ENV updated${NC}"

# ================= CLEAR CACHE =================
echo -e "${YELLOW}🧹 Clear cache...${NC}"
cd "$PANEL_DIR"
php artisan optimize:clear > /dev/null 2>&1
echo -e "${GREEN}✅ Cache cleared${NC}"

# ================= PERMISSION =================
echo -e "${YELLOW}🔐 Fix permission...${NC}"
chown -R www-data:www-data $PANEL_DIR
chmod -R 755 $PANEL_DIR/storage
chmod -R 755 $PANEL_DIR/bootstrap/cache
echo -e "${GREEN}✅ Permission fixed${NC}"

# ================= DETEKSI PHP =================
echo -e "${YELLOW}🔍 Deteksi PHP...${NC}"
PHP_SOCK=$(ls /run/php/ | grep fpm.sock | head -n 1)

if [ -z "$PHP_SOCK" ]; then
  echo -e "${RED}❌ ERROR: php-fpm socket tidak ditemukan${NC}"
  exit 1
fi
echo -e "${GREEN}✅ PHP socket: $PHP_SOCK${NC}"

# ================= NGINX CONFIG =================
echo -e "${YELLOW}🌐 Konfigurasi NGINX...${NC}"
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

nginx -t > /dev/null 2>&1
systemctl restart nginx
echo -e "${GREEN}✅ Nginx configured${NC}"

# ================= SSL =================
echo -e "${YELLOW}🔒 Install SSL...${NC}"
apt update -y > /dev/null 2>&1
apt install certbot python3-certbot-nginx -y > /dev/null 2>&1

certbot --nginx -d ${DOMAIN} \
  --non-interactive \
  --agree-tos \
  -m admin@${DOMAIN} \
  --redirect > /dev/null 2>&1
echo -e "${GREEN}✅ SSL installed${NC}"

# ================= RESTART =================
systemctl restart nginx
systemctl restart php* > /dev/null 2>&1 || true

# ================= WINGS CONFIG =================
echo -e "${YELLOW}⚙️ Konfigurasi Wings...${NC}"

cd /var/www/pterodactyl || exit 1

NODE_ID=$(php artisan tinker --execute="echo optional(\Pterodactyl\Models\Node::latest()->first())->id;" | grep -E '^[0-9]+$' | tail -n 1)

if [ -z "$NODE_ID" ]; then
    echo -e "${RED}❌ Gagal mendapatkan Node ID, skip Wings config${NC}"
else
    echo -e "${GREEN}✅ Node ID terdeteksi: $NODE_ID${NC}"
    mkdir -p /etc/pterodactyl
    php artisan p:node:configuration $NODE_ID > /etc/pterodactyl/config.yml

    systemctl daemon-reexec
    systemctl daemon-reload
    systemctl enable wings > /dev/null 2>&1
    systemctl restart wings

    sleep 5

    if systemctl is-active --quiet wings; then
        echo -e "${GREEN}✅ Wings berhasil dikonfigurasi dan ONLINE!${NC}"
    else
        echo -e "${RED}⚠️ Wings gagal start, cek manual dengan: systemctl status wings${NC}"
    fi
fi

echo ""
echo -e "${CYAN}${BOLD}=======================================${NC}"
echo -e "${GREEN}${BOLD}✅ REINSTALL SUCCESS!${NC}"
echo -e "${CYAN}${BOLD}=======================================${NC}"
echo -e "${CYAN}🌐 URL: ${GREEN}https://${DOMAIN}${NC}"
echo -e "${CYAN}🔁 OLD: ${YELLOW}${OLD_DOMAIN}${NC}"
echo -e "${CYAN}${BOLD}=======================================${NC}"
