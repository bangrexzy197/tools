#!/data/data/com.termux/files/usr/bin/bash
# =============================================================================
# OVARIUM V3 - LEVIATHAN EDITION (TERMUX OPTIMIZED - VERTICAL MODE)
# =============================================================================
# CREATED BY: XENON, WOLF, JOHAN, VIN, ZEYNA, ABUN, SINO
# EDITED: AUTO DETECT SMTP PROVIDER & SPECIAL CHARACTERS SUPPORT
# =============================================================================

# =============================================================================
# KONFIGURASI WARNA - BIRU DOMINAN
# =============================================================================
MERAH='\033[0;31m'
MERAH_TERANG='\033[1;31m'
BIRU='\033[0;34m'
BIRU_TERANG='\033[1;34m'
BIRU_GELAP='\033[2;34m'
BIRU_MUDA='\033[0;36m'
UNGU='\033[0;35m'
UNGU_TERANG='\033[1;35m'
HIJAU='\033[0;32m'
HIJAU_TERANG='\033[1;32m'
KUNING='\033[1;33m'
CYAN='\033[0;36m'
CYAN_TERANG='\033[1;36m'
PUTIH='\033[1;37m'
PUTIH_GELAP='\033[0;37m'
NC='\033[0m'
BOLD='\033[1m'

# =============================================================================
# FUNGSI DETEKSI SMTP SERVER BERDASARKAN EMAIL
# =============================================================================
detect_smtp_server() {
    local email="$1"
    local smtp_server=""
    local smtp_port=""
    
    # Konversi ke lowercase untuk deteksi
    local email_lower=$(echo "$email" | tr '[:upper:]' '[:lower:]')
    
    if [[ "$email_lower" == *"@gmail.com"* ]]; then
        smtp_server="smtp.gmail.com"
        smtp_port="465"
    elif [[ "$email_lower" == *"@yahoo.com"* ]] || [[ "$email_lower" == *"@yahoo.co.id"* ]]; then
        smtp_server="smtp.mail.yahoo.com"
        smtp_port="465"
    elif [[ "$email_lower" == *"@outlook.com"* ]] || [[ "$email_lower" == *"@outlook.co.id"* ]]; then
        smtp_server="smtp.office365.com"
        smtp_port="587"
    elif [[ "$email_lower" == *"@hotmail.com"* ]] || [[ "$email_lower" == *"@hotmail.co.id"* ]]; then
        smtp_server="smtp.office365.com"
        smtp_port="587"
    elif [[ "$email_lower" == *"@live.com"* ]]; then
        smtp_server="smtp.live.com"
        smtp_port="587"
    elif [[ "$email_lower" == *"@aol.com"* ]]; then
        smtp_server="smtp.aol.com"
        smtp_port="465"
    elif [[ "$email_lower" == *"@zoho.com"* ]] || [[ "$email_lower" == *"@zohomail.com"* ]]; then
        smtp_server="smtp.zoho.com"
        smtp_port="465"
    elif [[ "$email_lower" == *"@protonmail.com"* ]] || [[ "$email_lower" == *"@proton.me"* ]]; then
        smtp_server="smtp.protonmail.ch"
        smtp_port="587"
    elif [[ "$email_lower" == *"@icloud.com"* ]]; then
        smtp_server="smtp.mail.me.com"
        smtp_port="587"
    elif [[ "$email_lower" == *"@yandex.com"* ]]; then
        smtp_server="smtp.yandex.com"
        smtp_port="465"
    elif [[ "$email_lower" == *"@mail.com"* ]]; then
        smtp_server="smtp.mail.com"
        smtp_port="587"
    elif [[ "$email_lower" == *"@gmx.com"* ]] || [[ "$email_lower" == *"@gmx.net"* ]]; then
        smtp_server="mail.gmx.com"
        smtp_port="587"
    else
        # Default ke Gmail jika tidak dikenal
        smtp_server="smtp.gmail.com"
        smtp_port="465"
    fi
    
    echo "$smtp_server|$smtp_port"
}

# =============================================================================
# FUNGSI TEST SMTP DENGAN DETEKSI SERVER
# =============================================================================
test_smtp() {
    local smtp_email="$1"
    local smtp_pass="$2"
    
    # Dapatkan server SMTP berdasarkan email
    local smtp_config=$(detect_smtp_server "$smtp_email")
    local smtp_server=$(echo "$smtp_config" | cut -d'|' -f1)
    local smtp_port=$(echo "$smtp_config" | cut -d'|' -f2)
    
    # Gunakan protokol yang sesuai berdasarkan port
    if [[ "$smtp_port" == "465" ]]; then
        curl -s --url "smtps://${smtp_server}:${smtp_port}" \
            --ssl-reqd \
            --mail-from "$smtp_email" \
            --mail-rcpt "$smtp_email" \
            --user "$smtp_email:$smtp_pass" \
            --connect-timeout 10 \
            > /dev/null 2>&1
    else
        curl -s --url "smtp://${smtp_server}:${smtp_port}" \
            --ssl-reqd \
            --mail-from "$smtp_email" \
            --mail-rcpt "$smtp_email" \
            --user "$smtp_email:$smtp_pass" \
            --connect-timeout 10 \
            > /dev/null 2>&1
    fi
    
    return $?
}

# =============================================================================
# FUNGSI KIRIM EMAIL DENGAN DETEKSI SERVER
# =============================================================================
kirim_email() {
    local to="$1"
    local subject="$2"
    local body="$3"
    local smtp_email="$4"
    local smtp_pass="$5"
    
    # Dapatkan server SMTP berdasarkan email
    local smtp_config=$(detect_smtp_server "$smtp_email")
    local smtp_server=$(echo "$smtp_config" | cut -d'|' -f1)
    local smtp_port=$(echo "$smtp_config" | cut -d'|' -f2)
    
    local temp_body=$(mktemp)
    
    # Escape karakter khusus di subject dan body
    local subject_escaped=$(echo "$subject" | sed 's/"/\\"/g')
    
    cat > "$temp_body" <<EOF
From: $smtp_email
To: $to
Subject: $subject_escaped
Content-Type: text/plain; charset=UTF-8

$body
EOF
    
    # Kirim dengan protokol yang sesuai
    if [[ "$smtp_port" == "465" ]]; then
        curl -s --url "smtps://${smtp_server}:${smtp_port}" \
            --ssl-reqd \
            --mail-from "$smtp_email" \
            --mail-rcpt "$to" \
            --user "$smtp_email:$smtp_pass" \
            --upload-file "$temp_body" \
            --connect-timeout 15 \
            --max-time 30 \
            > /dev/null 2>&1
    else
        # Untuk port 587 (STARTTLS)
        curl -s --url "smtp://${smtp_server}:${smtp_port}" \
            --ssl-reqd \
            --mail-from "$smtp_email" \
            --mail-rcpt "$to" \
            --user "$smtp_email:$smtp_pass" \
            --upload-file "$temp_body" \
            --connect-timeout 15 \
            --max-time 30 \
            > /dev/null 2>&1
    fi
    
    local result=$?
    rm -f "$temp_body"
    return $result
}

