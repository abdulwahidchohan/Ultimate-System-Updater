#!/bin/bash

# Ultimate Linux Updater (Bash)
# Made by Abdul Wahid
# Primary Use Case: General purpose scripting and dev

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo ./Bash-Linux-Updater.sh)"
  exit
fi

echo -e "\e[36m=============================================\e[0m"
echo -e "\e[36m      STARTING FULL SYSTEM UPDATE PROCESS    \e[0m"
echo -e "\e[36m           Made by Abdul Wahid               \e[0m"
echo -e "\e[36m=============================================\e[0m"
echo ""

echo -e "\e[33m[1/4] Updating APT Packages (Debian/Ubuntu-based)...\e[0m"
if command -v apt &> /dev/null; then
    apt update -y && apt upgrade -y && apt autoremove -y
else
    echo -e "\e[90mapt not found. Skipping (not a Debian/Ubuntu system).\e[0m"
fi
echo ""

echo -e "\e[33m[2/4] Updating Snap Packages...\e[0m"
if command -v snap &> /dev/null; then
    snap refresh
else
    echo -e "\e[90msnap not found. Skipping.\e[0m"
fi
echo ""

echo -e "\e[33m[3/4] Updating Flatpak Packages...\e[0m"
if command -v flatpak &> /dev/null; then
    flatpak update -y
else
    echo -e "\e[90mflatpak not found. Skipping.\e[0m"
fi
echo ""

echo -e "\e[33m[4/4] Updating Global NPM Packages...\e[0m"
if command -v npm &> /dev/null; then
    npm update -g
else
    echo -e "\e[90mnpm not found. Skipping.\e[0m"
fi
echo ""

echo -e "\e[32m=============================================\e[0m"
echo -e "\e[32m        ALL SYSTEM UPDATES COMPLETED!        \e[0m"
echo -e "\e[32m=============================================\e[0m"
echo ""
