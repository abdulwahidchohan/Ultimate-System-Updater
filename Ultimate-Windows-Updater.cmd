@echo off
color 0B

:: --- AUTOMATIC ADMINISTRATOR CHECK ---
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] Administrator privileges required. Restarting...
    powershell -Command "Start-Process cmd -ArgumentList '/c \"%~f0\"' -Verb RunAs"
    exit /b
)

echo =============================================
echo      STARTING FULL SYSTEM UPDATE PROCESS     
echo        Made by Abdul Wahid Chohan
echo =============================================
echo.

:: --- NETWORK BANDWIDTH PRIORITIZATION ---
echo [*] Allocating Maximum Network Bandwidth...
powershell -ExecutionPolicy Bypass -Command "Remove-NetQosPolicy -Name 'CMDUpdatePriority' -Confirm:$false -ErrorAction SilentlyContinue; New-NetQosPolicy -Name 'CMDUpdatePriority' -AppPathNameMatchCondition 'cmd.exe' -DSCPAction 46 -ErrorAction SilentlyContinue | Out-Null"
echo Network priority secured.
echo.

:: ============================================
:: STEP 1: Windows OS + Driver Updates
:: ============================================
echo [1/8] Checking for Windows ^& Driver Updates...
powershell -ExecutionPolicy Bypass -Command "if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) { Write-Host 'Installing PSWindowsUpdate module...' -ForegroundColor Yellow; Install-PackageProvider -Name NuGet -Force -ErrorAction SilentlyContinue | Out-Null; Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction SilentlyContinue; Install-Module -Name PSWindowsUpdate -Force -ErrorAction SilentlyContinue | Out-Null }; Import-Module PSWindowsUpdate; Install-WindowsUpdate -AcceptAll -IgnoreReboot"
echo.

:: ============================================
:: STEP 2: OEM Manufacturer Driver Updates
:: ============================================
echo [2/8] Detecting System Manufacturer and Updating OEM Drivers...
powershell -ExecutionPolicy Bypass -Command "$vendor = (Get-CimInstance Win32_ComputerSystem).Manufacturer; Write-Host '[*] Manufacturer: ' -NoNewline; Write-Host $vendor -ForegroundColor Cyan; if ($vendor -match 'Dell') { $dcu = \"$env:ProgramFiles\Dell\CommandUpdate\dcu-cli.exe\"; if (-not (Test-Path $dcu)) { $dcu = \"${env:ProgramFiles(x86)}\Dell\CommandUpdate\dcu-cli.exe\" }; if (-not (Test-Path $dcu)) { winget install Dell.CommandUpdate --silent --accept-package-agreements --accept-source-agreements; Start-Sleep 5; $dcu = \"$env:ProgramFiles\Dell\CommandUpdate\dcu-cli.exe\"; if (-not (Test-Path $dcu)) { $dcu = \"${env:ProgramFiles(x86)}\Dell\CommandUpdate\dcu-cli.exe\" } }; if (Test-Path $dcu) { Start-Process -FilePath $dcu -ArgumentList '/applyUpdates -silent -reboot=disable' -Wait; Write-Host 'Dell OEM updates completed.' -ForegroundColor Green } else { Write-Host 'Could not locate DCU.' -ForegroundColor Red } } elseif ($vendor -match 'Lenovo') { $su = \"${env:ProgramFiles(x86)}\Lenovo\System Update\tvsu.exe\"; if (-not (Test-Path $su)) { winget install Lenovo.SystemUpdate --silent --accept-package-agreements --accept-source-agreements; Start-Sleep 5 }; if (Test-Path $su) { Start-Process -FilePath $su -ArgumentList '/CM -search A -action INSTALL -includerebootpackages 1,3,4,5 -noreboot' -Wait; Write-Host 'Lenovo OEM updates completed.' -ForegroundColor Green } else { Write-Host 'Could not locate Lenovo System Update.' -ForegroundColor Red } } elseif ($vendor -match 'HP') { Write-Host 'HP detected. Please run HP Support Assistant manually.' -ForegroundColor Yellow } else { Write-Host 'No automated OEM updater configured. Windows Update will handle generic drivers.' -ForegroundColor DarkGray }"
echo.

