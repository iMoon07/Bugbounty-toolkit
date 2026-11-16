#!/bin/bash

# ==============================================================================
# OWASP LAB TOOLKIT - SMART UPDATER
# Developed by iMoon (linkedin.com/in/imoon07) · infosec-world.id · Inspired by Taro Lay (linkedin.com/in/tarolay)
# ==============================================================================

if [[ $EUID -ne 0 ]]; then
   exec sudo "$0" "$@"
   exit 1
fi

# Prevent Git from prompting for passwords
export GIT_TERMINAL_PROMPT=0

# -----------------------------------------
# [ CONFIGURATION ]
# Memuat Config & UI / Load Settings
# -----------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "${SCRIPT_DIR}/owasp-apps.conf" ]; then
    source "${SCRIPT_DIR}/owasp-apps.conf"
else
    echo -e "\033[1;31m[!] Error: Missing owasp-apps.conf.\033[0m"
    exit 1
fi

# Load DB Config
DB_USER="owasp_user"
DB_PASS="Owasp#Lab123"
if [ -f /etc/owasp-lab/config.env ]; then
    source /etc/owasp-lab/config.env
fi

# -----------------------------------------
# [ UI / FRONTEND ]
# Command Line Interface
# -----------------------------------------
clear
printf '\n%.0s' {1..40}
printf '\033[2J\033[H\033[40m'

echo -e "${REDBG}${YLW}                                                                        ${RST}"
echo -e "${REDBG}${YLW}                     OWASP LAB TOOLKIT UPDATER v1.0                     ${RST}"
echo -e "${REDBG}${YLW}                                                                        ${RST}"
echo ""

_print_ascii_art

_tp "${CYN}┄┄ UPDATER PHASE ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄${RST}"
_tp "${DIM}Updating toolkit and lab apps...${RST}"
_tp ""
_tp "${WHT}Target : ${YLW}OWASP Lab Applications${RST}"
_tp ""

_prmpt "${RED}[?] Start Update Process? (Y/n): ${RST}"
read confirm
if [[ "$confirm" != "Y" && "$confirm" != "y" && "$confirm" != "" ]]; then
   echo -e "\n${RED}[x] Update aborted by user.${RST}"
   exit 1
fi

echo ""
sleep 1

# Setup Logging
tput civis
trap 'tput cnorm; echo ""; exit 1' EXIT INT TERM
LOG_FILE="${SCRIPT_DIR}/owasp-lab.log"
> "$LOG_FILE"

# ==========================================
# [ BACKEND EXECUTION ]
# Main Core Process Execution
# ==========================================

_hdr "PREPARING SYSTEM"

_cleanup_stalled() {
    local PROCS_TO_KILL=("git" "wget" "curl" "unzip" "tar")
    for p in "${PROCS_TO_KILL[@]}"; do killall -9 "$p" 2>/dev/null || true; done

    local FILES_TO_RM=(
        "/var/lib/apt/lists/lock"
        "/var/cache/apt/archives/lock"
    )
    for f in "${FILES_TO_RM[@]}"; do rm -f "$f" 2>/dev/null || true; done
    rm -f /var/lib/dpkg/lock* 2>/dev/null || true
    dpkg --configure -a 2>/dev/null || true
}
_run "Cleaning Stalled Apt Processes" "_cleanup_stalled"



# ------------------------------------------------------------------------------
_hdr "SMART UPDATE"

