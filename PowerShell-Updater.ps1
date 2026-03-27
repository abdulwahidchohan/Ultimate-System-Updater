<#
.SYNOPSIS
    Ultimate System Updater (PowerShell)
.DESCRIPTION
    Full system update script for Windows via PowerShell.
    Made by Abdul Wahid Chohan
#>

param(
    [switch]$ElevatedAttempted,
    [switch]$NonInteractive
)

function Test-IsInteractive {
    if ($NonInteractive) {
        return $false
    }

    try {
        return [Environment]::UserInteractive
    } catch {
        return $false
    }
}

function Test-Tool {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Wait-ForPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [int]$TimeoutSeconds = 60
    )

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    while ((Get-Date) -lt $deadline) {
        if (Test-Path $Path) {
            return $true
        }
        Start-Sleep -Seconds 2
    }

    return $false
}

function Get-RegistryInstallPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$DisplayNamePattern,
        [Parameter(Mandatory = $true)]
        [string]$ExecutableName
    )

    $roots = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )

    foreach ($root in $roots) {
        $apps = Get-ItemProperty -Path $root -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName -like $DisplayNamePattern }
        foreach ($app in $apps) {
            if ($app.InstallLocation) {
                $candidate = Join-Path $app.InstallLocation $ExecutableName
                if (Test-Path $candidate) {
                    return $candidate
                }
            }
        }
    }

    return $null
}

function Get-DellDcuPath {
    $candidates = @(
        "$env:ProgramFiles\Dell\CommandUpdate\dcu-cli.exe",
        "${env:ProgramFiles(x86)}\Dell\CommandUpdate\dcu-cli.exe"
    )

    foreach ($candidate in $candidates) {
        if (Test-Path $candidate) {
            return $candidate
        }
    }

    $registryPath = Get-RegistryInstallPath -DisplayNamePattern '*Dell*Command*Update*' -ExecutableName 'dcu-cli.exe'
    if ($registryPath) {
        return $registryPath
    }

    $cmd = Get-Command dcu-cli.exe -ErrorAction SilentlyContinue
    if ($cmd) {
        return $cmd.Source
    }

    return $null
}

function Get-LenovoSuPath {
    $candidates = @(
        "$env:ProgramFiles\Lenovo\System Update\tvsu.exe",
        "${env:ProgramFiles(x86)}\Lenovo\System Update\tvsu.exe"
    )

    foreach ($candidate in $candidates) {
        if (Test-Path $candidate) {
            return $candidate
        }
    }

    $registryPath = Get-RegistryInstallPath -DisplayNamePattern '*Lenovo*System*Update*' -ExecutableName 'tvsu.exe'
    if ($registryPath) {
        return $registryPath
    }

    $cmd = Get-Command tvsu.exe -ErrorAction SilentlyContinue
    if ($cmd) {
        return $cmd.Source
    }

    return $null
}

$isInteractive = Test-IsInteractive

# --- AUTOMATIC ADMINISTRATOR CHECK ---
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)

if (-not $isAdmin) {
    if ($ElevatedAttempted) {
        Write-Error "[!] Administrator elevation was denied or failed. Exiting."
        exit 1
    }

    Write-Warning "[!] Administrator privileges required. Requesting elevation..."
    $argList = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -ElevatedAttempted"
    if (-not $isInteractive) {
        $argList += " -NonInteractive"
    }

    try {
        Start-Process powershell -ArgumentList $argList -Verb RunAs -ErrorAction Stop | Out-Null
    } catch {
        Write-Error "[!] Failed to elevate process: $($_.Exception.Message)"
        exit 1
    }
    exit
}

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "     STARTING FULL SYSTEM UPDATE PROCESS    " -ForegroundColor Cyan
Write-Host "        Made by Abdul Wahid Chohan          " -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# --- NETWORK BANDWIDTH PRIORITIZATION ---
$qosApplied = $false
Write-Host "[*] Allocating Maximum Network Bandwidth..." -ForegroundColor Gray
try {
    Remove-NetQosPolicy -Name 'PSUpdatePriority' -Confirm:$false -ErrorAction SilentlyContinue
    New-NetQosPolicy -Name 'PSUpdatePriority' -AppPathNameMatchCondition 'powershell.exe' -DSCPAction 46 -ErrorAction Stop | Out-Null
    $qosApplied = $true
    Write-Host "Network priority secured." -ForegroundColor Green
} catch {
    Write-Warning "[!] Could not apply QoS policy. Continuing without it."
}
Write-Host ""