:: ============================================
:: STEP 3: App Package Managers (Winget + Choco)
:: ============================================
echo [3/8] Updating Apps via Winget ^& Chocolatey...
echo [*] Running Winget upgrade...
winget upgrade --all --include-unknown --accept-package-agreements --accept-source-agreements
echo [*] Running Chocolatey upgrade...
choco upgrade all -y
echo.

:: ============================================
:: STEP 4: Node.js + Global NPM Packages
:: ============================================
echo [4/8] Updating Node.js ^& Global NPM Packages...
winget upgrade --id OpenJS.NodeJS.LTS -e --silent --accept-package-agreements --accept-source-agreements
winget upgrade --id OpenJS.NodeJS -e --silent --accept-package-agreements --accept-source-agreements
call npm update -g
echo.

:: ============================================
:: STEP 5: Python (PIP) Packages
:: ============================================
echo [5/8] Updating Global Python (PIP) Packages...
set PIP_DEFAULT_TIMEOUT=100
call pip install pip-review --upgrade
call pip-review --local --auto
echo.

:: ============================================
:: STEP 6: Ruby Gems
:: ============================================
echo [6/8] Updating Ruby Gems...
where gem >nul 2>&1
if %errorlevel% equ 0 (
    call gem update --system
    call gem update
) else (
    echo gem not found. Skipping.
)
echo.

:: ============================================
:: STEP 7: Rust / Cargo Packages
:: ============================================
echo [7/8] Updating Rust ^& Global Cargo Packages...
where cargo >nul 2>&1
if %errorlevel% equ 0 (
    call rustup update
    where cargo-install-update >nul 2>&1
    if %errorlevel% equ 0 (
        call cargo install-update -a
    ) else (
        echo [*] Install cargo-update for auto-updating cargo packages: cargo install cargo-update
    )
) else (
    echo cargo not found. Skipping.
)
echo.

:: ============================================
:: STEP 8: Windows Defender + WSL Update
:: ============================================
echo [8/8] Updating Windows Defender Signatures ^& WSL...
echo [*] Updating Windows Defender virus definitions...
powershell -ExecutionPolicy Bypass -Command "Update-MpSignature -ErrorAction SilentlyContinue; Write-Host 'Defender signatures updated.' -ForegroundColor Green"
echo [*] Updating Windows Subsystem for Linux (WSL)...
wsl --update >nul 2>&1 && echo WSL updated. || echo WSL not installed or not applicable. Skipping.
echo.

:: --- RESTORE NETWORK SETTINGS ---
echo [*] Restoring normal network bandwidth allocation...
powershell -ExecutionPolicy Bypass -Command "Remove-NetQosPolicy -Name 'CMDUpdatePriority' -Confirm:$false -ErrorAction SilentlyContinue"
echo.

echo =============================================
echo        ALL SYSTEM UPDATES COMPLETED!        
echo =============================================
echo.

:: --- REBOOT CHECK ---
echo [*] Checking if a system reboot is required...
powershell -ExecutionPolicy Bypass -Command "$reboot = $false; if (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending') { $reboot = $true }; if (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired') { $reboot = $true }; if ((Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' -Name 'PendingFileRenameOperations' -ErrorAction SilentlyContinue).PendingFileRenameOperations) { $reboot = $true }; if ($reboot) { exit 1 } else { exit 0 }"

if %errorlevel% equ 1 (
    color 0E
    echo.
    echo [!] WARNING: A system reboot is REQUIRED to finish installing updates.
    echo [!] Please save your work and restart your computer soon.
    echo.
) else (
    echo [+] No reboot required. You are good to go!
    echo.
)

pause
