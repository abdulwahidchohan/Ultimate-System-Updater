@echo off
setlocal EnableExtensions EnableDelayedExpansion
color 0B

set "ELEVATED_ATTEMPTED=0"
set "NON_INTERACTIVE=0"

for %%A in (%*) do (
    if /I "%%~A"=="--elevated" set "ELEVATED_ATTEMPTED=1"
    if /I "%%~A"=="--non-interactive" set "NON_INTERACTIVE=1"
)

if "%NON_INTERACTIVE%"=="0" (
    for /f %%I in ('powershell -NoProfile -Command "[Console]::IsInputRedirected -or [Console]::IsOutputRedirected"') do set "REDIRECTED=%%I"
    if /I "!REDIRECTED!"=="True" set "NON_INTERACTIVE=1"
)

:: --- AUTOMATIC ADMINISTRATOR CHECK ---
net session >nul 2>&1
if %errorlevel% neq 0 (
    if "%ELEVATED_ATTEMPTED%"=="1" (
        echo [!] Administrator elevation was denied or failed. Exiting.
        exit /b 1
    )
    echo [!] Administrator privileges required. Restarting...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process cmd -ArgumentList '/c ""%~f0"" --elevated %*' -Verb RunAs"
    exit /b
)

echo =============================================
echo      STARTING FULL SYSTEM UPDATE PROCESS
echo        Made by Abdul Wahid Chohan
echo =============================================
echo.

:: --- NETWORK BANDWIDTH PRIORITIZATION ---
echo [*] Allocating Maximum Network Bandwidth...
powershell -ExecutionPolicy Bypass -Command "try { Remove-NetQosPolicy -Name 'CMDUpdatePriority' -Confirm:$false -ErrorAction SilentlyContinue; New-NetQosPolicy -Name 'CMDUpdatePriority' -AppPathNameMatchCondition 'cmd.exe' -DSCPAction 46 -ErrorAction Stop ^| Out-Null; Write-Host 'Network priority secured.' -ForegroundColor Green } catch { Write-Warning '[!] Could not apply QoS policy. Continuing without it.' }"
echo.

:: ============================================
:: STEP 1: Windows OS + Driver Updates
:: ============================================
echo [1/8] Checking for Windows ^& Driver Updates...
powershell -ExecutionPolicy Bypass -Command "try { if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) { Write-Host 'Installing PSWindowsUpdate module...' -ForegroundColor Yellow; Install-PackageProvider -Name NuGet -Force -ErrorAction Stop ^| Out-Null; Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction Stop; Install-Module -Name PSWindowsUpdate -Force -ErrorAction Stop ^| Out-Null }; Import-Module PSWindowsUpdate -ErrorAction Stop; if (Get-Command Install-WindowsUpdate -ErrorAction SilentlyContinue) { Install-WindowsUpdate -AcceptAll -IgnoreReboot } else { Write-Warning '[!] Install-WindowsUpdate not available. Skipping.' } } catch { Write-Warning ('[!] Windows update step failed: ' + $_.Exception.Message) }"
echo.

:: ============================================
:: STEP 2: OEM Manufacturer Driver Updates
:: ============================================
echo [2/8] Detecting System Manufacturer and Updating OEM Drivers...
powershell -ExecutionPolicy Bypass -Command "$vendor = (Get-CimInstance Win32_ComputerSystem).Manufacturer; Write-Host '[*] Manufacturer: ' -NoNewline; Write-Host $vendor -ForegroundColor Cyan; function Wait-Path([string]$path,[int]$timeout=60){$limit=(Get-Date).AddSeconds($timeout);while((Get-Date)-lt $limit){if(Test-Path $path){return $true};Start-Sleep -Seconds 2};return $false}; if ($vendor -match 'Dell') { $dcu = Join-Path $env:ProgramFiles 'Dell\CommandUpdate\dcu-cli.exe'; if (-not (Test-Path $dcu)) { $dcu = Join-Path ${env:ProgramFiles(x86)} 'Dell\CommandUpdate\dcu-cli.exe' }; if (-not (Test-Path $dcu)) { if (Get-Command winget -ErrorAction SilentlyContinue) { winget install Dell.CommandUpdate --silent --accept-package-agreements --accept-source-agreements; if (-not (Wait-Path $dcu 60)) { $dcu = Join-Path ${env:ProgramFiles(x86)} 'Dell\CommandUpdate\dcu-cli.exe' } } else { Write-Warning '[!] winget not found. Cannot auto-install Dell Command Update.' } }; if (Test-Path $dcu) { $proc = Start-Process -FilePath $dcu -ArgumentList '/applyUpdates -silent -reboot=disable' -Wait -PassThru; if ($proc.ExitCode -eq 0) { Write-Host 'Dell OEM updates completed.' -ForegroundColor Green } else { Write-Warning ('[!] Dell updater exited with code ' + $proc.ExitCode) } } else { Write-Warning '[!] Could not locate Dell Command Update.' } } elseif ($vendor -match 'Lenovo') { $su = Join-Path $env:ProgramFiles 'Lenovo\System Update\tvsu.exe'; if (-not (Test-Path $su)) { $su = Join-Path ${env:ProgramFiles(x86)} 'Lenovo\System Update\tvsu.exe' }; if (-not (Test-Path $su)) { if (Get-Command winget -ErrorAction SilentlyContinue) { winget install Lenovo.SystemUpdate --silent --accept-package-agreements --accept-source-agreements; if (-not (Wait-Path $su 60)) { $su = Join-Path ${env:ProgramFiles(x86)} 'Lenovo\System Update\tvsu.exe' } } else { Write-Warning '[!] winget not found. Cannot auto-install Lenovo System Update.' } }; if (Test-Path $su) { $proc = Start-Process -FilePath $su -ArgumentList '/CM -search A -action INSTALL -includerebootpackages 1,3,4,5 -noreboot' -Wait -PassThru; if ($proc.ExitCode -eq 0) { Write-Host 'Lenovo OEM updates completed.' -ForegroundColor Green } else { Write-Warning ('[!] Lenovo updater exited with code ' + $proc.ExitCode) } } else { Write-Warning '[!] Could not locate Lenovo System Update.' } } elseif ($vendor -match 'HP') { Write-Host 'HP detected. Please run HP Support Assistant manually (hp.com/support).' -ForegroundColor Yellow } else { Write-Host 'No automated OEM updater configured. Windows Update will handle generic drivers.' -ForegroundColor DarkGray }"
echo.

