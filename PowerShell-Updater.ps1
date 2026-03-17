<#
.SYNOPSIS
    Ultimate System Updater (PowerShell)
.DESCRIPTION
    Full system update script for Windows via PowerShell.
    Made by Abdul Wahid Chohan
#>

# --- AUTOMATIC ADMINISTRATOR CHECK ---
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "[!] Administrator privileges required. Requesting elevation..."
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "     STARTING FULL SYSTEM UPDATE PROCESS    " -ForegroundColor Cyan
Write-Host "        Made by Abdul Wahid Chohan          " -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# --- NETWORK BANDWIDTH PRIORITIZATION ---
Write-Host "[*] Allocating Maximum Network Bandwidth..." -ForegroundColor Gray
Remove-NetQosPolicy -Name 'PSUpdatePriority' -Confirm:$false -ErrorAction SilentlyContinue
New-NetQosPolicy -Name 'PSUpdatePriority' -AppPathNameMatchCondition 'powershell.exe' -DSCPAction 46 -ErrorAction SilentlyContinue | Out-Null
Write-Host "Network priority secured."
Write-Host ""

# ============================================
# STEP 1: Windows OS & Driver Updates
# ============================================
Write-Host "[1/8] Checking for Windows & Driver Updates..." -ForegroundColor Yellow
if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
    Write-Host "  Installing PSWindowsUpdate module..." -ForegroundColor Gray
    Install-PackageProvider -Name NuGet -Force -ErrorAction SilentlyContinue | Out-Null
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction SilentlyContinue
    Install-Module -Name PSWindowsUpdate -Force -ErrorAction SilentlyContinue | Out-Null
}
Import-Module PSWindowsUpdate
Install-WindowsUpdate -AcceptAll -IgnoreReboot
Write-Host ""

# ============================================
# STEP 2: OEM Manufacturer Driver Updates
# ============================================
Write-Host "[2/8] Detecting Manufacturer & Updating OEM Drivers..." -ForegroundColor Yellow
$vendor = (Get-CimInstance Win32_ComputerSystem).Manufacturer
Write-Host "  Manufacturer: $vendor" -ForegroundColor Cyan
if ($vendor -match 'Dell') {
    $dcu = "$env:ProgramFiles\Dell\CommandUpdate\dcu-cli.exe"
    if (-not (Test-Path $dcu)) { $dcu = "${env:ProgramFiles(x86)}\Dell\CommandUpdate\dcu-cli.exe" }
    if (-not (Test-Path $dcu)) { winget install Dell.CommandUpdate --silent --accept-package-agreements --accept-source-agreements; Start-Sleep 5 }
    if (Test-Path $dcu) { Start-Process -FilePath $dcu -ArgumentList '/applyUpdates -silent -reboot=disable' -Wait; Write-Host "  Dell OEM updates completed." -ForegroundColor Green }
} elseif ($vendor -match 'Lenovo') {
    $su = "${env:ProgramFiles(x86)}\Lenovo\System Update\tvsu.exe"
    if (-not (Test-Path $su)) { winget install Lenovo.SystemUpdate --silent --accept-package-agreements --accept-source-agreements; Start-Sleep 5 }
    if (Test-Path $su) { Start-Process -FilePath $su -ArgumentList '/CM -search A -action INSTALL -includerebootpackages 1,3,4,5 -noreboot' -Wait; Write-Host "  Lenovo OEM updates completed." -ForegroundColor Green }
} elseif ($vendor -match 'HP') {
    Write-Host "  HP detected. Please run HP Support Assistant manually." -ForegroundColor Yellow
} else {
    Write-Host "  No OEM updater configured. Windows Update handles generic drivers." -ForegroundColor DarkGray
}
Write-Host ""

# ============================================
# STEP 3: App Package Managers (Winget + Choco)
# ============================================
Write-Host "[3/8] Updating Apps via Winget & Chocolatey..." -ForegroundColor Yellow
Write-Host "  [*] Running Winget upgrade..." -ForegroundColor Gray
winget upgrade --all --include-unknown --accept-package-agreements --accept-source-agreements
Write-Host "  [*] Running Chocolatey upgrade..." -ForegroundColor Gray
if (Get-Command choco -ErrorAction SilentlyContinue) { choco upgrade all -y } else { Write-Host "  choco not found. Skipping." -ForegroundColor DarkGray }
Write-Host ""