_update_apps() {
    local HACK_DIR="/var/www/hack"
    
    # Bypass Git dubious ownership check for root operating on www-data folders
    git config --global --add safe.directory '*'

    for app in "${APPS_LIST[@]}"; do
        local url="${APP_URL[$app]}"
        local clone_dir="${APP_DIR[$app]}"
        local target_path="$HACK_DIR/$clone_dir"

        if [[ "$url" == *.git ]]; then
            if [ -d "$target_path/.git" ]; then
                cd "$target_path" || continue
                git config --global --add safe.directory "$target_path"
                git reset --hard HEAD
                git pull
                cd - >/dev/null || true
            fi
        fi
    done
    
    # Dynamic GitHub API update for Non-Git Apps (From Scratch / Absolute Latest)
    
    # Adminer
    local adminer_dir="${APP_DIR[adminer]}"
    if [ -n "$adminer_dir" ] && [ -d "$HACK_DIR" ]; then
        local ADM_URL=$(curl -s https://api.github.com/repos/vrana/adminer/releases/latest | grep -oP '"browser_download_url": "\K(.*adminer-mysql-en\.php)(?=")' | head -n 1)
        mkdir -p "$HACK_DIR/$adminer_dir"
        if [ -n "$ADM_URL" ]; then
            wget -q "$ADM_URL" -O "$HACK_DIR/$adminer_dir/index.php"
        else
            wget -q "https://www.adminer.org/latest-mysql-en.php" -O "$HACK_DIR/$adminer_dir/index.php"
        fi
    fi

    # Juice Shop
    local js_dir="${APP_DIR[juiceshop]}"
    if [ -d "$js_dir" ]; then
        local JS_URL=$(curl -s https://api.github.com/repos/juice-shop/juice-shop/releases/latest | grep -oP '"browser_download_url": "\K(.*_node20_linux_x64\.tgz)(?=")' | head -n 1)
        if [ -n "$JS_URL" ]; then
            rm -rf "$js_dir"/*
            wget -q "$JS_URL" -O /tmp/juiceshop.tgz
            tar -xf /tmp/juiceshop.tgz -C "$js_dir" --strip-components=1
            rm -f /tmp/juiceshop.tgz
            cd "$js_dir" || exit
            npm install --omit=dev >/dev/null 2>&1 || true
            cd - >/dev/null || true
        fi
    fi

    # WebGoat & WebWolf
    local wg_dir="${APP_DIR[webgoat]}"
    if [ -d "$wg_dir" ]; then
        local LATEST_JSON=$(curl -s https://api.github.com/repos/WebGoat/WebGoat/releases/latest)
        local WG_URL=$(echo "$LATEST_JSON" | grep -oP '"browser_download_url": "\K(.*webgoat-server.*\.jar)(?=")' | head -n 1)
        local WW_URL=$(echo "$LATEST_JSON" | grep -oP '"browser_download_url": "\K(.*webwolf.*\.jar)(?=")' | head -n 1)
        
        if [ -n "$WG_URL" ]; then
            rm -f "$wg_dir"/webgoat-*.jar
            wget -q "$WG_URL" -O "$wg_dir/webgoat.jar"
        fi
        
        if [ -n "$WW_URL" ]; then
            rm -f "$wg_dir"/webwolf-*.jar
            wget -q "$WW_URL" -O "$wg_dir/webwolf.jar"
        fi
    fi
}
_run "Pulling latest vulnerable apps" "_update_apps"

_update_engines() {
    export DEBIAN_FRONTEND=noninteractive
    
    local PACKAGES_TO_UPDATE=(
        "apache2" "nginx" "mariadb-server" 
        "php8.3" "nodejs" "temurin-21-jdk"
    )
    
    apt-get update -y
    apt-get upgrade -y "${PACKAGES_TO_UPDATE[@]}"
}
_run "Updating APT Engines & Source Codes" "_update_engines"

_fix_configs() {
    inject_db_creds "${DB_USER}" "${DB_PASS}"
    
    # Auto-Rebuild Databases after Git Pull
    curl -s -H "Host: bwapp.${DOMAIN}" "http://127.0.0.1:80/install.php?install=yes" >/dev/null || true
    curl -s -H "Host: mutillidae.${DOMAIN}" "http://127.0.0.1:80/set-up-database.php" >/dev/null || true
    
    local DVWA_TOKEN=$(curl -s -c /tmp/cookies.txt -H "Host: dvwa.${DOMAIN}" "http://127.0.0.1:80/setup.php" | grep "user_token" | awk -F"value='" '{print $2}' | awk -F"'" '{print $1}')
    curl -s -X POST -b /tmp/cookies.txt -d "create_db=Create+%2F+Reset+Database&user_token=${DVWA_TOKEN}" -H "Host: dvwa.${DOMAIN}" "http://127.0.0.1:80/setup.php" >/dev/null || true
}
_run "Re-applying configurations after update" "_fix_configs"

# ------------------------------------------------------------------------------
_hdr "SERVICE RELOAD"

_reload_services() {
    systemctl daemon-reload
    
    local SERVICES_TO_RESTART=(
        "apache2" "nginx" "mariadb"
        "juiceshop" "webgoat" "webwolf"
    )
    
    for s in "${SERVICES_TO_RESTART[@]}"; do
        systemctl restart "$s" || true
    done
}
_run "Restarting all Lab Services" "_reload_services"

echo ""
echo -e "${GRN}  [+] Updater Completed Successfully!${RST}"

tput cnorm
exit 0
