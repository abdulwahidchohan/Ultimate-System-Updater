#!/bin/zsh

# Ultimate Mac Updater (Zsh)
# Made by Abdul Wahid Chohan
# Primary Use Case: Modern interactive use, high customization

# --- AUTOMATIC ADMINISTRATOR CHECK ---
if [ "$EUID" -ne 0 ]; then
    printf "\033[33m[!] Administrator privileges required. Requesting sudo access...\033[0m\n"
    exec sudo zsh "$0" "$@"
    exit
fi

printf "\033[36m=============================================\033[0m\n"
printf "\033[36m      STARTING FULL SYSTEM UPDATE PROCESS    \033[0m\n"
printf "\033[36m       Made by Abdul Wahid Chohan            \033[0m\n"
printf "\033[36m=============================================\033[0m\n"
echo ""

# ============================================
# STEP 1: macOS System Updates
# ============================================
printf "\033[33m[1/7] Checking for macOS System Updates...\033[0m\n"
softwareupdate -i -a
echo ""

# ============================================
# STEP 2: Homebrew Package Manager
# ============================================
printf "\033[33m[2/7] Updating Homebrew Packages...\033[0m\n"
if command -v brew &> /dev/null; then
    printf "\033[90m  [*] Running brew update & upgrade...\033[0m\n"
    brew update
    brew upgrade
    brew cleanup
else
    printf "\033[90m  Homebrew not found. Install from https://brew.sh\033[0m\n"
fi
echo ""

# ============================================
# STEP 3: Mac App Store Apps (via mas-cli)
# ============================================
printf "\033[33m[3/7] Updating Mac App Store Apps...\033[0m\n"
if command -v mas &> /dev/null; then
    mas upgrade
else
    printf "\033[90m  mas not found. Install via Homebrew: brew install mas\033[0m\n"
fi
echo ""

# ============================================
# STEP 4: Node.js & Global NPM Packages
# ============================================
printf "\033[33m[4/7] Updating Global NPM Packages...\033[0m\n"
if command -v npm &> /dev/null; then
    npm update -g
else
    printf "\033[90m  npm not found. Skipping.\033[0m\n"
fi
echo ""

# ============================================
# STEP 5: Python (PIP) Packages
# ============================================
printf "\033[33m[5/7] Updating Global Python (PIP) Packages...\033[0m\n"
if command -v pip3 &> /dev/null; then
    pip3 install pip-review --upgrade
    pip-review --local --auto
elif command -v pip &> /dev/null; then
    pip install pip-review --upgrade
    pip-review --local --auto
else
    printf "\033[90m  pip not found. Skipping.\033[0m\n"
fi
echo ""

# ============================================
# STEP 6: Ruby Gems
# ============================================
printf "\033[33m[6/7] Updating Ruby Gems...\033[0m\n"
if command -v gem &> /dev/null; then
    gem update --system
    gem update
else
    printf "\033[90m  gem not found. Skipping.\033[0m\n"
fi
echo ""

# ============================================
# STEP 7: Rust / Cargo Packages
# ============================================
printf "\033[33m[7/7] Updating Rust & Global Cargo Packages...\033[0m\n"
if command -v rustup &> /dev/null; then
    rustup update
    if command -v cargo-install-update &> /dev/null; then
        cargo install-update -a
    else
        printf "\033[90m  Tip: Run 'cargo install cargo-update' to enable auto-updating cargo packages.\033[0m\n"
    fi
else
    printf "\033[90m  rustup/cargo not found. Skipping.\033[0m\n"
fi
echo ""

printf "\033[32m=============================================\033[0m\n"
printf "\033[32m        ALL SYSTEM UPDATES COMPLETED!        \033[0m\n"
printf "\033[32m=============================================\033[0m\n"
echo ""

# --- REBOOT CHECK ---
printf "\033[90m[*] Checking if a system reboot is required...\033[0m\n"
if [ -f /var/run/reboot-required ]; then
    printf "\033[33m[!] WARNING: A system reboot is REQUIRED to finish installing updates.\033[0m\n"
    printf "\033[33m[!] Please save your work and restart your computer soon.\033[0m\n"
else
    printf "\033[32m[+] No reboot required. You are good to go!\033[0m\n"
fi
echo ""
read "?Press Enter to exit..."
