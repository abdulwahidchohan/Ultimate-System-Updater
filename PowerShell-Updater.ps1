<#
.SYNOPSIS
    Ultimate System Updater v2.0 (PowerShell)
.DESCRIPTION
    Full system update script for Windows via PowerShell.
    Covers: Windows Update, OEM Drivers (Dell/Lenovo/HP/ASUS/Surface),
    Winget, Chocolatey, Scoop, Node/npm/pnpm/yarn, Python/pip/pipx/conda,
    Ruby Gems, Rust/Cargo, Go, Windows Defender, WSL, PowerShell itself.
    Made by Abdul Wahid Chohan - Version 2.0
#>

param(
    [switch]$ElevatedAttempted,
    [switch]$NonInteractive
)

# ── Helper: detect interactive session ──────────────────────────────────────
function Test-IsInteractive {
    if ($NonInteractive) { return $false }
    try { return [Environment]::UserInteractive } catch { return $false }
}

# ── Helper: check if a command/cmdlet exists ─────────────────────────────────
function Test-Tool {
    param([Parameter(Mandatory)][string]$Name)
    return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

# ── Helper: wait for a file path to appear ───────────────────────────────────
function Wait-ForPath {
    param([Parameter(Mandatory)][string]$Path, [int]$TimeoutSeconds = 90)
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    while ((Get-Date) -lt $deadline) {
        if (Test-Path $Path) { return $true }
        Start-Sleep -Seconds 2
    }
    return $false
}

# ── Helper: search registry + known paths for an OEM tool ────────────────────
function Find-OemExe {
    param(
        [string[]]$KnownPaths,
        [string]$NamePattern,
        [string]$ExeName
    )
    foreach ($p in $KnownPaths) { if (Test-Path $p) { return $p } }
    $roots = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    foreach ($root in $roots) {
        Get-ItemProperty -Path $root -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName -like $NamePattern } |
            ForEach-Object {
                if ($_.InstallLocation) {
                    $c = Join-Path $_.InstallLocation $ExeName
                    if (Test-Path $c) { return $c }
                }
            }
    }
    $cmd = Get-Command $ExeName -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    return $null
}

# ── Helper: run an OEM updater process ───────────────────────────────────────
function Invoke-OemUpdater {
    param([string]$Path, [string]$Args, [string]$Label)
    $proc = Start-Process -FilePath $Path -ArgumentList $Args -Wait -PassThru
    if ($proc.ExitCode -eq 0) {
        Write-Host "  $Label updates completed." -ForegroundColor Green
    } else {
        Write-Warning "[!] $Label updater exited with code $($proc.ExitCode)."
    }
}

# ── Print section header ─────────────────────────────────────────────────────
function Write-Step {
    param([string]$Text)
    Write-Host $Text -ForegroundColor Yellow
}

$isInteractive = Test-IsInteractive

# ════════════════════════════════════════════════════════════════════════════
# ADMINISTRATOR CHECK
# ════════════════════════════════════════════════════════════════════════════
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)

if (-not $isAdmin) {
    if ($ElevatedAttempted) {
        Write-Error '[!] Administrator elevation was denied or failed. Exiting.'
        exit 1
    }
    Write-Warning '[!] Administrator privileges required. Requesting elevation...'
    $argList = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -ElevatedAttempted"
    if (-not $isInteractive) { $argList += ' -NonInteractive' }
    try {
        Start-Process powershell -ArgumentList $argList -Verb RunAs -ErrorAction Stop | Out-Null
    } catch {
        Write-Error "[!] Elevation failed: $($_.Exception.Message)"
        exit 1
    }
    exit
}

# ════════════════════════════════════════════════════════════════════════════
# BANNER
# ════════════════════════════════════════════════════════════════════════════
Write-Host '=============================================' -ForegroundColor Cyan
Write-Host '      STARTING FULL SYSTEM UPDATE PROCESS    ' -ForegroundColor Cyan
Write-Host '       Made by Abdul Wahid Chohan v2.0       ' -ForegroundColor Cyan
Write-Host '=============================================' -ForegroundColor Cyan
Write-Host ''

