#!/bin/zsh

# Ultimate Mac Updater (Zsh)
# Made by Abdul Wahid
# Primary Use Case: Modern interactive use, high customization

# --- AUTOMATIC ADMINISTRATOR CHECK ---
if [ "$EUID" -ne 0 ]; then
    printf "\033[33m[!] Administrator privileges required. Requesting sudo access...\033[0m\n"
    exec sudo zsh "$0" "$@"
    exit
fi

printf "\033[36m=============================================\033[0m\n"
printf "\033[36m      STARTING FULL SYSTEM UPDATE PROCESS    \033[0m\n"
printf "\033[36m           Made by Abdul Wahid               \033[0m\n"
printf "\033[36m=============================================\033[0m\n"
echo ""

printf "\033[33m[1/4] Checking for macOS System Updates...\033[0m\n"
sudo softwareupdate -i -a
echo ""

printf "\033[33m[2/4] Updating Homebrew Packages...\033[0m\n"
if command -v brew &> /dev/null; then
    brew update
    brew upgrade
    brew cleanup
else
    printf "\033[90mHomebrew not found, skipping.\033[0m\n"
fi
echo ""

printf "\033[33m[3/4] Updating Global NPM Packages...\033[0m\n"
if command -v npm &> /dev/null; then
    npm update -g
else
    printf "\033[90mnpm not found. Skipping.\033[0m\n"
fi
echo ""

printf "\033[33m[4/4] Updating Global Ruby Gems...\033[0m\n"
if command -v gem &> /dev/null; then
    sudo gem update --system
    sudo gem update
else
    printf "\033[90mgem not found. Skipping.\033[0m\n"
fi
echo ""

printf "\033[32m=============================================\033[0m\n"
printf "\033[32m        ALL SYSTEM UPDATES COMPLETED!        \033[0m\n"
printf "\033[32m=============================================\033[0m\n"
echo ""
