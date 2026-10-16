#!/bin/bash

# ============================================================
#  Ultimate Linux Updater (Bash) v2.0
#  Made by Abdul Wahid Chohan
#  Covers: apt/dnf/yum/pacman/zypper, Snap, Flatpak, Homebrew
#           npm/pnpm/yarn, pip/pipx/conda, Ruby, Rust, Go, ClamAV
# ============================================================

NON_INTERACTIVE=0
for arg in "$@"; do
    if [ "$arg" = "--non-interactive" ]; then
        NON_INTERACTIVE=1
    fi
done

# Auto-detect non-interactive (piped stdin/stdout)
if [ ! -t 0 ] || [ ! -t 1 ]; then
    NON_INTERACTIVE=1
fi

# ── Wait for APT/dpkg locks to clear ────────────────────────────────────────
wait_for_apt() {
    local retries=90
    while [ "$retries" -gt 0 ]; do
        if ! pgrep -x "apt"              >/dev/null 2>&1 &&
           ! pgrep -x "apt-get"          >/dev/null 2>&1 &&
           ! pgrep -x "dpkg"             >/dev/null 2>&1 &&
           ! pgrep -x "unattended-upgrade" >/dev/null 2>&1 &&
           ! pgrep -x "unattended-upgr"  >/dev/null 2>&1; then
            return 0
        fi
        sleep 2
        retries=$((retries - 1))
    done
    return 1
}

# ── Detect if pip needs --break-system-packages (PEP 668 enforcement) ────────
pip_install_pkg() {
    local pip_cmd="$1"
    shift
    if "$pip_cmd" install "$@" 2>&1 | grep -q "externally-managed-environment"; then
        "$pip_cmd" install --break-system-packages "$@"
    else
        "$pip_cmd" install "$@"
    fi
}

# ── Administrator check ──────────────────────────────────────────────────────
CURRENT_EUID="${EUID:-$(id -u)}"
if [ "$CURRENT_EUID" -ne 0 ]; then
    if ! command -v sudo >/dev/null 2>&1; then
        echo -e "\e[31m[!] sudo not found and root is required. Exiting.\e[0m"
        exit 1
    fi
    echo -e "\e[33m[!] Administrator privileges required. Restarting with sudo...\e[0m"
    exec sudo -E bash "$0" "$@" || {
        echo -e "\e[31m[!] Elevation failed. Exiting.\e[0m"
        exit 1
    }
fi

echo -e "\e[36m=============================================\e[0m"
echo -e "\e[36m      STARTING FULL SYSTEM UPDATE PROCESS    \e[0m"
echo -e "\e[36m       Made by Abdul Wahid Chohan v2.0       \e[0m"
echo -e "\e[36m=============================================\e[0m"
echo ""

# ════════════════════════════════════════════════════════════════════════════
# STEP 1/8 — OS Package Manager Updates
# ════════════════════════════════════════════════════════════════════════════
echo -e "\e[33m[1/8] Updating System Packages...\e[0m"

# Debian / Ubuntu / Linux Mint
if command -v apt >/dev/null 2>&1; then
    echo -e "\e[90m  [*] Waiting for apt/dpkg locks...\e[0m"
    if wait_for_apt; then
        echo -e "\e[90m  [*] Running apt update, full-upgrade & autoremove...\e[0m"
        apt update
        apt full-upgrade -y
        apt autoremove -y
        apt autoclean
    else
        echo -e "\e[31m  [!] apt/dpkg/unattended-upgrade is busy. Skipping apt.\e[0m"
    fi
fi

# Red Hat / Fedora / CentOS / Rocky / AlmaLinux
if command -v dnf >/dev/null 2>&1; then
    echo -e "\e[90m  [*] Running dnf upgrade...\e[0m"
    dnf upgrade -y --refresh
elif command -v yum >/dev/null 2>&1; then
    echo -e "\e[90m  [*] Running yum update...\e[0m"
    yum update -y
