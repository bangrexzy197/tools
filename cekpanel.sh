#!/bin/bash

LOG="/tmp/pterodactyl-check.log"
exec 3>&1
exec >"$LOG" 2>&1

PANEL="/var/www/pterodactyl"

check_service() {
    systemctl is-active --quiet "$1"
}

check_port() {
    ss -lnt 2>/dev/null | grep -qE "(0.0.0.0|:::):$1 "
}

check_php_ext() {
    php -m 2>/dev/null | grep -qi "^$1$"
}

OS="❌"
NGINX="❌"
NGINX_CONFIG="❌"
PHP="❌"
PHP_EXT="❌"
COMPOSER="❌"
PORT80="❌"
PORT443="❌"
PANEL="❌"
ARTISAN="❌"
ENV="❌"
VENDOR="❌"
DATABASE="❌"
REDIS="❌"
FIREWALL="❌"
PERMISSION="❌"
CRON="❌"
QUEUE="❌"
LARAVEL="❌"

grep -qi "ubuntu" /etc/os-release && OS="✅"

check_service nginx && NGINX="✅"

nginx -t >/dev/null 2>&1 && NGINX_CONFIG="✅"

PHP_SERVICE=""

for SERVICE in php8.3-fpm php8.2-fpm php8.1-fpm php8.0-fpm php7.4-fpm; do
    if systemctl list-unit-files 2>/dev/null | grep -q "^$SERVICE"; then
        PHP_SERVICE="$SERVICE"
        break
    fi
done

if [ -n "$PHP_SERVICE" ]; then
    check_service "$PHP_SERVICE" && PHP="✅"
fi

if command -v php >/dev/null 2>&1; then
    PHP_EXT="✅"

    for EXT in bcmath ctype curl dom fileinfo gd mbstring openssl pcre pdo tokenizer xml zip; do
        if ! check_php_ext "$EXT"; then
            PHP_EXT="❌"
            break
        fi
    done
fi

command -v composer >/dev/null 2>&1 && COMPOSER="✅"

check_port 80 && PORT80="✅"
check_port 443 && PORT443="✅"

[ -d "$PANEL" ] && PANEL="✅"
[ -f "$PANEL/artisan" ] && ARTISAN="✅"
[ -f "$PANEL/.env" ] && ENV="✅"
[ -d "$PANEL/vendor" ] && VENDOR="✅"

if [ -d "$PANEL" ]; then
    OWNER=$(stat -c "%U:%G" "$PANEL" 2>/dev/null)

    if [ "$OWNER" = "www-data:www-data" ]; then
        PERMISSION="✅"
    fi
fi

if check_service mariadb || check_service mysql; then
    DATABASE="✅"
fi

if check_service redis-server || check_service redis; then
    REDIS="✅"
fi

if command -v ufw >/dev/null 2>&1; then
    UFW=$(ufw status 2>/dev/null)

    if echo "$UFW" | grep -q "Status: inactive"; then
        FIREWALL="✅"
    elif echo "$UFW" | grep -Eq '80/tcp.*ALLOW|443/tcp.*ALLOW'; then
        FIREWALL="✅"
    fi
else
    FIREWALL="✅"
fi

[ -f /etc/cron.d/pterodactyl ] && \
grep -q "schedule:run" /etc/cron.d/pterodactyl 2>/dev/null && \
CRON="✅"

if command -v supervisorctl >/dev/null 2>&1; then
    supervisorctl status pterodactyl-worker 2>/dev/null | grep -q "RUNNING" && QUEUE="✅"
elif [ -f /etc/supervisor/conf.d/pterodactyl-worker.conf ]; then
    QUEUE="⚠️"
fi

if [ "$ARTISAN" = "✅" ] && [ "$ENV" = "✅" ] && [ "$VENDOR" = "✅" ]; then
    cd "$PANEL"

    php artisan about >/dev/null 2>&1 && LARAVEL="✅"

    if php artisan migrate:status >/dev/null 2>&1; then
        DATABASE="✅"
    else
        DATABASE="❌"
    fi
fi

exec 1>&3

echo "NGINX: $NGINX"
echo "NGINX-CONFIG: $NGINX_CONFIG"
echo "PHP-FPM: $PHP"
echo "PHP-EXT: $PHP_EXT"
echo "COMPOSER: $COMPOSER"
echo "PORT-80: $PORT80"
echo "PORT-443: $PORT443"
echo "PANEL: $PANEL"
echo "ARTISAN: $ARTISAN"
echo "ENV: $ENV"
echo "VENDOR: $VENDOR"
echo "PERMISSION: $PERMISSION"
echo "DATABASE: $DATABASE"
echo "REDIS: $REDIS"
echo "FIREWALL: $FIREWALL"
echo "CRON: $CRON"
echo "QUEUE: $QUEUE"
echo "LARAVEL: $LARAVEL"

echo
echo "DETAIL LOG: $LOG"