# ============================================
# STEP 1: Windows OS & Driver Updates
# ============================================
Write-Host "[1/8] Checking for Windows & Driver Updates..." -ForegroundColor Yellow
if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
    Write-Host "  Installing PSWindowsUpdate module..." -ForegroundColor Gray
    try {
        Install-PackageProvider -Name NuGet -Force -ErrorAction Stop | Out-Null
        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction Stop
        Install-Module -Name PSWindowsUpdate -Force -ErrorAction Stop | Out-Null
    } catch {
        Write-Warning "[!] Failed to install PSWindowsUpdate: $($_.Exception.Message)"
    }
}

try {
    Import-Module PSWindowsUpdate -ErrorAction Stop
    if (Test-Tool -Name Install-WindowsUpdate) {
        Install-WindowsUpdate -AcceptAll -IgnoreReboot
    } else {
        Write-Warning "[!] Install-WindowsUpdate command is unavailable. Skipping Windows Update step."
    }
} catch {
    Write-Warning "[!] Windows update step failed: $($_.Exception.Message)"
}
Write-Host ""

# ============================================
# STEP 2: OEM Manufacturer Driver Updates
# ============================================
Write-Host "[2/8] Detecting Manufacturer & Updating OEM Drivers..." -ForegroundColor Yellow
$vendor = (Get-CimInstance Win32_ComputerSystem).Manufacturer
Write-Host "  Manufacturer: $vendor" -ForegroundColor Cyan

if ($vendor -match 'Dell') {
    $dcu = Get-DellDcuPath
    if (-not $dcu) {
        if (Test-Tool -Name winget) {
            Write-Host "  Dell Command Update not found. Installing with winget..." -ForegroundColor Gray
            winget install Dell.CommandUpdate --silent --accept-package-agreements --accept-source-agreements
            $dcu = Get-DellDcuPath
            if (-not $dcu) {
                $defaultDcu = "$env:ProgramFiles\Dell\CommandUpdate\dcu-cli.exe"
                if (Wait-ForPath -Path $defaultDcu -TimeoutSeconds 60) {
                    $dcu = $defaultDcu
                }
            }
        } else {
            Write-Warning "[!] winget not found. Cannot auto-install Dell Command Update."
        }
    }

    if ($dcu -and (Test-Path $dcu)) {
        $dcuProcess = Start-Process -FilePath $dcu -ArgumentList '/applyUpdates -silent -reboot=disable' -Wait -PassThru
        if ($dcuProcess.ExitCode -eq 0) {
            Write-Host "  Dell OEM updates completed." -ForegroundColor Green
        } else {
            Write-Warning "[!] Dell OEM updater exited with code $($dcuProcess.ExitCode)."
        }
    } else {
        Write-Warning "[!] Could not locate Dell Command Update after installation attempt."
    }
} elseif ($vendor -match 'Lenovo') {
    $su = Get-LenovoSuPath
    if (-not $su) {
        if (Test-Tool -Name winget) {
            Write-Host "  Lenovo System Update not found. Installing with winget..." -ForegroundColor Gray
            winget install Lenovo.SystemUpdate --silent --accept-package-agreements --accept-source-agreements
            $su = Get-LenovoSuPath
            if (-not $su) {
                $defaultSu = "${env:ProgramFiles(x86)}\Lenovo\System Update\tvsu.exe"
                if (Wait-ForPath -Path $defaultSu -TimeoutSeconds 60) {
                    $su = $defaultSu
                }
            }
        } else {
            Write-Warning "[!] winget not found. Cannot auto-install Lenovo System Update."
        }
    }

    if ($su -and (Test-Path $su)) {
        $suProcess = Start-Process -FilePath $su -ArgumentList '/CM -search A -action INSTALL -includerebootpackages 1,3,4,5 -noreboot' -Wait -PassThru
        if ($suProcess.ExitCode -eq 0) {
            Write-Host "  Lenovo OEM updates completed." -ForegroundColor Green
        } else {
            Write-Warning "[!] Lenovo OEM updater exited with code $($suProcess.ExitCode)."
        }
    } else {
        Write-Warning "[!] Could not locate Lenovo System Update after installation attempt."
    }
} elseif ($vendor -match 'HP') {
    Write-Host "  HP detected. Please run HP Support Assistant manually (hp.com/support)." -ForegroundColor Yellow
} else {
    Write-Host "  No OEM updater configured. Windows Update handles generic drivers." -ForegroundColor DarkGray
}
Write-Host ""

