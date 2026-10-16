#!/bin/zsh

# ============================================================
#  Ultimate Mac Updater (Zsh) v2.0
#  Made by Abdul Wahid Chohan
#  Covers: macOS softwareupdate, Homebrew (formulae + casks),
#           Mac App Store (mas), npm/pnpm/yarn, pip/pipx/conda,
#           Ruby Gems, Rust/Cargo, Go Toolchain
# ============================================================

NON_INTERACTIVE=0
for arg in "$@"; do
    if [ "$arg" = "--non-interactive" ]; then
        NON_INTERACTIVE=1
    fi
done

if [ ! -t 0 ] || [ ! -t 1 ]; then
    NON_INTERACTIVE=1
fi

# ── Detect if pip needs --break-system-packages (PEP 668 on macOS 14+) ──────
pip_install_pkg() {
    local pip_cmd="$1"
    shift
    if "$pip_cmd" install "$@" 2>&1 | grep -q "externally-managed-environment"; then
        "$pip_cmd" install --break-system-packages "$@"
    else
        "$pip_cmd" install "$@"
    fi
}

# ── Administrator check ──────────────────────────────────────────────────────
CURRENT_EUID="${EUID:-$(id -u)}"
if [ "$CURRENT_EUID" -ne 0 ]; then
    if ! command -v sudo >/dev/null 2>&1; then
        printf "\033[31m[!] sudo not found and root is required. Exiting.\033[0m\n"
        exit 1
    fi
    printf "\033[33m[!] Administrator privileges required. Requesting sudo...\033[0m\n"
    exec sudo -E zsh "$0" "$@" || {
        printf "\033[31m[!] Elevation failed. Exiting.\033[0m\n"
        exit 1
    }
fi

printf "\033[36m=============================================\033[0m\n"
printf "\033[36m      STARTING FULL SYSTEM UPDATE PROCESS    \033[0m\n"
printf "\033[36m       Made by Abdul Wahid Chohan v2.0       \033[0m\n"
printf "\033[36m=============================================\033[0m\n"
echo ""

# ════════════════════════════════════════════════════════════════════════════
# STEP 1/8 — macOS System Updates
# ════════════════════════════════════════════════════════════════════════════
printf "\033[33m[1/8] Checking for macOS System Updates...\033[0m\n"
printf "\033[33m  [!] macOS may request or force a restart during some updates.\033[0m\n"
softwareupdate --all --install --agree-to-license 2>/dev/null || softwareupdate -i -a
echo ""

# ════════════════════════════════════════════════════════════════════════════
# STEP 2/8 — Homebrew (Formulae + Casks + Cleanup)
# ════════════════════════════════════════════════════════════════════════════
printf "\033[33m[2/8] Updating Homebrew Packages...\033[0m\n"

if command -v brew >/dev/null 2>&1; then
    printf "\033[90m  [*] Updating Homebrew itself...\033[0m\n"
    brew update

    printf "\033[90m  [*] Upgrading formulae...\033[0m\n"
    brew upgrade

    printf "\033[90m  [*] Upgrading casks...\033[0m\n"
    brew upgrade --cask --greedy 2>/dev/null || brew upgrade --cask

    printf "\033[90m  [*] Running brew cleanup...\033[0m\n"
    brew cleanup -s

    printf "\033[90m  [*] Running brew doctor (warnings only)...\033[0m\n"
    brew doctor 2>&1 | grep -E "^Warning:|^Error:" || true

    printf "\033[32m  Homebrew update complete.\033[0m\n"
else
    printf "\033[90m  Homebrew not found. Install from https://brew.sh\033[0m\n"
fi
echo ""

# ════════════════════════════════════════════════════════════════════════════
# STEP 3/8 — Mac App Store (via mas-cli)
# ════════════════════════════════════════════════════════════════════════════
printf "\033[33m[3/8] Updating Mac App Store Apps...\033[0m\n"

if command -v mas >/dev/null 2>&1; then
    if mas account >/dev/null 2>&1; then
        mas upgrade
        printf "\033[32m  App Store apps updated.\033[0m\n"
    else
        printf "\033[90m  mas is installed but not signed in to Apple ID. Skipping.\033[0m\n"
    fi
else
    printf "\033[90m  mas not found. Install via Homebrew: brew install mas\033[0m\n"
fi
echo ""

# ════════════════════════════════════════════════════════════════════════════
# STEP 4/8 — Node.js & Global npm / pnpm / yarn
# ════════════════════════════════════════════════════════════════════════════
printf "\033[33m[4/8] Updating Global Node.js Package Managers...\033[0m\n"

if command -v npm >/dev/null 2>&1; then
    printf "\033[90m  [*] Updating npm itself...\033[0m\n"
    npm install -g npm@latest
    printf "\033[90m  [*] Updating all global npm packages...\033[0m\n"
    npm update -g
else
    printf "\033[90m  npm not found. Skipping.\033[0m\n"
fi

if command -v pnpm >/dev/null 2>&1; then
    printf "\033[90m  [*] Updating pnpm global packages...\033[0m\n"
    pnpm update -g
