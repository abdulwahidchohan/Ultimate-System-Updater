#!/bin/bash

# Ultimate Linux Updater (Bash)
# Made by Abdul Wahid Chohan
# Primary Use Case: General purpose scripting and dev

NON_INTERACTIVE=0
for arg in "$@"; do
    if [ "$arg" = "--non-interactive" ]; then
        NON_INTERACTIVE=1
    fi
done

if [ ! -t 0 ] || [ ! -t 1 ]; then
    NON_INTERACTIVE=1
fi

wait_for_apt_processes() {
    local retries=60
    while [ "$retries" -gt 0 ]; do
        if ! pgrep -x apt >/dev/null 2>&1 && ! pgrep -x apt-get >/dev/null 2>&1 && ! pgrep -x dpkg >/dev/null 2>&1; then
            return 0
        fi
        sleep 2
        retries=$((retries - 1))
    done
    return 1
}

# --- AUTOMATIC ADMINISTRATOR CHECK ---
CURRENT_EUID="${EUID:-$(id -u)}"
if [ "$CURRENT_EUID" -ne 0 ]; then
    if ! command -v sudo >/dev/null 2>&1; then
        echo -e "\e[31m[!] sudo not found and root privileges are required. Exiting.\e[0m"
        exit 1
    fi
    echo -e "\e[33m[!] Administrator privileges required. Restarting with sudo...\e[0m"
    exec sudo -E bash "$0" "$@" || {
        echo -e "\e[31m[!] Elevation failed or was denied. Exiting.\e[0m"
        exit 1
    }
fi

echo -e "\e[36m=============================================\e[0m"
echo -e "\e[36m      STARTING FULL SYSTEM UPDATE PROCESS    \e[0m"
echo -e "\e[36m       Made by Abdul Wahid Chohan            \e[0m"
echo -e "\e[36m=============================================\e[0m"
echo ""

# ============================================
# STEP 1: OS Package Manager Updates (all distros)
# ============================================
echo -e "\e[33m[1/7] Updating System Packages...\e[0m"
# Debian / Ubuntu
if command -v apt >/dev/null 2>&1; then
    echo -e "\e[90m  [*] Running apt update & upgrade...\e[0m"
    if wait_for_apt_processes; then
        apt update && apt upgrade -y && apt autoremove -y
    else
        echo -e "\e[31m[!] apt/dpkg appears busy. Skipping apt updates this run.\e[0m"
    fi
fi

# Red Hat / Fedora / CentOS
if command -v dnf >/dev/null 2>&1; then
    echo -e "\e[90m  [*] Running dnf upgrade...\e[0m"
    dnf upgrade -y
elif command -v yum >/dev/null 2>&1; then
    echo -e "\e[90m  [*] Running yum update...\e[0m"
    yum update -y
fi

# Arch Linux
if command -v pacman >/dev/null 2>&1; then
    echo -e "\e[90m  [*] Running pacman -Syu (aggressive mode)...\e[0m"
    pacman -Syu --noconfirm
fi

# openSUSE
if command -v zypper >/dev/null 2>&1; then
    echo -e "\e[90m  [*] Running zypper update...\e[0m"
    zypper update -y
fi
echo ""

# ============================================
# STEP 2: Universal Package Managers (Snap + Flatpak)
# ============================================
echo -e "\e[33m[2/7] Updating Snap & Flatpak Packages...\e[0m"
if command -v snap >/dev/null 2>&1; then
    echo -e "\e[90m  [*] Refreshing Snap packages...\e[0m"
    snap refresh
else
    echo -e "\e[90m  snap not found. Skipping.\e[0m"
fi

if command -v flatpak >/dev/null 2>&1; then
    echo -e "\e[90m  [*] Updating Flatpak packages...\e[0m"
    flatpak update -y
else
    echo -e "\e[90m  flatpak not found. Skipping.\e[0m"
fi
echo ""

