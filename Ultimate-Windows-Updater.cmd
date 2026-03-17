@echo off
color 0B

:: --- AUTOMATIC ADMINISTRATOR CHECK ---
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Administrator privileges required. Restarting...
    powershell -Command "Start-Process cmd -ArgumentList '/c \"%~f0\"' -Verb RunAs"
    exit /b
)

echo =============================================
echo      STARTING FULL SYSTEM UPDATE PROCESS     
echo           Made by Abdul Wahid
echo =============================================
echo.

:: --- NETWORK BANDWIDTH PRIORITIZATION ---
echo [*] Allocating Maximum Network Bandwidth...
powershell -ExecutionPolicy Bypass -Command "Remove-NetQosPolicy -Name 'CMDUpdatePriority' -Confirm:$false -ErrorAction SilentlyContinue; New-NetQosPolicy -Name 'CMDUpdatePriority' -AppPathNameMatchCondition 'cmd.exe' -DSCPAction 46 -ErrorAction SilentlyContinue | Out-Null"
echo Network priority secured.
echo.

:: 1. Update Windows OS and Drivers
echo [1/6] Checking for Windows ^& Driver Updates...
powershell -ExecutionPolicy Bypass -Command "if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) { Write-Host 'Installing PSWindowsUpdate module (One-time setup)...' -ForegroundColor Yellow; Install-PackageProvider -Name NuGet -Force -ErrorAction SilentlyContinue | Out-Null; Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction SilentlyContinue; Install-Module -Name PSWindowsUpdate -Force -ErrorAction SilentlyContinue | Out-Null }; Import-Module PSWindowsUpdate; Install-WindowsUpdate -AcceptAll -IgnoreReboot"
echo.

:: 2. Update Manufacturer-Specific Drivers (Smart Check)
echo [2/6] Detecting System Manufacturer and Updating OEM Drivers...
powershell -ExecutionPolicy Bypass -Command "$vendor = (Get-CimInstance Win32_ComputerSystem).Manufacturer; Write-Host '[*] System Manufacturer Detected: ' -NoNewline; Write-Host $vendor -ForegroundColor Cyan; if ($vendor -match 'Dell') { $dcu = \"$env:ProgramFiles\Dell\CommandUpdate\dcu-cli.exe\"; if (-not (Test-Path $dcu)) { $dcu = \"${env:ProgramFiles(x86)}\Dell\CommandUpdate\dcu-cli.exe\" }; if (-not (Test-Path $dcu)) { Write-Host 'Dell Command Update missing. Installing via Winget...' -ForegroundColor Yellow; winget install Dell.CommandUpdate --silent --accept-package-agreements --accept-source-agreements; Start-Sleep 5; $dcu = \"$env:ProgramFiles\Dell\CommandUpdate\dcu-cli.exe\"; if (-not (Test-Path $dcu)) { $dcu = \"${env:ProgramFiles(x86)}\Dell\CommandUpdate\dcu-cli.exe\" }; }; if (Test-Path $dcu) { Write-Host 'Running Dell Command Update...' -ForegroundColor Yellow; Start-Process -FilePath $dcu -ArgumentList '/applyUpdates -silent -reboot=disable' -Wait; Write-Host 'Dell OEM updates completed.' -ForegroundColor Green; } else { Write-Host 'Could not locate DCU.' -ForegroundColor Red; } } elseif ($vendor -match 'Lenovo') { $su = \"${env:ProgramFiles(x86)}\Lenovo\System Update\tvsu.exe\"; if (-not (Test-Path $su)) { Write-Host 'Lenovo System Update missing. Installing via Winget...' -ForegroundColor Yellow; winget install Lenovo.SystemUpdate --silent --accept-package-agreements --accept-source-agreements; Start-Sleep 5; }; if (Test-Path $su) { Write-Host 'Running Lenovo System Update...' -ForegroundColor Yellow; Start-Process -FilePath $su -ArgumentList '/CM -search A -action INSTALL -includerebootpackages 1,3,4,5 -noreboot' -Wait; Write-Host 'Lenovo OEM updates completed.' -ForegroundColor Green; } else { Write-Host 'Could not locate Lenovo System Update.' -ForegroundColor Red; } } elseif ($vendor -match 'HP') { Write-Host 'HP System detected. Please run HP Support Assistant from your Start Menu to check for OEM firmware.' -ForegroundColor Yellow; } else { Write-Host 'No automated OEM updater configured for your brand. Generic drivers will be handled by Windows Update.' -ForegroundColor DarkGray; }"
echo.

:: 3. Update Standard Windows Apps
echo [3/6] Updating Windows Desktop ^& Store Apps via Winget...
winget upgrade --all --include-unknown --accept-package-agreements --accept-source-agreements
echo.

:: 4. Update Chocolatey Packages
echo [4/6] Updating Chocolatey Packages...
choco upgrade all -y
echo.

:: 5. Update Node.js Packages
echo [5/6] Updating Node.js Core and Global NPM Packages...
echo [*] Checking for Node.js core updates...
winget upgrade --id OpenJS.NodeJS.LTS -e --silent --accept-package-agreements --accept-source-agreements
winget upgrade --id OpenJS.NodeJS -e --silent --accept-package-agreements --accept-source-agreements
echo [*] Updating global NPM packages...
call npm update -g
echo.

:: 6. Update Python Packages
echo [6/6] Updating Global Python (PIP) Packages...
set PIP_DEFAULT_TIMEOUT=100
echo Ensuring pip-review is installed...
call pip install pip-review --upgrade
call pip-review --local --auto
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

:: Keep the window open so you can read any errors
pause