fi

# Arch Linux / Manjaro
if command -v pacman >/dev/null 2>&1; then
    echo -e "\e[90m  [*] Running pacman -Syu...\e[0m"
    pacman -Syu --noconfirm
fi

# openSUSE / SLES
if command -v zypper >/dev/null 2>&1; then
    echo -e "\e[90m  [*] Running zypper update...\e[0m"
    zypper update -y
fi

# Alpine Linux
if command -v apk >/dev/null 2>&1; then
    echo -e "\e[90m  [*] Running apk upgrade...\e[0m"
    apk update && apk upgrade
fi
echo ""

# ════════════════════════════════════════════════════════════════════════════
# STEP 2/8 — Universal Package Managers (Snap + Flatpak + Homebrew on Linux)
# ════════════════════════════════════════════════════════════════════════════
echo -e "\e[33m[2/8] Updating Snap, Flatpak & Homebrew...\e[0m"

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

# Homebrew on Linux (Linuxbrew)
if command -v brew >/dev/null 2>&1; then
    echo -e "\e[90m  [*] Updating Homebrew packages (Linux)...\e[0m"
    brew update
    brew upgrade
    brew cleanup
else
    echo -e "\e[90m  brew not found. Skipping.\e[0m"
fi
echo ""

# ════════════════════════════════════════════════════════════════════════════
# STEP 3/8 — Node.js & Global npm / pnpm / yarn Packages
# ════════════════════════════════════════════════════════════════════════════
echo -e "\e[33m[3/8] Updating Global Node.js Package Managers...\e[0m"

if command -v npm >/dev/null 2>&1; then
    echo -e "\e[90m  [*] Updating npm itself...\e[0m"
    npm install -g npm@latest
    echo -e "\e[90m  [*] Updating all global npm packages...\e[0m"
    npm update -g
else
    echo -e "\e[90m  npm not found. Skipping.\e[0m"
fi

if command -v pnpm >/dev/null 2>&1; then
    echo -e "\e[90m  [*] Updating pnpm global packages...\e[0m"
    pnpm update -g
fi

if command -v yarn >/dev/null 2>&1; then
    echo -e "\e[90m  [*] Updating yarn global packages...\e[0m"
    yarn global upgrade
fi
echo ""

# ════════════════════════════════════════════════════════════════════════════
# STEP 4/8 — Python (pip) + pipx + conda/mamba
# ════════════════════════════════════════════════════════════════════════════
echo -e "\e[33m[4/8] Updating Global Python Packages...\e[0m"
echo -e "\e[33m  [!] Upgrading all global Python packages (aggressive mode).\e[0m"

PIP_CMD=""
if command -v pip3 >/dev/null 2>&1; then
    PIP_CMD="pip3"
elif command -v pip >/dev/null 2>&1; then
    PIP_CMD="pip"
fi

if [ -n "$PIP_CMD" ]; then
    echo -e "\e[90m  [*] Upgrading pip, setuptools & wheel...\e[0m"
    pip_install_pkg "$PIP_CMD" --upgrade pip setuptools wheel

    echo -e "\e[90m  [*] Installing/upgrading pip-review...\e[0m"
    pip_install_pkg "$PIP_CMD" pip-review --upgrade

    if command -v pip-review >/dev/null 2>&1; then
        echo -e "\e[90m  [*] Upgrading all outdated packages...\e[0m"
        pip-review --local --auto
    else
        echo -e "\e[90m  pip-review not found after install. Skipping auto-review.\e[0m"
    fi
else
    echo -e "\e[90m  pip not found. Skipping.\e[0m"
fi

if command -v pipx >/dev/null 2>&1; then
    echo -e "\e[90m  [*] Upgrading pipx global tools...\e[0m"
    pipx upgrade-all
fi

if command -v conda >/dev/null 2>&1; then
    echo -e "\e[90m  [*] Updating conda base environment...\e[0m"
    conda update -n base -c defaults conda -y
    conda update --all -y