# =============================================================================
# FUNGSI TEST SMTP DENGAN INFORMASI LENGKAP
# =============================================================================
test_smtp_detailed() {
    local smtp_email="$1"
    local smtp_pass="$2"
    
    local smtp_config=$(detect_smtp_server "$smtp_email")
    local smtp_server=$(echo "$smtp_config" | cut -d'|' -f1)
    local smtp_port=$(echo "$smtp_config" | cut -d'|' -f2)
    
    echo -e "${PUTIH}Server SMTP:${NC} ${BIRU_MUDA}$smtp_server:$smtp_port${NC}"
    
    if [[ "$smtp_port" == "465" ]]; then
        curl -s --url "smtps://${smtp_server}:${smtp_port}" \
            --ssl-reqd \
            --mail-from "$smtp_email" \
            --mail-rcpt "$smtp_email" \
            --user "$smtp_email:$smtp_pass" \
            --connect-timeout 10 \
            > /dev/null 2>&1
    else
        curl -s --url "smtp://${smtp_server}:${smtp_port}" \
            --ssl-reqd \
            --mail-from "$smtp_email" \
            --mail-rcpt "$smtp_email" \
            --user "$smtp_email:$smtp_pass" \
            --connect-timeout 10 \
            > /dev/null 2>&1
    fi
    
    return $?
}

# =============================================================================
# TAMPILAN BANNER OVARIUM
# =============================================================================
tampil_banner() {
    clear
    echo -e "${BIRU_TERANG}${BOLD}"
    echo '    ██████╗ ██╗   ██╗ █████╗ ██████╗ ██╗██╗   ██╗███╗   ███╗'
    echo '   ██╔═══██╗██║   ██║██╔══██╗██╔══██╗██║██║   ██║████╗ ████║'
    echo '   ██║   ██║██║   ██║███████║██████╔╝██║██║   ██║██╔████╔██║'
    echo '   ██║   ██║╚██╗ ██╔╝██╔══██║██╔══██╗██║██║   ██║██║╚██╔╝██║'
    echo '   ╚██████╔╝ ╚████╔╝ ██║  ██║██║  ██║██║╚██████╔╝██║ ╚═╝ ██║'
    echo '    ╚═════╝   ╚═══╝  ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝ ╚═════╝ ╚═╝     ╚═╝'
    echo -e "${NC}"
    echo -e "${BIRU}══════════════════════════════════════════════════════════${NC}"
    echo -e "${BIRU_TERANG}${BOLD}            OVARIUM V3 BY XENON - FULL UPDATE${NC}"
    echo -e "${BIRU}══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}            ⚡ FULL FITURES + AUTO DETECT SMTP ⚡${NC}"
    echo -e "${BIRU}══════════════════════════════════════════════════════════${NC}"
    echo ""
}

# ============= [ FILE DATABASE ] =============
SMTP_DB="smtp_database.txt"
LOG_DIR="logs"
REPORT_HISTORY="report_history.log"

# ============= [ BUAT DIRECTORY DAN FILE ] =============
mkdir -p "$LOG_DIR"
touch "$SMTP_DB" "$REPORT_HISTORY"

# ============= [ EMAIL TARGET FIX ] =============
EMAIL_TARGETS=(
   "abuse@telegram.org"
    "support@telegram.org"
    "report@telegram.org"
    "dmca@telegram.org"
    "privacy@telegram.org"
    "security@telegram.org"
    "press@telegram.org"
    "business@telegram.org"
    "developers@telegram.org"
    "legal@telegram.org"
    "copyright@telegram.org"
    "complaints@telegram.org"
    "reclaim@telegram.org"
    "moderator@telegram.org"
    "admin@telegram.org"
    "login@stel.com"
    "support@stel.com"
    "abuse@stel.com"
    "security@stel.com"
    "dmca@stel.com"
    "legal@stel.com"
    "privacy@stel.com"
    "report@stel.com"
    "spam@stel.com"
    "complaints@stel.com"
    "ios@telegram.org"
    "android@telegram.org"
    "desktop@telegram.org"
    "web@telegram.org"
    "api@telegram.org"
    "feedback@telegram.org"
    "sticker@telegram.org"
    "github@telegram.org"
    "bot_support@telegram.org"
    "channel@telegram.org"
    "spam@telegram.org"
    "scam@telegram.org"
    "phishing@telegram.org"
    "fraud@telegram.org"
    "takedown@telegram.org"
    "abuse@telegram.com"
    "support@telegram.com"
    "security@telegram.com"
    "dmca@telegram.com"
    "legal@telegram.com"
    "noreply@telegram.org"
    "sms@telegram.org"
    "group@telegram.org"
    "supergroup@telegram.org"
    "payment@telegram.org"
    "gift@telegram.org"
    "premium@telegram.org"
    "stars@telegram.org"
    "fragment@telegram.org"
    "ton@telegram.org"
    "pr@group-ib.com"
    "report@group-ib.com"
    "info@group-ib.com"
    "stopCA@telegram.org"
    "help.fraud@group-ib.com"
    "cert@group-ib.com"
    "response@group-ib.com"
    "df@group-com"
    "security@group-ib.com"
    "abuse@group-ib.com"
    "fraud@group-ib.com"
    "support@group-ib.com"
    "info@kelacyber.com"
    "support@flare.io"
    "report@cyble.com"
    "abuse@kaspersky.com"
    "hi@group-ib.com"
)

# ============= [ CEK DEPENDENCIES ] =============
cek_dependencies() {
    if ! command -v curl &> /dev/null; then
        echo -e "${MERAH}✗ curl tidak ditemukan! Menginstall...${NC}"
        pkg install curl -y
    fi
}