# ── Network QoS priority ────────────────────────────────────────────────────
$qosApplied = $false
Write-Host '[*] Allocating Maximum Network Bandwidth...' -ForegroundColor Gray
try {
    Remove-NetQosPolicy -Name 'PSUpdatePriority' -Confirm:$false -ErrorAction SilentlyContinue
    New-NetQosPolicy -Name 'PSUpdatePriority' -AppPathNameMatchCondition 'powershell.exe' `
        -DSCPAction 46 -ErrorAction Stop | Out-Null
    $qosApplied = $true
    Write-Host '  Network priority secured.' -ForegroundColor Green
} catch {
    Write-Warning '[!] Could not apply QoS policy. Continuing without it.'
}
Write-Host ''

# ════════════════════════════════════════════════════════════════════════════
# STEP 1/9 — Windows OS & Driver Updates
# ════════════════════════════════════════════════════════════════════════════
Write-Step '[1/9] Checking for Windows & Driver Updates...'

if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
    Write-Host '  Installing PSWindowsUpdate module...' -ForegroundColor Gray
    try {
        Install-PackageProvider -Name NuGet -Force -ErrorAction Stop | Out-Null
        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
        Install-Module PSWindowsUpdate -Force -Scope AllUsers | Out-Null
        Write-Host '  PSWindowsUpdate installed.' -ForegroundColor Green
    } catch {
        Write-Warning "[!] Failed to install PSWindowsUpdate: $($_.Exception.Message)"
    }
}

try {
    Import-Module PSWindowsUpdate -ErrorAction Stop
    Write-Host '  Scanning for available updates...' -ForegroundColor Gray
    $wuList = Get-WindowsUpdate -ErrorAction SilentlyContinue
    if ($wuList -and $wuList.Count -gt 0) {
        Write-Host "  Found $($wuList.Count) update(s). Installing..." -ForegroundColor Cyan
        Install-WindowsUpdate -AcceptAll -IgnoreReboot -ErrorAction Stop
        Write-Host '  Windows Updates applied successfully.' -ForegroundColor Green
    } else {
        Write-Host '  Windows is already up to date.' -ForegroundColor Green
    }
} catch {
    Write-Warning "[!] Windows update step failed: $($_.Exception.Message)"
}
Write-Host ''

# ════════════════════════════════════════════════════════════════════════════
# STEP 2/9 — OEM Manufacturer Driver Updates
# ════════════════════════════════════════════════════════════════════════════
Write-Step '[2/9] Detecting Manufacturer & Updating OEM Drivers...'
$vendor = (Get-CimInstance Win32_ComputerSystem).Manufacturer
Write-Host "  Manufacturer: $vendor" -ForegroundColor Cyan

if ($vendor -match 'Dell') {
    $dcu = Find-OemExe -KnownPaths @(
        "$env:ProgramFiles\Dell\CommandUpdate\dcu-cli.exe",
        "$env:ProgramW6432\Dell\CommandUpdate\dcu-cli.exe"
    ) -NamePattern '*Dell*Command*Update*' -ExeName 'dcu-cli.exe'

    if (-not $dcu) {
        if (Test-Tool winget) {
            Write-Host '  Installing Dell Command Update via winget...' -ForegroundColor Gray
            winget install Dell.CommandUpdate --silent --accept-package-agreements --accept-source-agreements
            Start-Sleep -Seconds 5
            $dcu = Find-OemExe -KnownPaths @(
                "$env:ProgramFiles\Dell\CommandUpdate\dcu-cli.exe"
            ) -NamePattern '*Dell*Command*Update*' -ExeName 'dcu-cli.exe'
            if (-not $dcu) { Wait-ForPath "$env:ProgramFiles\Dell\CommandUpdate\dcu-cli.exe" | Out-Null }
        } else { Write-Warning '[!] winget not found. Cannot auto-install Dell Command Update.' }
    }
    if ($dcu -and (Test-Path $dcu)) {
        Invoke-OemUpdater -Path $dcu -Args '/applyUpdates -silent -reboot=disable' -Label 'Dell OEM'
    } else { Write-Warning '[!] Dell Command Update not found after install attempt.' }

} elseif ($vendor -match 'Lenovo') {
    $pf86 = [Environment]::GetEnvironmentVariable('ProgramFiles(x86)')
    $su = Find-OemExe -KnownPaths @(
        "$env:ProgramFiles\Lenovo\System Update\tvsu.exe",
        "$pf86\Lenovo\System Update\tvsu.exe"
    ) -NamePattern '*Lenovo*System*Update*' -ExeName 'tvsu.exe'

    if (-not $su) {
        if (Test-Tool winget) {
            Write-Host '  Installing Lenovo System Update via winget...' -ForegroundColor Gray
            winget install Lenovo.SystemUpdate --silent --accept-package-agreements --accept-source-agreements
            Start-Sleep -Seconds 5
            $su = Find-OemExe -KnownPaths @(
                "$env:ProgramFiles\Lenovo\System Update\tvsu.exe",
                "$pf86\Lenovo\System Update\tvsu.exe"
            ) -NamePattern '*Lenovo*System*Update*' -ExeName 'tvsu.exe'
        } else { Write-Warning '[!] winget not found. Cannot auto-install Lenovo System Update.' }
    }
    if ($su -and (Test-Path $su)) {
        Invoke-OemUpdater -Path $su -Args '/CM -search A -action INSTALL -includerebootpackages 1,3,4,5 -noreboot' -Label 'Lenovo OEM'
    } else { Write-Warning '[!] Lenovo System Update not found after install attempt.' }

} elseif ($vendor -match 'HP|Hewlett') {
    $pf86 = [Environment]::GetEnvironmentVariable('ProgramFiles(x86)')
    $hpsa = Find-OemExe -KnownPaths @(
        "$env:ProgramFiles\HP\HP Support Framework\HPSF.exe",
        "$pf86\HP\HP Support Framework\HPSF.exe",
        "$env:ProgramFiles\HP\HP Support Assistant\HPSA_Service.exe"
    ) -NamePattern '*HP*Support*' -ExeName 'HPSF.exe'

    if ($hpsa -and (Test-Path $hpsa)) {
        Write-Host '  Launching HP Support Assistant update scan...' -ForegroundColor Gray
        Start-Process -FilePath $hpsa -ArgumentList '-action StartSOLM' -Wait
        Write-Host '  HP Support Assistant launched.' -ForegroundColor Green
    } else {
        Write-Host '  HP Support Assistant not found. Installing via winget...' -ForegroundColor Yellow
        if (Test-Tool winget) {
            winget install HP.SupportAssistant --silent --accept-package-agreements --accept-source-agreements
        } else {
            Write-Host '  Visit https://support.hp.com/us-en/topic/hp-support-assistant to install manually.' -ForegroundColor Yellow
        }
    }

} elseif ($vendor -match 'ASUSTeK|ASUS') {
    Write-Host '  ASUS detected. Attempting MyASUS install/update via winget...' -ForegroundColor Yellow
    if (Test-Tool winget) {
        winget install ASUS.MyASUS --silent --accept-package-agreements --accept-source-agreements 2>$null
        Write-Host '  Please open MyASUS to apply BIOS/driver updates.' -ForegroundColor Yellow
    } else {
        Write-Host '  Visit https://www.asus.com/support/ for MyASUS.' -ForegroundColor Yellow
    }

} elseif ($vendor -match 'Microsoft') {
    Write-Host '  Microsoft Surface detected. Applying Surface Firmware/Drivers...' -ForegroundColor Gray
    if (Test-Tool winget) {
        winget install Microsoft.SurfaceDriversFirmware --silent --accept-package-agreements --accept-source-agreements 2>$null
        Write-Host '  Surface firmware package applied (reboot may be required).' -ForegroundColor Green
    } else {
        Write-Host '  Visit https://support.microsoft.com/surface to update drivers manually.' -ForegroundColor Yellow
    }

} else {
    Write-Host "  No automated OEM updater configured for: $vendor. Windows Update handles generic drivers." -ForegroundColor DarkGray
}
Write-Host ''

# ════════════════════════════════════════════════════════════════════════════
# STEP 3/9 — Package Managers (Winget + Chocolatey + Scoop)
# ════════════════════════════════════════════════════════════════════════════
Write-Step '[3/9] Updating Apps via Winget, Chocolatey & Scoop...'

if (Test-Tool winget) {
    Write-Host '  [*] Updating winget itself (Microsoft.AppInstaller)...' -ForegroundColor Gray
    winget upgrade --id Microsoft.AppInstaller -e --silent --accept-package-agreements --accept-source-agreements 2>$null

    Write-Host '  [*] Running full Winget upgrade...' -ForegroundColor Gray
    winget upgrade --all --include-unknown --accept-package-agreements --accept-source-agreements
} else {
    Write-Host '  winget not found. Skipping.' -ForegroundColor DarkGray
}

if (Test-Tool choco) {
    Write-Host '  [*] Running Chocolatey upgrade...' -ForegroundColor Gray
    choco upgrade all -y
} else {
    Write-Host '  choco not found. Skipping.' -ForegroundColor DarkGray
}

if (Test-Tool scoop) {
    Write-Host '  [*] Running Scoop upgrade...' -ForegroundColor Gray
    scoop update *
} else {
    Write-Host '  scoop not found. Skipping.' -ForegroundColor DarkGray
}
Write-Host ''

# ════════════════════════════════════════════════════════════════════════════
# STEP 4/9 — Node.js + npm + pnpm + yarn
# ════════════════════════════════════════════════════════════════════════════
Write-Step '[4/9] Updating Node.js & Global Node Package Managers...'

if (Test-Tool winget) {
    winget upgrade --id OpenJS.NodeJS.LTS -e --silent --accept-package-agreements --accept-source-agreements 2>$null
    winget upgrade --id OpenJS.NodeJS     -e --silent --accept-package-agreements --accept-source-agreements 2>$null
} else {
    Write-Host '  winget not found. Skipping Node.js binary upgrade.' -ForegroundColor DarkGray
}

if (Test-Tool npm) {
    Write-Host '  [*] Updating npm itself...' -ForegroundColor Gray
    npm install -g npm@latest

    Write-Host '  [*] Updating all global npm packages...' -ForegroundColor Gray
    npm update -g

    # Allow install scripts for known blocked packages
    $blockedPkgs = @('@anthropic-ai/claude-code', 'better-sqlite3')
    $installedGlobals = npm ls -g --depth=0 --json 2>$null | ConvertFrom-Json -ErrorAction SilentlyContinue
    foreach ($pkg in $blockedPkgs) {
        $pkgName = $pkg -replace '/.*',''
        if ($installedGlobals.dependencies.PSObject.Properties.Name -contains ($pkg -replace '@.*','').TrimStart('@')) {
            Write-Host "  [*] Re-installing $pkg with scripts allowed..." -ForegroundColor Gray
            npm install -g "$pkg" --allow-scripts="$pkg"
        }
    }
} else {
    Write-Host '  npm not found. Skipping.' -ForegroundColor DarkGray
}

if (Test-Tool pnpm) {
    Write-Host '  [*] Updating pnpm global packages...' -ForegroundColor Gray
    pnpm update -g
}

if (Test-Tool yarn) {
    Write-Host '  [*] Updating yarn global packages...' -ForegroundColor Gray
    yarn global upgrade
}
Write-Host ''

# ════════════════════════════════════════════════════════════════════════════
# STEP 5/9 — Python (pip) + pipx + conda/mamba
# ════════════════════════════════════════════════════════════════════════════
Write-Step '[5/9] Updating Global Python Packages...'

if (Test-Tool pip) {
    $env:PIP_DEFAULT_TIMEOUT = '120'

    Write-Host '  [*] Upgrading pip, setuptools & wheel first...' -ForegroundColor Gray
    pip install --upgrade pip setuptools wheel

    Write-Host '  [*] Installing/upgrading pip-review...' -ForegroundColor Gray
    pip install pip-review --upgrade

    if (Test-Tool pip-review) {
        Write-Host '  [*] Upgrading all outdated packages...' -ForegroundColor Gray
        pip-review --local --auto
        Write-Host '  pip packages updated (check above for any non-fatal dependency conflicts).' -ForegroundColor Green
    } else {
        Write-Warning '[!] pip-review not found after install. Skipping bulk update.'
    }
} else {
    Write-Host '  pip not found. Skipping.' -ForegroundColor DarkGray
}

if (Test-Tool pipx) {
    Write-Host '  [*] Upgrading pipx global tools...' -ForegroundColor Gray
    pipx upgrade-all
}

if (Test-Tool conda) {
    Write-Host '  [*] Updating conda base environment...' -ForegroundColor Gray
    conda update -n base -c defaults conda -y
    conda update --all -y
} elseif (Test-Tool mamba) {
    Write-Host '  [*] Updating mamba environment...' -ForegroundColor Gray
    mamba update --all -y
}
Write-Host ''

# ════════════════════════════════════════════════════════════════════════════
# STEP 6/9 — Ruby Gems
# ════════════════════════════════════════════════════════════════════════════
Write-Step '[6/9] Updating Ruby Gems...'

if (Test-Tool gem) {
    gem update --system
    gem update
    gem cleanup
    Write-Host '  Ruby gems updated and cleaned up.' -ForegroundColor Green
} else {
    Write-Host '  gem not found. Skipping.' -ForegroundColor DarkGray
}
Write-Host ''

# ════════════════════════════════════════════════════════════════════════════
# STEP 7/9 — Rust + Cargo
# ════════════════════════════════════════════════════════════════════════════
Write-Step '[7/9] Updating Rust & Global Cargo Packages...'

if (Test-Tool rustup) {
    rustup update
    if (Test-Tool cargo-install-update) {
        cargo install-update -a
    } else {
        Write-Host "  Tip: Run 'cargo install cargo-update' to enable auto-updating cargo packages." -ForegroundColor DarkGray
    }
} else {
    Write-Host '  rustup/cargo not found. Skipping.' -ForegroundColor DarkGray
}
Write-Host ''

# ════════════════════════════════════════════════════════════════════════════
# STEP 8/9 — Go Toolchain
# ════════════════════════════════════════════════════════════════════════════
Write-Step '[8/9] Updating Go Toolchain...'

if (Test-Tool go) {
    $goVer = (go version 2>$null)
    Write-Host "  Current: $goVer" -ForegroundColor Gray
    if (Test-Tool winget) {
        winget upgrade --id GoLang.Go -e --silent --accept-package-agreements --accept-source-agreements 2>$null
        Write-Host '  Go toolchain upgrade attempted.' -ForegroundColor Green
    } else {
        Write-Host '  Visit https://go.dev/dl/ to update Go manually.' -ForegroundColor Yellow
    }
} else {
    Write-Host '  Go not found. Skipping.' -ForegroundColor DarkGray
}
Write-Host ''

# ════════════════════════════════════════════════════════════════════════════
# STEP 9/9 — Windows Defender + WSL + PowerShell
# ════════════════════════════════════════════════════════════════════════════
Write-Step '[9/9] Updating Windows Defender, WSL & PowerShell...'

# Defender signatures
Write-Host '  [*] Updating Windows Defender virus definitions...' -ForegroundColor Gray
try {
    Update-MpSignature -ErrorAction Stop
    Write-Host '  Defender signatures updated successfully.' -ForegroundColor Green
} catch {
    Write-Warning "[!] Defender signature update failed: $($_.Exception.Message)"
}

# WSL
if (Test-Tool wsl) {
    Write-Host '  [*] Updating Windows Subsystem for Linux (WSL)...' -ForegroundColor Gray
    wsl --update
    if ($LASTEXITCODE -eq 0) {
        Write-Host '  WSL updated.' -ForegroundColor Green
    } else {
        Write-Warning "[!] WSL update exited with code $LASTEXITCODE."
    }
} else {
    Write-Host '  WSL not found. Skipping.' -ForegroundColor DarkGray
}

# PowerShell itself
if (Test-Tool winget) {
    Write-Host '  [*] Checking for PowerShell updates...' -ForegroundColor Gray
    winget upgrade --id Microsoft.PowerShell -e --silent --accept-package-agreements --accept-source-agreements 2>$null
    Write-Host '  PowerShell upgrade check complete.' -ForegroundColor Green
}
Write-Host ''

# ── Restore network QoS ──────────────────────────────────────────────────────
Write-Host '[*] Restoring normal network bandwidth allocation...' -ForegroundColor Gray
if ($qosApplied) {
    Remove-NetQosPolicy -Name 'PSUpdatePriority' -Confirm:$false -ErrorAction SilentlyContinue
}
Write-Host ''

# ════════════════════════════════════════════════════════════════════════════
# COMPLETION BANNER
# ════════════════════════════════════════════════════════════════════════════
Write-Host '=============================================' -ForegroundColor Green
Write-Host '        ALL SYSTEM UPDATES COMPLETED!        ' -ForegroundColor Green
Write-Host '=============================================' -ForegroundColor Green
Write-Host ''

# ── Reboot check ─────────────────────────────────────────────────────────────
Write-Host '[*] Checking if a system reboot is required...' -ForegroundColor Gray
$reboot = $false
if (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending') { $reboot = $true }
if (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired') { $reboot = $true }
$pfr = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' `
    -Name 'PendingFileRenameOperations' -ErrorAction SilentlyContinue).PendingFileRenameOperations
if ($pfr) { $reboot = $true }

if ($reboot) {
    Write-Host ''
    Write-Host '[!] WARNING: A system reboot is REQUIRED to finish installing updates.' -ForegroundColor Yellow
    Write-Host '[!] Please save your work and restart your computer soon.'              -ForegroundColor Yellow
} else {
    Write-Host '[+] No reboot required. You are good to go!' -ForegroundColor Green
}
Write-Host ''

if ($isInteractive) {
    Read-Host 'Press Enter to exit'
}