# ============================================
# STEP 4: Node.js & Global NPM Packages
# ============================================
Write-Host "[4/8] Updating Node.js & Global NPM Packages..." -ForegroundColor Yellow
winget upgrade --id OpenJS.NodeJS.LTS -e --silent --accept-package-agreements --accept-source-agreements
winget upgrade --id OpenJS.NodeJS -e --silent --accept-package-agreements --accept-source-agreements
if (Get-Command npm -ErrorAction SilentlyContinue) { npm update -g } else { Write-Host "  npm not found. Skipping." -ForegroundColor DarkGray }
Write-Host ""

# ============================================
# STEP 5: Python (PIP) Packages
# ============================================
Write-Host "[5/8] Updating Global Python (PIP) Packages..." -ForegroundColor Yellow
if (Get-Command pip -ErrorAction SilentlyContinue) {
    pip install pip-review --upgrade
    pip-review --local --auto
} else { Write-Host "  pip not found. Skipping." -ForegroundColor DarkGray }
Write-Host ""

# ============================================
# STEP 6: Ruby Gems
# ============================================
Write-Host "[6/8] Updating Ruby Gems..." -ForegroundColor Yellow
if (Get-Command gem -ErrorAction SilentlyContinue) {
    gem update --system
    gem update
} else { Write-Host "  gem not found. Skipping." -ForegroundColor DarkGray }
Write-Host ""

# ============================================
# STEP 7: Rust / Cargo Packages
# ============================================
Write-Host "[7/8] Updating Rust & Global Cargo Packages..." -ForegroundColor Yellow
if (Get-Command rustup -ErrorAction SilentlyContinue) {
    rustup update
    if (Get-Command cargo-install-update -ErrorAction SilentlyContinue) {
        cargo install-update -a
    } else {
        Write-Host "  Tip: Run 'cargo install cargo-update' to enable auto-updating cargo packages." -ForegroundColor DarkGray
    }
} else { Write-Host "  cargo/rustup not found. Skipping." -ForegroundColor DarkGray }
Write-Host ""

# ============================================
# STEP 8: Windows Defender + WSL Update
# ============================================
Write-Host "[8/8] Updating Windows Defender Signatures & WSL..." -ForegroundColor Yellow
Write-Host "  [*] Updating Defender virus definitions..." -ForegroundColor Gray
Update-MpSignature -ErrorAction SilentlyContinue
Write-Host "  Defender signatures updated." -ForegroundColor Green
Write-Host "  [*] Updating WSL..." -ForegroundColor Gray
wsl --update 2>$null
Write-Host ""

# --- RESTORE NETWORK SETTINGS ---
Write-Host "[*] Restoring normal network bandwidth allocation..." -ForegroundColor Gray
Remove-NetQosPolicy -Name 'PSUpdatePriority' -Confirm:$false -ErrorAction SilentlyContinue
Write-Host ""

Write-Host "=============================================" -ForegroundColor Green
Write-Host "        ALL SYSTEM UPDATES COMPLETED!        " -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green
Write-Host ""

# --- REBOOT CHECK ---
Write-Host "[*] Checking if a system reboot is required..." -ForegroundColor Gray
$reboot = $false
if (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending') { $reboot = $true }
if (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired') { $reboot = $true }
if ((Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' -Name 'PendingFileRenameOperations' -ErrorAction SilentlyContinue).PendingFileRenameOperations) { $reboot = $true }

if ($reboot) {
    Write-Host ""
    Write-Host "[!] WARNING: A system reboot is REQUIRED to finish installing updates." -ForegroundColor Yellow
    Write-Host "[!] Please save your work and restart your computer soon." -ForegroundColor Yellow
} else {
    Write-Host "[+] No reboot required. You are good to go!" -ForegroundColor Green
}
Write-Host ""
Read-Host "Press Enter to exit"
