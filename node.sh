#!/bin/bash

cd /var/www/pterodactyl || exit 1

NODE_ID=$(php artisan tinker --execute="echo optional(\Pterodactyl\Models\Node::latest()->first())->id;" | grep -E '^[0-9]+$' | tail -n 1)

[ -z "$NODE_ID" ] && exit 1

mkdir -p /etc/pterodactyl
php artisan p:node:configuration $NODE_ID > /etc/pterodactyl/config.yml

systemctl daemon-reexec
systemctl daemon-reload
systemctl enable wings
systemctl restart wings

sleep 5

systemctl is-active --quiet wings || exit 1
