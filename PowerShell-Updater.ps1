<#
.SYNOPSIS
Ultimate System Updater (PowerShell)
.DESCRIPTION
Advanced automation script to update Windows systems and cross-platform setups.
Primary Use Case: Advanced automation, system admin
#>
# --- AUTOMATIC ADMINISTRATOR CHECK ---
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Administrator privileges required. Restarting script as Admin..."
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "      STARTING FULL SYSTEM UPDATE PROCESS    " -ForegroundColor Cyan
Write-Host "           Made by Abdul Wahid               " -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# 1. Update Windows OS and Drivers
Write-Host "[1/4] Checking for Windows & Driver Updates..." -ForegroundColor Yellow
if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
    Write-Host "Installing PSWindowsUpdate module..." -ForegroundColor Gray
    Install-PackageProvider -Name NuGet -Force -ErrorAction SilentlyContinue | Out-Null
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction SilentlyContinue
    Install-Module -Name PSWindowsUpdate -Force -ErrorAction SilentlyContinue | Out-Null
}
Import-Module PSWindowsUpdate
Install-WindowsUpdate -AcceptAll -IgnoreReboot
Write-Host ""

# 2. Update Standard Windows Apps via Winget
Write-Host "[2/4] Updating Desktop & Store Apps via Winget..." -ForegroundColor Yellow
winget upgrade --all --include-unknown --accept-package-agreements --accept-source-agreements
Write-Host ""

# 3. Update Node.js Packages
Write-Host "[3/4] Updating Global NPM Packages..." -ForegroundColor Yellow
if (Get-Command npm -ErrorAction SilentlyContinue) {
    npm update -g
} else {
    Write-Host "npm not found. Skipping." -ForegroundColor DarkGray
}
Write-Host ""

# 4. Update Python Packages
Write-Host "[4/4] Updating Global Python (PIP) Packages..." -ForegroundColor Yellow
if (Get-Command pip -ErrorAction SilentlyContinue) {
    pip install pip-review --upgrade
    pip-review --local --auto
} else {
    Write-Host "pip not found. Skipping." -ForegroundColor DarkGray
}
Write-Host ""

Write-Host "=============================================" -ForegroundColor Green
Write-Host "        ALL SYSTEM UPDATES COMPLETED!        " -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green
Write-Host ""

Read-Host "Press Enter to exit"