# ============================================
# STEP 3: Node.js & Global NPM Packages
# ============================================
echo -e "\e[33m[3/7] Updating Global NPM Packages...\e[0m"
if command -v npm >/dev/null 2>&1; then
    npm update -g
else
    echo -e "\e[90m  npm not found. Skipping.\e[0m"
fi
echo ""

# ============================================
# STEP 4: Python (PIP) Packages
# ============================================
echo -e "\e[33m[4/7] Updating Global Python (PIP) Packages...\e[0m"
echo -e "\e[33m  [!] Aggressive mode enabled: updating all global Python packages.\e[0m"
if command -v pip3 >/dev/null 2>&1; then
    pip3 install pip-review --upgrade
    if command -v pip-review >/dev/null 2>&1; then
        pip-review --local --auto
    else
        echo -e "\e[90m  pip-review not found after install attempt. Skipping auto-review.\e[0m"
    fi
elif command -v pip >/dev/null 2>&1; then
    pip install pip-review --upgrade
    if command -v pip-review >/dev/null 2>&1; then
        pip-review --local --auto
    else
        echo -e "\e[90m  pip-review not found after install attempt. Skipping auto-review.\e[0m"
    fi
else
    echo -e "\e[90m  pip not found. Skipping.\e[0m"
fi
echo ""

# ============================================
# STEP 5: Ruby Gems
# ============================================
echo -e "\e[33m[5/7] Updating Ruby Gems...\e[0m"
echo -e "\e[33m  [!] Aggressive mode enabled: updating system RubyGems and all global gems.\e[0m"
if command -v gem >/dev/null 2>&1; then
    gem update --system
    gem update
else
    echo -e "\e[90m  gem not found. Skipping.\e[0m"
fi
echo ""

# ============================================
# STEP 6: Rust / Cargo Packages
# ============================================
echo -e "\e[33m[6/7] Updating Rust & Global Cargo Packages...\e[0m"
echo -e "\e[33m  [!] Aggressive mode enabled: updating all globally installed cargo crates.\e[0m"
if command -v rustup >/dev/null 2>&1; then
    rustup update
    if command -v cargo-install-update >/dev/null 2>&1; then
        cargo install-update -a
    else
        echo -e "\e[90m  Tip: Run 'cargo install cargo-update' to enable auto-updating cargo packages.\e[0m"
    fi
else
    echo -e "\e[90m  rustup/cargo not found. Skipping.\e[0m"
fi
echo ""

# ============================================
# STEP 7: Antivirus Signature Update (ClamAV)
# ============================================
echo -e "\e[33m[7/7] Updating Antivirus Signatures (ClamAV)...\e[0m"
if command -v freshclam >/dev/null 2>&1; then
    freshclam
else
    echo -e "\e[90m  freshclam (ClamAV) not found. Skipping.\e[0m"
fi
echo ""

echo -e "\e[32m=============================================\e[0m"
echo -e "\e[32m        ALL SYSTEM UPDATES COMPLETED!        \e[0m"
echo -e "\e[32m=============================================\e[0m"
echo ""

# --- REBOOT CHECK ---
echo -e "\e[90m[*] Checking if a system reboot is required...\e[0m"
reboot_required=0
if [ -f /var/run/reboot-required ]; then
    reboot_required=1
fi

if command -v needs-restarting >/dev/null 2>&1; then
    needs-restarting -r >/dev/null 2>&1 || reboot_required=1
fi

if [ "$reboot_required" -eq 1 ]; then
    echo -e "\e[33m[!] WARNING: A system reboot is REQUIRED to finish installing updates.\e[0m"
    echo -e "\e[33m[!] Please save your work and restart your computer soon.\e[0m"
else
    echo -e "\e[32m[+] No reboot required. You are good to go!\e[0m"
fi
echo ""

if [ "$NON_INTERACTIVE" -eq 0 ]; then
    read -p "Press Enter to exit..."
fi