elif command -v mamba >/dev/null 2>&1; then
    echo -e "\e[90m  [*] Updating mamba environment...\e[0m"
    mamba update --all -y
fi
echo ""

# ════════════════════════════════════════════════════════════════════════════
# STEP 5/8 — Ruby Gems
# ════════════════════════════════════════════════════════════════════════════
echo -e "\e[33m[5/8] Updating Ruby Gems...\e[0m"

if command -v gem >/dev/null 2>&1; then
    gem update --system
    gem update
    gem cleanup
    echo -e "\e[32m  Ruby gems updated and cleaned up.\e[0m"
else
    echo -e "\e[90m  gem not found. Skipping.\e[0m"
fi
echo ""

# ════════════════════════════════════════════════════════════════════════════
# STEP 6/8 — Rust / Cargo
# ════════════════════════════════════════════════════════════════════════════
echo -e "\e[33m[6/8] Updating Rust & Global Cargo Packages...\e[0m"

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

# ════════════════════════════════════════════════════════════════════════════
# STEP 7/8 — Go Toolchain
# ════════════════════════════════════════════════════════════════════════════
echo -e "\e[33m[7/8] Updating Go Toolchain...\e[0m"

if command -v go >/dev/null 2>&1; then
    echo -e "\e[90m  Current: $(go version)\e[0m"
    # Update Go itself via package manager if available
    if command -v apt >/dev/null 2>&1 && apt-cache show golang-go >/dev/null 2>&1; then
        apt install --only-upgrade -y golang-go 2>/dev/null || true
    elif command -v dnf >/dev/null 2>&1; then
        dnf upgrade -y golang 2>/dev/null || true
    elif command -v brew >/dev/null 2>&1; then
        brew upgrade go 2>/dev/null || true
    else
        echo -e "\e[90m  Visit https://go.dev/dl/ to update Go manually.\e[0m"
    fi
else
    echo -e "\e[90m  Go not found. Skipping.\e[0m"
fi
echo ""

# ════════════════════════════════════════════════════════════════════════════
# STEP 8/8 — Antivirus Signature Update (ClamAV)
# ════════════════════════════════════════════════════════════════════════════
echo -e "\e[33m[8/8] Updating Antivirus Signatures (ClamAV)...\e[0m"

if command -v freshclam >/dev/null 2>&1; then
    freshclam
    echo -e "\e[32m  ClamAV signatures updated.\e[0m"
else
    echo -e "\e[90m  freshclam (ClamAV) not found. Skipping.\e[0m"
fi
echo ""

echo -e "\e[32m=============================================\e[0m"
echo -e "\e[32m        ALL SYSTEM UPDATES COMPLETED!        \e[0m"
echo -e "\e[32m=============================================\e[0m"
echo ""

# ── Reboot check ─────────────────────────────────────────────────────────────
echo -e "\e[90m[*] Checking if a system reboot is required...\e[0m"
REBOOT=0

# Ubuntu/Debian
if [ -f /var/run/reboot-required ]; then
    REBOOT=1
fi

# RHEL/Fedora
if command -v needs-restarting >/dev/null 2>&1; then
    needs-restarting -r >/dev/null 2>&1 || REBOOT=1
fi

# needrestart (Ubuntu enhanced)
if command -v needrestart >/dev/null 2>&1; then
    needrestart -r a 2>/dev/null || true
fi

if [ "$REBOOT" -eq 1 ]; then
    echo -e "\e[33m[!] WARNING: A system reboot is REQUIRED to finish installing updates.\e[0m"
    echo -e "\e[33m[!] Please save your work and restart your computer soon.\e[0m"
else
    echo -e "\e[32m[+] No reboot required. You are good to go!\e[0m"
fi
echo ""

if [ "$NON_INTERACTIVE" -eq 0 ]; then
    read -rp "Press Enter to exit..."
fi