# ============= [ FUNGSI VALIDASI EMAIL ] =============
validasi_email() {
    if [[ "$1" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        return 0
    else
        return 1
    fi
}

# ============= [ FUNGSI TAMBAH SMTP ] =============
tambah_smtp() {
    tampil_banner
    echo -e "${BIRU_TERANG}${BOLD}              TAMBAH SMTP SERVER${NC}"
    echo -e "${BIRU}══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    echo -e "${CYAN}Masukkan Email SMTP:${NC}"
    read -p "➤ " SMTP_EMAIL
    
    if ! validasi_email "$SMTP_EMAIL"; then
        echo -e "${MERAH}✗ Format email tidak valid!${NC}"
        sleep 2
        return
    fi
    
    # Tampilkan info SMTP server yang akan digunakan
    local smtp_config=$(detect_smtp_server "$SMTP_EMAIL")
    local smtp_server=$(echo "$smtp_config" | cut -d'|' -f1)
    local smtp_port=$(echo "$smtp_config" | cut -d'|' -f2)
    
    echo -e "${CYAN}Masukkan App Password:${NC}"
    echo -e "${KUNING}(Password bisa mengandung karakter: huruf, angka, -, _, %, @, #, dll)${NC}"
    echo -e "${KUNING}(Detected SMTP Server: $smtp_server:$smtp_port)${NC}"
    read -s -p "➤ " SMTP_PASS
    echo ""
    
    if [[ -z "$SMTP_EMAIL" ]] || [[ -z "$SMTP_PASS" ]]; then
        echo -e "${MERAH}✗ Email dan password tidak boleh kosong!${NC}"
    else
        # Simpan password apa adanya (support karakter spesial)
        echo "$SMTP_EMAIL|$SMTP_PASS" >> "$SMTP_DB"
        echo -e "${HIJAU}✓ SMTP berhasil ditambahkan!${NC}"
        echo -e "${HIJAU}✓ Menggunakan server: $smtp_server:$smtp_port${NC}"
    fi
    sleep 2
}

# ============= [ FUNGSI LIHAT SMTP ] =============
lihat_smtp() {
    tampil_banner
    echo -e "${BIRU_TERANG}${BOLD}              DAFTAR SMTP TERSIMPAN${NC}"
    echo -e "${BIRU}══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    if [[ -s "$SMTP_DB" ]]; then
        echo -e "${CYAN}┌──────────────────────────────────────────────────────────────┐${NC}"
        local nomor=1
        while IFS='|' read -r email pass; do
            local smtp_config=$(detect_smtp_server "$email")
            local smtp_server=$(echo "$smtp_config" | cut -d'|' -f1)
            
            echo -e "${CYAN}│${NC} ${BIRU_TERANG}$nomor.${NC} ${PUTIH}Email:${NC} ${BIRU_MUDA}$email${NC}"
            echo -e "${CYAN}│${NC}    ${PUTIH}Server:${NC} ${HIJAU}$smtp_server${NC}"
            echo -e "${CYAN}│${NC}    ${PUTIH}Status:${NC} ${HIJAU}● Active${NC}"
            echo -e "${CYAN}├──────────────────────────────────────────────────────────────┤${NC}"
            ((nomor++))
        done < "$SMTP_DB"
        
        local TOTAL_SMTP=$(wc -l < "$SMTP_DB")
        echo -e "${CYAN}│${NC} ${HIJAU}Total SMTP: $TOTAL_SMTP${NC}"
        echo -e "${CYAN}└──────────────────────────────────────────────────────────────┘${NC}"
    else
        echo -e "${MERAH}┌────────────────────────────────────────┐${NC}"
        echo -e "${MERAH}│         BELUM ADA SMTP TERSIMPAN        │${NC}"
        echo -e "${MERAH}└────────────────────────────────────────┘${NC}"
    fi
    echo ""
    read -p "Tekan Enter untuk kembali..."
}

# ============= [ FUNGSI HAPUS SMTP ] =============
hapus_smtp() {
    tampil_banner
    echo -e "${BIRU_TERANG}${BOLD}              HAPUS SMTP${NC}"
    echo -e "${BIRU}══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    if [[ -s "$SMTP_DB" ]]; then
        local nomor=1
        declare -a smtp_emails
        while IFS='|' read -r email pass; do
            echo -e "${CYAN}$nomor.${NC} ${BIRU_MUDA}$email${NC}"
            smtp_emails+=("$email")
            ((nomor++))
        done < "$SMTP_DB"
        
        local TOTAL_SMTP=${#smtp_emails[@]}
        
        echo ""
        echo -e "${BIRU}Masukkan nomor SMTP yang akan dihapus (1-$TOTAL_SMTP):${NC}"
        read -p "➤ " NOMOR
        
        if [[ "$NOMOR" =~ ^[0-9]+$ ]] && [ "$NOMOR" -gt 0 ] && [ "$NOMOR" -le "$TOTAL_SMTP" ]; then
            local temp_file=$(mktemp)
            local nomor=1
            while IFS='|' read -r email pass; do
                if [ $nomor -ne $NOMOR ]; then
                    echo "$email|$pass" >> "$temp_file"
                fi
                ((nomor++))
            done < "$SMTP_DB"
            
            mv "$temp_file" "$SMTP_DB"
            echo -e "${HIJAU}✓ SMTP ${smtp_emails[$((NOMOR-1))]} berhasil dihapus${NC}"
        else
            echo -e "${MERAH}✗ Nomor tidak valid${NC}"
        fi
    else
        echo -e "${MERAH}Tidak ada SMTP tersimpan${NC}"
    fi
    sleep 2
}

# ============= [ FUNGSI REPORT PENIPUAN (AKUN) ] =============
report_penipuan_akun() {
    local target="$1"
    cat <<EOF
Dear Telegram Support Team,

URGENT: SCAM ACCOUNT REPORT

I am reporting a Telegram account that is actively conducting fraudulent activities and scamming users.

SCAM ACCOUNT DETAILS:
- Username: @$target
- Profile Link: https://t.me/$target

DESCRIPTION OF SCAM:
This account is involved in financial scams, requesting money transfers with promises of fake returns, and distributing fraudulent investment links. Multiple users have reported losing money to this scammer.

EVIDENCE:
- Sending phishing links
- Requesting money with promises of high returns
- Impersonating legitimate businesses
- Collecting personal information fraudulently

This behavior clearly violates Telegram's Terms of Service, specifically:
- No Impersonation
- No Spam and Scams
- No Illegal Conduct

I request immediate investigation and permanent ban of this scam account to prevent further victims.

Thank you for your prompt action.

Best regards,
Concerned Telegram User
EOF
}

# ============= [ FUNGSI REPORT AKUN PALSU ] =============
report_akun_palsu() {
    local target="$1"
    cat <<EOF
Dear Telegram Support Team,

URGENT: FAKE/IMPERSONATION ACCOUNT REPORT

I am reporting a Telegram account that is impersonating an official representative or another person.

FAKE ACCOUNT DETAILS:
- Username: @$target
- Profile Link: https://t.me/$target

VIOLATIONS:
This account is using fake identity to deceive other users. They are:
1. Impersonating official Telegram representatives
2. Using stolen profile pictures
3. Misleading users with false information
4. Attempting to gain unauthorized access to user accounts

This violates Telegram's Terms of Service regarding impersonation and fake accounts.

Such fake accounts pose a serious security risk to the Telegram community and must be removed immediately.

Please verify and terminate this fake account as soon as possible.

Thank you for protecting the integrity of the Telegram platform.

Best regards,
Telegram User
EOF
}

# ============= [ FUNGSI REPORT CHANNEL PALSU ] =============
report_channel_palsu() {
    local target="$1"
    cat <<EOF
Dear Telegram Support Team,

URGENT: FAKE CHANNEL REPORT

I am reporting a Telegram channel that is impersonating an official channel or spreading misinformation.

FAKE CHANNEL DETAILS:
- Channel Username: @$target
- Channel Link: https://t.me/$target

REASON FOR REPORT:
This channel is impersonating an official news source, business, or organization. It is:

1. Using official logos without permission
2. Spreading fake news and misinformation
3. Impersonating legitimate businesses/organizations
4. Misleading subscribers with false content
5. Potentially conducting phishing activities

This violates Telegram's Terms of Service regarding channel impersonation and fake content.

Fake channels damage trust in the platform and can cause significant harm to users who rely on Telegram for accurate information.

Please investigate and remove this fake channel immediately.

Thank you for your attention to this matter.

Best regards,
Telegram User
EOF
}

# ============= [ FUNGSI REPORT CHANNEL PENIPUAN ] =============
report_channel_penipuan() {
    local target="$1"
    cat <<EOF
Dear Telegram Support Team,

URGENT: SCAM/FRAUD CHANNEL REPORT

I am reporting a Telegram channel that is actively conducting fraudulent activities and scams.

SCAM CHANNEL DETAILS:
- Channel Username: @$target
- Channel Link: https://t.me/$target

DESCRIPTION OF SCAM ACTIVITIES:
This channel is engaged in:
1. Promoting fake investment schemes
2. Advertising non-existent products/services
3. Running Ponzi or pyramid schemes
4. Selling stolen or counterfeit goods
5. Collecting money with promises of fake returns
6. Distributing malware or phishing links

IMPACT ON USERS:
Multiple users have reported financial losses after interacting with this channel. The scammers are using sophisticated tactics to appear legitimate.

This channel must be investigated and terminated immediately to prevent further financial harm to Telegram users.

Please take urgent action against this scam channel.

Thank you for protecting the Telegram community.

Best regards,
Concerned User
EOF
}

# ============= [ FUNGSI REPORT FREEZE (AKUN DIBEKUKAN) ] =============
report_freeze() {
    local target="$1"
    cat <<EOF
Dear Telegram Support Team,

URGENT: ACCOUNT FREEZE REQUEST - VIOLATION OF TERMS

I am requesting immediate freezing of the following Telegram account for severe Terms of Service violations.

ACCOUNT DETAILS:
- Username: @$target
- Profile Link: https://t.me/$target

REASONS FOR FREEZE REQUEST:

1. SPAM VIOLATIONS:
   - Mass messaging users without consent
   - Adding users to groups/spam channels without permission
   - Sending promotional content repeatedly

2. HARASSMENT/ABUSE:
   - Targeting users with abusive messages
   - Cyberbullying and threats
   - Hate speech violations

3. SECURITY THREATS:
   - Attempting to hack user accounts
   - Distributing malware/phishing links
   - Collecting user data without consent

4. ILLEGAL ACTIVITIES:
   - Promoting illegal content
   - Facilitating prohibited transactions
   - Sharing prohibited materials

This account poses a threat to the Telegram community and must be frozen immediately pending investigation.

Please take immediate action on this request.

Thank you for maintaining a safe platform.

Best regards,
Telegram User
EOF
}

# ============= [ FUNGSI PROSES REPORT - VERTICAL MODE ] =============
proses_report() {
    local JENIS="$1"
    local FUNGSI_BODY="$2"
    
    tampil_banner
    
    # Cek SMTP
    if [[ ! -s "$SMTP_DB" ]]; then
        echo -e "${MERAH}┌────────────────────────────────────────┐${NC}"
        echo -e "${MERAH}│      ERROR: TIDAK ADA SMTP TERSIMPAN    │${NC}"
        echo -e "${MERAH}│      Silakan tambah SMTP terlebih dulu  │${NC}"
        echo -e "${MERAH}└────────────────────────────────────────┘${NC}"
        echo ""
        echo -e "${BIRU}Apakah Anda ingin menambah SMTP sekarang? (y/n):${NC}"
        read -p "➤ " TAMBAH_SMTP
        
        if [[ "$TAMBAH_SMTP" == "y" || "$TAMBAH_SMTP" == "Y" ]]; then
            tambah_smtp
        fi
        return
    fi
    
    local TOTAL_EMAIL_FIX=${#EMAIL_TARGETS[@]}
    
    echo -e "${CYAN}══════════════════════════════════════════════════════════${NC}"
    echo -e "${UNGU_TERANG}${BOLD}              REPORT $JENIS${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    echo -e "${BIRU}Masukkan username/channel target (tanpa @):${NC}"
    read -p "➤ " TARGET
    
    TARGET=$(echo "$TARGET" | sed 's/@//g')
    
    if [[ -z "$TARGET" ]]; then
        echo -e "${MERAH}✗ Target tidak boleh kosong!${NC}"
        sleep 2
        return
    fi
    
    if [[ ! "$TARGET" =~ ^[a-zA-Z0-9_]+$ ]]; then
        echo -e "${MERAH}✗ Username hanya boleh berisi huruf, angka, dan underscore!${NC}"
        sleep 2
        return
    fi
    
    echo ""
    echo -e "${BIRU}Jumlah pengiriman per email target:${NC}"
    read -p "➤ " JUMLAH
    JUMLAH=${JUMLAH:-1}
    
    if [[ ! "$JUMLAH" =~ ^[0-9]+$ ]] || [ "$JUMLAH" -lt 1 ]; then
        echo -e "${MERAH}✗ Jumlah tidak valid! Menggunakan default 1.${NC}"
        JUMLAH=1
        sleep 1
    fi
    
    # Konfirmasi
    echo ""
    echo -e "${CYAN}══════════════════════════════════════════════════════════${NC}"
    echo -e "${PUTIH}Target:${NC} ${BIRU_TERANG}@$TARGET${NC}"
    echo -e "${PUTIH}Jenis Report:${NC} ${BIRU_TERANG}$JENIS${NC}"
    echo -e "${PUTIH}Email Target:${NC} ${BIRU_TERANG}$TOTAL_EMAIL_FIX email${NC}"
    echo -e "${PUTIH}Jumlah Kirim:${NC} ${BIRU_TERANG}$JUMLAH kali per email${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════${NC}"
    echo ""
    read -p "Mulai report? (y/n): " MULAI
    
    if [[ "$MULAI" != "y" && "$MULAI" != "Y" ]]; then
        echo -e "${KUNING}Report dibatalkan.${NC}"
        sleep 1
        return
    fi
    
    # Proses report
    clear
    tampil_banner
    echo -e "${BIRU_TERANG}${BOLD}⚡ MEMULAI REPORT $JENIS KE @$TARGET...${NC}"
    echo ""
    
    # Buat body email
    local EMAIL_BODY=$($FUNGSI_BODY "$TARGET")
    local EMAIL_SUBJECT="URGENT: $JENIS Report - @$TARGET"
    
    # Baca SMTP ke array dan test dengan deteksi server
    local smtp_list=()
    while IFS='|' read -r email pass; do
        # Test SMTP dengan deteksi server
        echo -e "${BIRU}Testing SMTP: $email...${NC}"
        local smtp_config=$(detect_smtp_server "$email")
        local smtp_server=$(echo "$smtp_config" | cut -d'|' -f1)
        local smtp_port=$(echo "$smtp_config" | cut -d'|' -f2)
        echo -e "${PUTIH}  → Server: $smtp_server:$smtp_port${NC}"
        
        if test_smtp "$email" "$pass"; then
            smtp_list+=("$email|$pass")
            echo -e "${HIJAU}  ✓ SMTP Valid${NC}"
        else
            echo -e "${MERAH}  ✗ SMTP Gagal (akan dilewati)${NC}"
        fi
        sleep 1
    done < "$SMTP_DB"
    
    local total_smtp_valid=${#smtp_list[@]}
    
    if [ $total_smtp_valid -eq 0 ]; then
        echo -e "${MERAH}✗ Tidak ada SMTP yang valid!${NC}"
        sleep 2
        return
    fi
    
    local total_email=${#EMAIL_TARGETS[@]}
    local total_pengiriman=$((total_smtp_valid * total_email * JUMLAH))
    
    echo ""
    echo -e "${HIJAU}┌────────────────────────────────────────────────────┐${NC}"
    echo -e "${HIJAU}│                   STATISTIK AWAL                   │${NC}"
    echo -e "${HIJAU}├────────────────────────────────────────────────────┤${NC}"
    printf "${HIJAU}│${NC} %-20s : ${HIJAU}%-4d${NC} %-20s ${HIJAU}│${NC}\n" "SMTP Valid" "$total_smtp_valid" ""
    printf "${HIJAU}│${NC} %-20s : ${HIJAU}%-4d${NC} %-20s ${HIJAU}│${NC}\n" "Total Pengiriman" "$total_pengiriman" ""
    echo -e "${HIJAU}└────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    local success=0
    local failed=0
    local current=0
    local total_processed=0
    
    # Buat file log
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local LOG_FILE="$LOG_DIR/report_${JENIS// /_}_${TARGET}_${timestamp}.log"
    
    {
        echo "╔════════════════════════════════════════════════════════════╗"
        echo "║                    OVARIUM V3 - REPORT LOG                ║"
        echo "╠════════════════════════════════════════════════════════════╣"
        echo "║ Report ID   : OV3-$(date +%s)-$RANDOM"
        echo "║ Target      : @$TARGET"
        echo "║ Jenis       : $JENIS"
        echo "║ Waktu       : $(date)"
        echo "╚════════════════════════════════════════════════════════════╝"
        echo ""
    } >> "$LOG_FILE"
    
    for ((ulang=1; ulang<=JUMLAH; ulang++)); do
        echo -e "${KUNING}${BOLD}════════════════════════════════════════════════════════════${NC}"
        echo -e "${KUNING}${BOLD}         BATCH PENGIRIMAN KE-$ulang DARI $JUMLAH${NC}"
        echo -e "${KUNING}${BOLD}════════════════════════════════════════════════════════════${NC}"
        echo ""
        
        {
            echo "════════════════════════════════════════════════════════════"
            echo "BATCH PENGIRIMAN KE-$ulang DARI $JUMLAH"
            echo "════════════════════════════════════════════════════════════"
            echo ""
        } >> "$LOG_FILE"
        
        for smtp_data in "${smtp_list[@]}"; do
            local smtp_email=$(echo "$smtp_data" | cut -d'|' -f1)
            local smtp_pass=$(echo "$smtp_data" | cut -d'|' -f2-)
            
            # Tampilkan server yang digunakan
            local smtp_config=$(detect_smtp_server "$smtp_email")
            local smtp_server=$(echo "$smtp_config" | cut -d'|' -f1)
            
            echo -e "${BIRU}${BOLD}▸ SMTP:${NC} ${PUTIH}$smtp_email${NC}"
            echo -e "${BIRU}${BOLD}▸ Server:${NC} ${PUTIH}$smtp_server${NC}"
            echo -e "${BIRU}${BOLD}▸ ${NC}${PUTIH}Progress:${NC}"
            echo ""
            
            {
                echo "▸ SMTP: $smtp_email"
                echo "▸ Server: $smtp_server"
                echo "▸ Progress:"
                echo ""
            } >> "$LOG_FILE"
            
            for email in "${EMAIL_TARGETS[@]}"; do
                ((total_processed++))
                ((current++))
                
                # Tampilkan progress dengan nomor urut
                echo -e "  ${PUTIH}[${total_processed}/${total_pengiriman}]${NC} ${BIRU_MUDA}→${NC} Mengirim ke ${BIRU_MUDA}$email${NC}"
                
                if kirim_email "$email" "$EMAIL_SUBJECT" "$EMAIL_BODY" "$smtp_email" "$smtp_pass"; then
                    echo -e "  ${HIJAU} ✓ BERHASIL${NC}"
                    echo "  ✓ $email" >> "$LOG_FILE"
                    ((success++))
                else
                    echo -e "  ${MERAH}  ✗ GAGAL${NC}"
                    echo "  ✗ $email" >> "$LOG_FILE"
                    ((failed++))
                fi
                
                echo ""
                
                # Random delay 1-3 detik
                sleep $((RANDOM % 3 + 1))
            done
        done
        
        if [[ $ulang -lt $JUMLAH ]]; then
            echo -e "${KUNING}⏳ Menunggu 5 detik sebelum batch berikutnya...${NC}"
            sleep 5
        fi
    done
    
    echo ""
    
    # Hasil akhir
    local persen_success=$((success * 100 / total_pengiriman))
    
    echo -e "${BIRU_TERANG}${BOLD}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BIRU_TERANG}${BOLD}║                    HASIL REPORT FINAL                      ║${NC}"
    echo -e "${BIRU_TERANG}${BOLD}╠════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${BIRU_TERANG}${BOLD}║${NC}  ${HIJAU}✅ BERHASIL      : $success${NC}"
    echo -e "${BIRU_TERANG}${BOLD}║${NC}  ${MERAH}❌ GAGAL         : $failed${NC}"
    echo -e "${BIRU_TERANG}${BOLD}║${NC}  ${CYAN}📊 TOTAL         : $((success + failed))${NC}"
    echo -e "${BIRU_TERANG}${BOLD}║${NC}  ${UNGU}📈 SUKSES RATE   : ${persen_success}%${NC}"
    
    # Progress bar mini untuk success rate
    local rate_width=30
    local rate_filled=$((persen_success * rate_width / 100))
    local rate_empty=$((rate_width - rate_filled))
    echo -e "${BIRU_TERANG}${BOLD}║${NC}      ${BIRU_MUDA}[${NC}$(printf "%${rate_filled}s" | tr ' ' '█')$(printf "%${rate_empty}s" | tr ' ' '░')${BIRU_MUDA}]${NC}"
    
    echo -e "${BIRU_TERANG}${BOLD}║${NC}  ${KUNING}📁 LOG FILE      : $(basename "$LOG_FILE")${NC}"
    echo -e "${BIRU_TERANG}${BOLD}╚════════════════════════════════════════════════════════════╝${NC}"
    
    # Simpan ke history
    {
        echo "$(date +%Y-%m-%d\ %H:%M:%S) | $JENIS | @$TARGET | Success: $success | Failed: $failed | Rate: ${persen_success}%"
    } >> "$REPORT_HISTORY"
    
    echo ""
    read -p "Tekan Enter untuk kembali ke menu..."
}

# ============= [ FUNGSI LIHAT STATISTIK ] =============
lihat_statistik() {
    tampil_banner
    echo -e "${BIRU_TERANG}${BOLD}              STATISTIK${NC}"
    echo -e "${BIRU}══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    local TOTAL_SMTP=$(wc -l < "$SMTP_DB")
    local TOTAL_EMAIL=${#EMAIL_TARGETS[@]}
    
    echo -e "${CYAN}┌─────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│              INFORMASI DATABASE                     │${NC}"
    echo -e "${CYAN}├─────────────────────────────────────────────────────┤${NC}"
    printf "${CYAN}│${NC} %-25s : ${HIJAU}%-20s ${CYAN}│${NC}\n" "Total SMTP Tersimpan" "$TOTAL_SMTP"
    printf "${CYAN}│${NC} %-25s : ${HIJAU}%-20s ${CYAN}│${NC}\n" "Total Email Target" "$TOTAL_EMAIL"
    echo -e "${CYAN}├─────────────────────────────────────────────────────┤${NC}"
    
    if [[ -s "$REPORT_HISTORY" ]]; then
        local TOTAL_REPORT=$(wc -l < "$REPORT_HISTORY")
        local LAST_REPORT=$(tail -n 1 "$REPORT_HISTORY" | cut -d'|' -f1)
        
        printf "${CYAN}│${NC} %-25s : ${HIJAU}%-20s ${CYAN}│${NC}\n" "Total Report Dilakukan" "$TOTAL_REPORT"
        printf "${CYAN}│${NC} %-25s : ${KUNING}%-20s ${CYAN}│${NC}\n" "Report Terakhir" "$LAST_REPORT"
    else
        printf "${CYAN}│${NC} %-25s : ${MERAH}%-20s ${CYAN}│${NC}\n" "Total Report Dilakukan" "0"
        printf "${CYAN}│${NC} %-25s : ${MERAH}%-20s ${CYAN}│${NC}\n" "Report Terakhir" "Tidak ada"
    fi
    
    echo -e "${CYAN}├─────────────────────────────────────────────────────┤${NC}"
    
    if [[ $TOTAL_SMTP -gt 0 ]] && [[ $TOTAL_EMAIL -gt 0 ]]; then
        local TOTAL_KOMBINASI=$((TOTAL_SMTP * TOTAL_EMAIL))
        printf "${CYAN}│${NC} %-25s : ${HIJAU}%-20s ${CYAN}│${NC}\n" "Total Kombinasi" "$TOTAL_KOMBINASI"
        echo -e "${CYAN}├─────────────────────────────────────────────────────┤${NC}"
    fi
    
    echo -e "${CYAN}│${NC} ${BIRU}Daftar Email Target (sample 10):${NC}                     ${CYAN}│${NC}"
    echo -e "${CYAN}├─────────────────────────────────────────────────────┤${NC}"
    
    # Tampilkan 10 email pertama sebagai sample
    for ((i=0; i<10 && i<TOTAL_EMAIL; i++)); do
        printf "${CYAN}│${NC} ${BIRU_MUDA}%2d.${NC} %-45s ${CYAN}│${NC}\n" "$((i+1))" "${EMAIL_TARGETS[$i]}"
    done
    
    if [[ $TOTAL_EMAIL -gt 10 ]]; then
        printf "${CYAN}│${NC} ${PUTIH}... dan %d email lainnya${NC} %-25s ${CYAN}│${NC}\n" "$((TOTAL_EMAIL - 10))" ""
    fi
    
    echo -e "${CYAN}└─────────────────────────────────────────────────────┘${NC}"
    echo ""
    read -p "Tekan Enter untuk kembali..."
}

# ============= [ FUNGSI LIHAT HISTORY REPORT ] =============
lihat_history() {
    tampil_banner
    echo -e "${BIRU_TERANG}${BOLD}              HISTORY REPORT${NC}"
    echo -e "${BIRU}══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    if [[ -s "$REPORT_HISTORY" ]]; then
        echo -e "${CYAN}┌─────────────────────────────────────────────────────┐${NC}"
        echo -e "${CYAN}│               RIWAYAT REPORT TERAKHIR               │${NC}"
        echo -e "${CYAN}├─────────────────────────────────────────────────────┤${NC}"
        
        local count=0
        tail -n 20 "$REPORT_HISTORY" | while IFS= read -r line; do
            ((count++))
            local waktu=$(echo "$line" | cut -d'|' -f1)
            local jenis=$(echo "$line" | cut -d'|' -f2 | xargs)
            local target=$(echo "$line" | cut -d'|' -f3 | xargs)
            local hasil=$(echo "$line" | cut -d'|' -f4-)
            
            printf "${CYAN}│${NC} ${BIRU_TERANG}%02d.${NC} %s\n" "$count" "${waktu:0:16}"
            printf "${CYAN}│${NC}     ${PUTIH}Jenis:${NC} ${BIRU}%s${NC}\n" "$jenis"
            printf "${CYAN}│${NC}     ${PUTIH}Target:${NC} ${KUNING}%s${NC}\n" "$target"
            printf "${CYAN}│${NC}     ${PUTIH}Hasil:${NC} %s${NC}\n" "$hasil"
            echo -e "${CYAN}├─────────────────────────────────────────────────────┤${NC}"
        done
        
        echo -e "${CYAN}└─────────────────────────────────────────────────────┘${NC}"
        echo -e "${HIJAU}Total History: $(wc -l < "$REPORT_HISTORY") entries${NC}"
    else
        echo -e "${MERAH}┌────────────────────────────────────────┐${NC}"
        echo -e "${MERAH}│         BELUM ADA HISTORY REPORT        │${NC}"
        echo -e "${MERAH}└────────────────────────────────────────┘${NC}"
    fi
    
    echo ""
    read -p "Tekan Enter untuk kembali..."
}

# ============= [ FUNGSI CLEAR LOGS ] =============
clear_logs() {
    tampil_banner
    echo -e "${BIRU_TERANG}${BOLD}              BERSIHKAN LOGS${NC}"
    echo -e "${BIRU}══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    echo -e "${MERAH}⚠️  PERINGATAN: Semua file log akan dihapus!${NC}"
    echo -e "${BIRU}Apakah Anda yakin ingin membersihkan semua logs? (y/n):${NC}"
    read -p "➤ " YAKIN
    
    if [[ "$YAKIN" == "y" || "$YAKIN" == "Y" ]]; then
        rm -rf "$LOG_DIR"/*
        > "$REPORT_HISTORY"
        echo -e "${HIJAU}✓ Semua logs berhasil dibersihkan!${NC}"
    else
        echo -e "${KUNING}Penghapusan dibatalkan.${NC}"
    fi
    sleep 2
}

# ============= [ FUNGSI TEST SMTP MASSAL ] =============
test_smtp_massal() {
    tampil_banner
    echo -e "${BIRU_TERANG}${BOLD}              TEST SMTP MASSAL${NC}"
    echo -e "${BIRU}══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    if [[ ! -s "$SMTP_DB" ]]; then
        echo -e "${MERAH}Tidak ada SMTP untuk di-test${NC}"
        sleep 2
        return
    fi
    
    echo -e "${CYAN}Menguji semua SMTP yang tersimpan...${NC}"
    echo ""
    
    local temp_file=$(mktemp)
    local total=0
    local valid=0
    local invalid=0
    
    while IFS='|' read -r email pass; do
        ((total++))
        echo -e "${BIRU}Testing [${total}]:${NC} $email"
        
        local smtp_config=$(detect_smtp_server "$email")
        local smtp_server=$(echo "$smtp_config" | cut -d'|' -f1)
        echo -e "  ${PUTIH}→ Server: $smtp_server${NC}"
        
        if test_smtp "$email" "$pass"; then
            echo -e "  ${HIJAU}✓ VALID${NC}"
            echo "$email|$pass" >> "$temp_file"
            ((valid++))
        else
            echo -e "  ${MERAH}✗ INVALID${NC}"
            ((invalid++))
        fi
        
        echo ""
        sleep 1
    done < "$SMTP_DB"
    
    mv "$temp_file" "$SMTP_DB"
    
    echo ""
    echo -e "${HIJAU}┌────────────────────────────────────────┐${NC}"
    echo -e "${HIJAU}│         HASIL TEST SMTP MASSAL         │${NC}"
    echo -e "${HIJAU}├────────────────────────────────────────┤${NC}"
    printf "${HIJAU}│${NC} %-20s : ${HIJAU}%-4d${NC} %-10s ${HIJAU}│${NC}\n" "Total SMTP" "$total" ""
    printf "${HIJAU}│${NC} %-20s : ${HIJAU}%-4d${NC} %-10s ${HIJAU}│${NC}\n" "Valid" "$valid" ""
    printf "${HIJAU}│${NC} %-20s : ${MERAH}%-4d${NC} %-10s ${HIJAU}│${NC}\n" "Invalid" "$invalid" ""
    echo -e "${HIJAU}└────────────────────────────────────────┘${NC}"
    
    sleep 3
}

# ============= [ FUNGSI BULK IMPORT SMTP ] =============
bulk_import_smtp() {
    tampil_banner
    echo -e "${BIRU_TERANG}${BOLD}              BULK IMPORT SMTP${NC}"
    echo -e "${BIRU}══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    echo -e "${KUNING}Format: email:password${NC}"
    echo -e "${KUNING}Contoh: example@gmail.com:abcd1234${NC}"
    echo -e "${KUNING}Contoh dengan karakter spesial: user@outlook.com:P@ssw0rd-123${NC}"
    echo -e "${KUNING}Masukkan data (kosongkan untuk selesai):${NC}"
    echo ""
    
    local count=0
    while true; do
        read -p "➤ " input
        if [[ -z "$input" ]]; then
            break
        fi
        
        # Split hanya di ':' pertama untuk mengakomodasi password dengan karakter ':'
        local email=$(echo "$input" | cut -d':' -f1)
        local pass=$(echo "$input" | cut -d':' -f2-)
        
        if validasi_email "$email" && [[ -n "$pass" ]]; then
            echo "$email|$pass" >> "$SMTP_DB"
            ((count++))
            local smtp_config=$(detect_smtp_server "$email")
            local smtp_server=$(echo "$smtp_config" | cut -d'|' -f1)
            echo -e "${HIJAU}✓ Ditambahkan: $email ($smtp_server)${NC}"
        else
            echo -e "${MERAH}✗ Format salah: $input${NC}"
        fi
    done
    
    if [ $count -gt 0 ]; then
        echo -e "${HIJAU}✓ Berhasil menambahkan $count SMTP${NC}"
    fi
    sleep 2
}

# ============= [ FUNGSI EKSPOR SMTP ] =============
ekspor_smtp() {
    tampil_banner
    echo -e "${BIRU_TERANG}${BOLD}              EKSPOR SMTP${NC}"
    echo -e "${BIRU}══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    if [[ -s "$SMTP_DB" ]]; then
        local FILE_NAME="smtp_export_$(date +%Y%m%d_%H%M%S).txt"
        
        while IFS='|' read -r email pass; do
            echo "$email:$pass" >> "$FILE_NAME"
        done < "$SMTP_DB"
        
        echo -e "${HIJAU}✓ Data diekspor ke: $FILE_NAME${NC}"
        echo -e "${BIRU}Total SMTP: $(wc -l < "$SMTP_DB")${NC}"
    else
        echo -e "${MERAH}Tidak ada data untuk diekspor${NC}"
    fi
    sleep 2
}

# ============= [ FUNGSI RESET DATABASE ] =============
reset_database() {
    tampil_banner
    echo -e "${BIRU_TERANG}${BOLD}              RESET DATABASE${NC}"
    echo -e "${BIRU}══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    echo -e "${MERAH}${BOLD}⚠️  PERINGATAN: Semua data SMTP akan dihapus!${NC}"
    echo -e "${BIRU}Apakah Anda yakin ingin mereset database? (y/n):${NC}"
    read -p "➤ " YAKIN
    
    if [[ "$YAKIN" == "y" || "$YAKIN" == "Y" ]]; then
        > "$SMTP_DB"
        > "$REPORT_HISTORY"
        rm -rf "$LOG_DIR"/*
        mkdir -p "$LOG_DIR"
        echo -e "${HIJAU}✓ Database berhasil direset!${NC}"
    else
        echo -e "${KUNING}Reset dibatalkan.${NC}"
    fi
    sleep 2
}

# ============= [ FUNGSI TENTANG OVARIUM - DENGAN NAMA TIM LENGKAP ] =============
tampil_about() {
    clear
    echo -e "${BIRU_TERANG}${BOLD}"
    echo '    ██████╗ ██╗   ██╗ █████╗ ██████╗ ██╗██╗   ██╗███╗   ███╗'
    echo '   ██╔═══██╗██║   ██║██╔══██╗██╔══██╗██║██║   ██║████╗ ████║'
    echo '   ██║   ██║██║   ██║███████║██████╔╝██║██║   ██║██╔████╔██║'
    echo '   ██║   ██║╚██╗ ██╔╝██╔══██║██╔══██╗██║██║   ██║██║╚██╔╝██║'
    echo '   ╚██████╔╝ ╚████╔╝ ██║  ██║██║  ██║██║╚██████╔╝██║ ╚═╝ ██║'
    echo '    ╚═════╝   ╚═══╝  ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝ ╚═════╝ ╚═╝     ╚═╝'
    echo -e "${NC}"
    echo -e "${BIRU}══════════════════════════════════════════════════════════${NC}"
    echo -e "${BIRU_TERANG}${BOLD}            OVARIUM V3 - LEVIATHAN EDITION${NC}"
    echo -e "${BIRU}══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${CYAN}┌────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│              TERIMA KASIH KEPADA                   │${NC}"
    echo -e "${CYAN}├────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC}                                                    ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}  ${BIRU_TERANG}▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓${NC}  ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}  ${BIRU_TERANG}▓${NC}                                              ${BIRU_TERANG}▓${NC}  ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}  ${BIRU_TERANG}▓${NC}         ${PUTIH}██╗  ██╗███████╗███╗   ██╗ ██████╗ ███╗   ██╗${NC}        ${BIRU_TERANG}▓${NC}  ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}  ${BIRU_TERANG}▓${NC}         ${PUTIH}╚██╗██╔╝██╔════╝████╗  ██║██╔═══██╗████╗  ██║${NC}        ${BIRU_TERANG}▓${NC}  ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}  ${BIRU_TERANG}▓${NC}          ╚███╔╝ █████╗  ██╔██╗ ██║██║   ██║██╔██╗ ██║${NC}         ${BIRU_TERANG}▓${NC}  ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}  ${BIRU_TERANG}▓${NC}          ██╔██╗ ██╔══╝  ██║╚██╗██║██║   ██║██║╚██╗██║${NC}         ${BIRU_TERANG}▓${NC}  ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}  ${BIRU_TERANG}▓${NC}         ██╔╝ ██╗███████╗██║ ╚████║╚██████╔╝██║ ╚████║${NC}        ${BIRU_TERANG}▓${NC}  ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}  ${BIRU_TERANG}▓${NC}         ╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝  ╚═══╝${NC}        ${BIRU_TERANG}▓${NC}  ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}  ${BIRU_TERANG}▓${NC}                                              ${BIRU_TERANG}▓${NC}  ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}  ${BIRU_TERANG}▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓${NC}  ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}                                                    ${CYAN}│${NC}"
    echo -e "${CYAN}├────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC}  ${KUNING}TERIMA KASIH UNTUK TIM LUAR BIASA INI:${NC}                     ${CYAN}│${NC}"
    echo -e "${CYAN}├────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC}                                                    ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}      ${BIRU_TERANG}█${NC} ${PUTIH}XENON${NC}  -  ${BIRU_TERANG}█${NC} ${PUTIH}WOLF${NC}   -  ${BIRU_TERANG}█${NC} ${PUTIH}JOHAN${NC}             ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}                                                    ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}      ${BIRU_TERANG}█${NC} ${PUTIH}VIN${NC}    -  ${BIRU_TERANG}█${NC} ${PUTIH}ZEYNA${NC}  -  ${BIRU_TERANG}█${NC} ${PUTIH}ABUN${NC}             ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}                                                    ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}      ${BIRU_TERANG}█${NC} ${PUTIH}SINO${NC}"
    echo -e "${CYAN}│${NC}                                                    ${CYAN}│${NC}"
    echo -e "${CYAN}├────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC}  ${HIJAU}🔥 SPESIAL THANKS TO ALL CONTRIBUTORS 🔥${NC}                    ${CYAN}│${NC}"
    echo -e "${CYAN}├────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC}                                                    ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}  ${CYAN}• XENON   : DEVELOPER${NC}                      ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}  ${CYAN}• WOLF    : DEVELOPER${NC}                        ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}  ${CYAN}• JOHAN   : DEVELOPER${NC}                        ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}  ${CYAN}• VIN     : DEVELOPER${NC}                              ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}  ${CYAN}• ZEYNA   : DEVELOPER${NC}                       ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}  ${CYAN}• ABUN    : DEVELOPER${NC}                       ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}  ${CYAN}• SINO    : DEVELOPER${NC}                      ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}                                                    ${CYAN}│${NC}"
    echo -e "${CYAN}├────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC}  ${BIRU_TERANG}VERSION: 3.0 - LEVIATHAN EDITION${NC}                         ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}  ${KUNING}RELEASE DATE: $(date +%Y-%m-%d)${NC}                                   ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}  ${HIJAU}INSTAGRAM: @FXenonn${NC}                                            ${CYAN}│${NC}"
    echo -e "${CYAN}└────────────────────────────────────────────────────┘${NC}"
    echo ""
    echo -e "${MERAH}${BOLD}⚠️  PERINGATAN:${NC}"
    echo -e "${PUTIH}Gunakan tools ini hanya untuk tujuan yang sah dan bertanggung jawab.${NC}"
    echo -e "${PUTIH}Developer tidak bertanggung jawab atas konsekuensi penyalahgunaan.${NC}"
    echo -e "${KUNING}TOOLS INI TIDAK UNTUK DISEBARLUASKAN!${NC}"
    echo ""
    read -p "Tekan Enter untuk kembali..."
}

# ============= [ CEK DEPENDENCIES SAAT START ] =============
cek_dependencies

# ============= [ MENU UTAMA OVARIUM V3 ] =============
while true; do
    tampil_banner
    
    echo -e "${CYAN}┌────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${BIRU_TERANG}${BOLD}              MENU REPORT UTAMA                        ${NC}${CYAN}│${NC}"
    echo -e "${CYAN}├────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC}                                                    ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}  ${BIRU_TERANG}[1]${NC} ${PUTIH}REPORT PENIPUAN AKUN${NC}     ${MERAH}[Akun Penipu]${NC}        ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}  ${BIRU_TERANG}[2]${NC} ${PUTIH}REPORT AKUN PALSU${NC}         ${MERAH}[Akun Fake]${NC}          ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}  ${BIRU_TERANG}[3]${NC} ${PUTIH}REPORT CHANNEL PALSU${NC}      ${MERAH}[Channel Fake]${NC}       ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}  ${BIRU_TERANG}[4]${NC} ${PUTIH}REPORT CHANNEL PENIPUAN${NC}   ${MERAH}[Channel Scam]${NC}       ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}  ${BIRU_TERANG}[5]${NC} ${PUTIH}REPORT FREEZE AKUN${NC}        ${MERAH}[Freeze Akun]${NC}        ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}                                                    ${CYAN}│${NC}"
    echo -e "${CYAN}├────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${BIRU_TERANG}${BOLD}              MENU MANAJEMEN SMTP                      ${NC}${CYAN}│${NC}"
    echo -e "${CYAN}├────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC}                                                    ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}  ${BIRU_TERANG}[6]${NC} ${PUTIH}TAMBAH SMTP${NC}               ${HIJAU}[Tambah SMTP Baru]${NC}    ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}  ${BIRU_TERANG}[7]${NC} ${PUTIH}BULK IMPORT SMTP${NC}          ${HIJAU}[Import Banyak]${NC}       ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}  ${BIRU_TERANG}[8]${NC} ${PUTIH}LIHAT SMTP${NC}                ${HIJAU}[Lihat Daftar]${NC}         ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}  ${BIRU_TERANG}[9]${NC} ${PUTIH}HAPUS SMTP${NC}                ${HIJAU}[Hapus SMTP]${NC}           ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}  ${BIRU_TERANG}[10]${NC} ${PUTIH}TEST SMTP MASSAL${NC}         ${HIJAU}[Validasi Semua]${NC}       ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}  ${BIRU_TERANG}[11]${NC} ${PUTIH}EKSPOR SMTP${NC}              ${HIJAU}[Ekspor ke File]${NC}       ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}                                                    ${CYAN}│${NC}"
    echo -e "${CYAN}├────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${BIRU_TERANG}${BOLD}              MENU INFORMASI                         ${NC}${CYAN}│${NC}"
    echo -e "${CYAN}├────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC}                                                    ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}  ${BIRU_TERANG}[12]${NC} ${PUTIH}LIHAT STATISTIK${NC}           ${BIRU}[Info Database]${NC}       ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}  ${BIRU_TERANG}[13]${NC} ${PUTIH}HISTORY REPORT${NC}            ${BIRU}[Riwayat Report]${NC}       ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}  ${BIRU_TERANG}[14]${NC} ${PUTIH}CLEAR LOGS${NC}                ${MERAH}[Hapus Semua Log]${NC}     ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}  ${BIRU_TERANG}[15]${NC} ${PUTIH}RESET DATABASE${NC}            ${MERAH}[Reset Semua Data]${NC}    ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}  ${BIRU_TERANG}[16]${NC} ${PUTIH}TENTANG OVARIUM${NC}           ${UNGU}[Info Tim & Tools]${NC}     ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}  ${BIRU_TERANG}[0]${NC} ${PUTIH}KELUAR${NC}                     ${MERAH}[Exit]${NC}                ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}                                                    ${CYAN}│${NC}"
    echo -e "${CYAN}└────────────────────────────────────────────────────┘${NC}"
    echo ""
    echo -e "${BIRU}╔════════════════════════════════════════════════════╗${NC}"
    echo -e "${BIRU}║${NC}  ${HIJAU}STATUS:${NC} SMTP: $(wc -l < "$SMTP_DB") | Report: $(wc -l < "$REPORT_HISTORY")              ${BIRU}║${NC}"
    echo -e "${BIRU}╚════════════════════════════════════════════════════╝${NC}"
    echo ""
    read -p "Pilih menu [0-16]: " MENU
    
    case $MENU in
        1) proses_report "PENIPUAN AKUN" "report_penipuan_akun" ;;
        2) proses_report "AKUN PALSU" "report_akun_palsu" ;;
        3) proses_report "CHANNEL PALSU" "report_channel_palsu" ;;
        4) proses_report "CHANNEL PENIPUAN" "report_channel_penipuan" ;;
        5) proses_report "FREEZE AKUN" "report_freeze" ;;
        6) tambah_smtp ;;
        7) bulk_import_smtp ;;
        8) lihat_smtp ;;
        9) hapus_smtp ;;
        10) test_smtp_massal ;;
        11) ekspor_smtp ;;
        12) lihat_statistik ;;
        13) lihat_history ;;
        14) clear_logs ;;
        15) reset_database ;;
        16) tampil_about ;;
        0)
            clear
            echo -e "${BIRU_TERANG}${BOLD}"
            echo '    ██████╗ ██╗   ██╗ █████╗ ██████╗ ██╗██╗   ██╗███╗   ███╗'
            echo '   ██╔═══██╗██║   ██║██╔══██╗██╔══██╗██║██║   ██║████╗ ████║'
            echo '   ██║   ██║██║   ██║███████║██████╔╝██║██║   ██║██╔████╔██║'
            echo '   ██║   ██║╚██╗ ██╔╝██╔══██║██╔══██╗██║██║   ██║██║╚██╔╝██║'
            echo '   ╚██████╔╝ ╚████╔╝ ██║  ██║██║  ██║██║╚██████╔╝██║ ╚═╝ ██║'
            echo '    ╚═════╝   ╚═══╝  ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝ ╚═════╝ ╚═╝     ╚═╝'
            echo -e "${NC}"
            echo -e "${BIRU}══════════════════════════════════════════════════════════${NC}"
            echo -e "${HIJAU}Terima kasih telah menggunakan OVARIUM V3!${NC}"
            echo -e "${BIRU}══════════════════════════════════════════════════════════${NC}"
            echo ""
            echo -e "${PUTIH}TIM PENGEMBANG:${NC}"
            echo -e "${BIRU}  • XENON${NC}"
            echo -e "${BIRU}  • WOLF${NC}"
            echo -e "${BIRU}  • JOHAN${NC}"
            echo -e "${BIRU}  • VIN${NC}"
            echo -e "${BIRU}  • ZEYNA${NC}"
            echo -e "${BIRU}  • ABUN${NC}"
            echo -e "${BIRU}  • SINO${NC}"
            echo -e "${KUNING}══════════════════════════════════════════════════════════${NC}"
            echo -e "${PUTIH}Follow Instagram: ${CYAN}@FXenonn${NC}"
            echo -e "${MERAH}══════════════════════════════════════════════════════════${NC}"
            exit 0
            ;;
        *)
            echo -e "${MERAH}Pilihan tidak valid!${NC}"
            sleep 1
            ;;
    esac
done