fi

if command -v yarn >/dev/null 2>&1; then
    printf "\033[90m  [*] Updating yarn global packages...\033[0m\n"
    yarn global upgrade
fi
echo ""

# ════════════════════════════════════════════════════════════════════════════
# STEP 5/8 — Python (pip) + pipx + conda/mamba
# ════════════════════════════════════════════════════════════════════════════
printf "\033[33m[5/8] Updating Global Python Packages...\033[0m\n"
printf "\033[33m  [!] Aggressive mode: upgrading all global Python packages.\033[0m\n"

PIP_CMD=""
if command -v pip3 >/dev/null 2>&1; then
    PIP_CMD="pip3"
elif command -v pip >/dev/null 2>&1; then
    PIP_CMD="pip"
fi

if [ -n "$PIP_CMD" ]; then
    printf "\033[90m  [*] Upgrading pip, setuptools & wheel...\033[0m\n"
    pip_install_pkg "$PIP_CMD" --upgrade pip setuptools wheel

    printf "\033[90m  [*] Installing/upgrading pip-review...\033[0m\n"
    pip_install_pkg "$PIP_CMD" pip-review --upgrade

    if command -v pip-review >/dev/null 2>&1; then
        printf "\033[90m  [*] Upgrading all outdated packages...\033[0m\n"
        pip-review --local --auto
        printf "\033[32m  Python packages updated.\033[0m\n"
    else
        printf "\033[90m  pip-review not found after install. Skipping auto-review.\033[0m\n"
    fi
else
    printf "\033[90m  pip not found. Skipping.\033[0m\n"
fi

if command -v pipx >/dev/null 2>&1; then
    printf "\033[90m  [*] Upgrading pipx global tools...\033[0m\n"
    pipx upgrade-all
fi

if command -v conda >/dev/null 2>&1; then
    printf "\033[90m  [*] Updating conda base environment...\033[0m\n"
    conda update -n base -c defaults conda -y
    conda update --all -y
elif command -v mamba >/dev/null 2>&1; then
    printf "\033[90m  [*] Updating mamba environment...\033[0m\n"
    mamba update --all -y
fi
echo ""

# ════════════════════════════════════════════════════════════════════════════
# STEP 6/8 — Ruby Gems
# ════════════════════════════════════════════════════════════════════════════
printf "\033[33m[6/8] Updating Ruby Gems...\033[0m\n"

if command -v gem >/dev/null 2>&1; then
    gem update --system
    gem update
    gem cleanup
    printf "\033[32m  Ruby gems updated and cleaned up.\033[0m\n"
else
    printf "\033[90m  gem not found. Skipping.\033[0m\n"
fi
echo ""

# ════════════════════════════════════════════════════════════════════════════
# STEP 7/8 — Rust / Cargo
# ════════════════════════════════════════════════════════════════════════════
printf "\033[33m[7/8] Updating Rust & Global Cargo Packages...\033[0m\n"

if command -v rustup >/dev/null 2>&1; then
    rustup update
    if command -v cargo-install-update >/dev/null 2>&1; then
        cargo install-update -a
    else
        printf "\033[90m  Tip: Run 'cargo install cargo-update' to enable auto-updating cargo packages.\033[0m\n"
    fi
else
    printf "\033[90m  rustup/cargo not found. Skipping.\033[0m\n"
fi
echo ""

# ════════════════════════════════════════════════════════════════════════════
# STEP 8/8 — Go Toolchain
# ════════════════════════════════════════════════════════════════════════════
printf "\033[33m[8/8] Updating Go Toolchain...\033[0m\n"

if command -v go >/dev/null 2>&1; then
    printf "\033[90m  Current: $(go version)\033[0m\n"
    if command -v brew >/dev/null 2>&1; then
        brew upgrade go 2>/dev/null || true
        printf "\033[32m  Go toolchain updated via Homebrew.\033[0m\n"
    else
        printf "\033[90m  Visit https://go.dev/dl/ to update Go manually.\033[0m\n"
    fi
else
    printf "\033[90m  Go not found. Skipping.\033[0m\n"
fi
echo ""

printf "\033[32m=============================================\033[0m\n"
printf "\033[32m        ALL SYSTEM UPDATES COMPLETED!        \033[0m\n"
printf "\033[32m=============================================\033[0m\n"
echo ""

# ── Reboot check ─────────────────────────────────────────────────────────────
printf "\033[90m[*] Checking if a system reboot is required...\033[0m\n"
if softwareupdate -l 2>/dev/null | grep -Ei 'restart|recommended' >/dev/null; then
    printf "\033[33m[!] WARNING: A system reboot may be required to finish installing updates.\033[0m\n"
    printf "\033[33m[!] Please save your work and restart your Mac soon.\033[0m\n"
else
    printf "\033[32m[+] No reboot requirement detected. You are good to go!\033[0m\n"
fi
echo ""

if [ "$NON_INTERACTIVE" -eq 0 ]; then
    read "?Press Enter to exit..."
fi
