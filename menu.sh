#!/bin/bash

# ================= WARNA =================
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
PURPLE='\033[1;35m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m'

# ================= DEPENDENCY =================
if ! command -v jq >/dev/null 2>&1; then
    apt update -y
    apt install -y jq
fi

# ================= PAUSE FUNCTION =================
pause() {
    echo ""
    read -p "Tekan ENTER untuk kembali ke menu..."
}

# ================= HEADER =================
header() {
clear
echo -e "${PURPLE}${BOLD}"
cat << "EOF"
████████╗ ██████╗  ██████╗ ██╗     ███████╗
╚══██╔══╝██╔═══██╗██╔═══██╗██║     ██╔════╝
   ██║   ██║   ██║██║   ██║██║     ███████╗
   ██║   ██║   ██║██║   ██║██║     ╚════██║
   ██║   ╚██████╔╝╚██████╔╝███████╗███████║
   ╚═╝    ╚═════╝  ╚═════╝ ╚══════╝╚══════╝
EOF
echo -e "${NC}"

echo -e "${CYAN}${BOLD}======================================${NC}"
echo -e "${YELLOW}${BOLD}        PANEL CONTROL MENU${NC}"
echo -e "${CYAN}${BOLD}======================================${NC}"
}

# ================= LOOP MENU =================
while true; do
    header

    echo -e "${GREEN}[1]${NC} Reinstall Panel"
    echo -e "${GREEN}[2]${NC} Uninstall Panel"
    echo -e "${GREEN}[3]${NC} Create Node"
    echo -e "${GREEN}[4]${NC} Start Wings"
    echo -e "${GREEN}[5]${NC} Create Subdomain"
    echo -e "${GREEN}[6]${NC} Cek Subdomain"
    echo ""
    echo -e "${PURPLE}CTRL+C${NC} untuk keluar"
    echo -e "${CYAN}======================================${NC}"

    read -p "Pilih menu [1-6]: " pilih

    case $pilih in
        1)
            bash <(curl -s https://raw.githubusercontent.com/bangrexzy197/tools/main/reinstall.sh)
            pause
            ;;
        2)
            bash <(curl -s https://raw.githubusercontent.com/rexzy223/tools/main/uninstall.sh)
            pause
            ;;
        3)
            bash <(curl -s https://raw.githubusercontent.com/rexzy223/tools/main/wings.sh)
            pause
            ;;
        4)
            bash <(curl -s https://raw.githubusercontent.com/rexzy223/tools/main/swings.sh)
            pause
            ;;
        5)
            bash <(curl -s https://raw.githubusercontent.com/bangrexzy197/tools/main/csubdo.sh)
            pause
            ;;
        6)
            bash <(curl -s https://raw.githubusercontent.com/bangrexzy197/tools/main/ceksubdo.sh)
            pause
            ;;
        *)
            echo -e "${RED}Pilihan tidak valid!${NC}"
            sleep 1
            ;;
    esac
done