:: ============================================
:: STEP 3: App Package Managers (Winget + Choco)
:: ============================================
echo [3/8] Updating Apps via Winget ^& Chocolatey...
where winget >nul 2>&1
if %errorlevel% equ 0 (
    echo [*] Running Winget upgrade...
    winget upgrade --all --include-unknown --accept-package-agreements --accept-source-agreements
) else (
    echo [*] winget not found. Skipping Winget upgrades.
)

where choco >nul 2>&1
if %errorlevel% equ 0 (
    echo [*] Running Chocolatey upgrade...
    choco upgrade all -y
) else (
    echo [*] choco not found. Skipping Chocolatey upgrades.
)
echo.

:: ============================================
:: STEP 4: Node.js + Global NPM Packages
:: ============================================
echo [4/8] Updating Node.js ^& Global NPM Packages...
where winget >nul 2>&1
if %errorlevel% equ 0 (
    winget upgrade --id OpenJS.NodeJS.LTS -e --silent --accept-package-agreements --accept-source-agreements
    winget upgrade --id OpenJS.NodeJS -e --silent --accept-package-agreements --accept-source-agreements
) else (
    echo [*] winget not found. Skipping Node.js binary upgrades.
)

where npm >nul 2>&1
if %errorlevel% equ 0 (
    call npm update -g
) else (
    echo [*] npm not found. Skipping.
)
echo.

:: ============================================
:: STEP 5: Python (PIP) Packages
:: ============================================
echo [5/8] Updating Global Python (PIP) Packages...
echo [!] Aggressive mode enabled: updating all global Python packages.
where pip >nul 2>&1
if %errorlevel% equ 0 (
    set PIP_DEFAULT_TIMEOUT=100
    call pip install pip-review --upgrade
    where pip-review >nul 2>&1
    if !errorlevel! equ 0 (
        call pip-review --local --auto
    ) else (
        echo [*] pip-review not found after install attempt. Skipping auto-review.
    )
) else (
    echo [*] pip not found. Skipping.
)
echo.

:: ============================================
:: STEP 6: Ruby Gems
:: ============================================
echo [6/8] Updating Ruby Gems...
echo [!] Aggressive mode enabled: updating system RubyGems and all global gems.
where gem >nul 2>&1
if %errorlevel% equ 0 (
    call gem update --system
    call gem update
) else (
    echo [*] gem not found. Skipping.
)
echo.

:: ============================================
:: STEP 7: Rust / Cargo Packages
:: ============================================
echo [7/8] Updating Rust ^& Global Cargo Packages...
echo [!] Aggressive mode enabled: updating all globally installed cargo crates.
where rustup >nul 2>&1
if %errorlevel% equ 0 (
    call rustup update
    where cargo-install-update >nul 2>&1
    if %errorlevel% equ 0 (
        call cargo install-update -a
    ) else (
        echo [*] Install cargo-update for auto-updating cargo packages: cargo install cargo-update
    )
) else (
    echo [*] rustup not found. Skipping.
)
echo.

:: ============================================
:: STEP 8: Windows Defender + WSL Update
:: ============================================
echo [8/8] Updating Windows Defender Signatures ^& WSL...
echo [*] Updating Windows Defender virus definitions...
powershell -ExecutionPolicy Bypass -Command "if (Get-Command Update-MpSignature -ErrorAction SilentlyContinue) { Update-MpSignature -ErrorAction SilentlyContinue; Write-Host 'Defender signatures update attempted.' -ForegroundColor Green } else { Write-Host 'Defender update command unavailable. Skipping.' -ForegroundColor DarkGray }"

where wsl >nul 2>&1
if %errorlevel% equ 0 (
    echo [*] Updating Windows Subsystem for Linux (WSL)...
    wsl --update >nul 2>&1 && echo WSL updated. || echo WSL update failed.
) else (
    echo [*] WSL not found. Skipping.
)
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

if "%NON_INTERACTIVE%"=="0" (
    pause
)

endlocal