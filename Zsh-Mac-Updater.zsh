#!/bin/zsh

# Ultimate Mac Updater (Zsh)
# Made by Abdul Wahid
# Primary Use Case: Modern interactive use, high customization

echo "\e[36m=============================================\e[0m"
echo "\e[36m      STARTING FULL SYSTEM UPDATE PROCESS    \e[0m"
echo "\e[36m           Made by Abdul Wahid               \e[0m"
echo "\e[36m=============================================\e[0m"
echo ""

echo "\e[33m[1/4] Checking for macOS System Updates...\e[0m"
sudo softwareupdate -i -a
echo ""

echo "\e[33m[2/4] Updating Homebrew Packages...\e[0m"
if command -v brew &> /dev/null; then
    brew update
    brew upgrade
    brew cleanup
else
    echo "\e[90mHomebrew not found, skipping.\e[0m"
fi
echo ""

echo "\e[33m[3/4] Updating Global NPM Packages...\e[0m"
if command -v npm &> /dev/null; then
    npm update -g
else
    echo "\e[90mnpm not found. Skipping.\e[0m"
fi
echo ""

echo "\e[33m[4/4] Updating Global Ruby Gems...\e[0m"
if command -v gem &> /dev/null; then
    sudo gem update --system
    sudo gem update
else
    echo "\e[90mgem not found. Skipping.\e[0m"
fi
echo ""

echo "\e[32m=============================================\e[0m"
echo "\e[32m        ALL SYSTEM UPDATES COMPLETED!        \e[0m"
echo "\e[32m=============================================\e[0m"
echo ""