# ============================================
# STEP 3: App Package Managers (Winget + Choco)
# ============================================
Write-Host "[3/8] Updating Apps via Winget & Chocolatey..." -ForegroundColor Yellow
if (Test-Tool -Name winget) {
    Write-Host "  [*] Running Winget upgrade..." -ForegroundColor Gray
    winget upgrade --all --include-unknown --accept-package-agreements --accept-source-agreements
} else {
    Write-Host "  winget not found. Skipping." -ForegroundColor DarkGray
}

Write-Host "  [*] Running Chocolatey upgrade..." -ForegroundColor Gray
if (Test-Tool -Name choco) {
    choco upgrade all -y
} else {
    Write-Host "  choco not found. Skipping." -ForegroundColor DarkGray
}
Write-Host ""

# ============================================
# STEP 4: Node.js & Global NPM Packages
# ============================================
Write-Host "[4/8] Updating Node.js & Global NPM Packages..." -ForegroundColor Yellow
if (Test-Tool -Name winget) {
    winget upgrade --id OpenJS.NodeJS.LTS -e --silent --accept-package-agreements --accept-source-agreements
    winget upgrade --id OpenJS.NodeJS -e --silent --accept-package-agreements --accept-source-agreements
} else {
    Write-Host "  winget not found. Skipping Node.js binary upgrades." -ForegroundColor DarkGray
}

if (Test-Tool -Name npm) {
    npm update -g
} else {
    Write-Host "  npm not found. Skipping." -ForegroundColor DarkGray
}
Write-Host ""

# ============================================
# STEP 5: Python (PIP) Packages
# ============================================
Write-Host "[5/8] Updating Global Python (PIP) Packages..." -ForegroundColor Yellow
Write-Host "  [!] Aggressive mode enabled: updating all global Python packages." -ForegroundColor DarkYellow
if (Test-Tool -Name pip) {
    pip install pip-review --upgrade
    if (Test-Tool -Name pip-review) {
        pip-review --local --auto
    } else {
        Write-Warning "[!] pip-review command not found after installation attempt."
    }
} else {
    Write-Host "  pip not found. Skipping." -ForegroundColor DarkGray
}
Write-Host ""

# ============================================
# STEP 6: Ruby Gems
# ============================================
Write-Host "[6/8] Updating Ruby Gems..." -ForegroundColor Yellow
Write-Host "  [!] Aggressive mode enabled: updating system RubyGems and all global gems." -ForegroundColor DarkYellow
if (Test-Tool -Name gem) {
    gem update --system
    gem update
} else {
    Write-Host "  gem not found. Skipping." -ForegroundColor DarkGray
}
Write-Host ""

# ============================================
# STEP 7: Rust / Cargo Packages
# ============================================
Write-Host "[7/8] Updating Rust & Global Cargo Packages..." -ForegroundColor Yellow
Write-Host "  [!] Aggressive mode enabled: updating all globally installed cargo crates." -ForegroundColor DarkYellow
if (Test-Tool -Name rustup) {
    rustup update
    if (Test-Tool -Name cargo-install-update) {
        cargo install-update -a
    } else {
        Write-Host "  Tip: Run 'cargo install cargo-update' to enable auto-updating cargo packages." -ForegroundColor DarkGray
    }
} else {
    Write-Host "  cargo/rustup not found. Skipping." -ForegroundColor DarkGray
}
Write-Host ""

# ============================================
# STEP 8: Windows Defender + WSL Update
# ============================================
Write-Host "[8/8] Updating Windows Defender Signatures & WSL..." -ForegroundColor Yellow
Write-Host "  [*] Updating Defender virus definitions..." -ForegroundColor Gray
if (Test-Tool -Name Update-MpSignature) {
    Update-MpSignature -ErrorAction SilentlyContinue
    Write-Host "  Defender signatures update attempted." -ForegroundColor Green
} else {
    Write-Host "  Defender update command unavailable. Skipping." -ForegroundColor DarkGray
}

Write-Host "  [*] Updating WSL..." -ForegroundColor Gray
if (Test-Tool -Name wsl) {
    wsl --update
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  WSL updated." -ForegroundColor Green
    } else {
        Write-Warning "[!] WSL update exited with code $LASTEXITCODE."
    }
} else {
    Write-Host "  wsl not found. Skipping." -ForegroundColor DarkGray
}
Write-Host ""

# --- RESTORE NETWORK SETTINGS ---
Write-Host "[*] Restoring normal network bandwidth allocation..." -ForegroundColor Gray
if ($qosApplied) {
    Remove-NetQosPolicy -Name 'PSUpdatePriority' -Confirm:$false -ErrorAction SilentlyContinue
}
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

if ($isInteractive) {
    Read-Host "Press Enter to exit"
}