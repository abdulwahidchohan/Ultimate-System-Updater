<div align="center">

# 🚀 Ultimate Multi-Platform System Updaters

**Automate your system updates across Windows, macOS, Linux, and Cisco Networking Hardware.**

[![Windows](https://img.shields.io/badge/Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white)](#-windows-command-prompt-cmd--powershell)
[![Apple](https://img.shields.io/badge/macOS-000000?style=for-the-badge&logo=apple&logoColor=white)](#-macos-zsh)
[![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)](#-linux-bash)
[![Cisco](https://img.shields.io/badge/Cisco-1BA0D7?style=for-the-badge&logo=cisco&logoColor=white)](#-cisco-ios-network-hardware)

A comprehensive suite of automated maintenance and update scripts created by **Abdul Wahid Chohan**. Keeping your machines secure, drivers up-to-date, and applications running perfectly has never been easier. 

</div>

---

## 🌟 Why Use These Scripts? (SEO & Search Friendly)

Whether you are an IT Administrator managing a fleet of devices, a developer looking to keep your environment optimized, or an everyday user needing an easy reliable update solution—these scripts eliminate the hassle of multi-platform maintenance. 

**Keywords & Topics covered:** `automated system update`, `windows driver updater`, `macos terminal updater`, `linux package manager`, `apt snap flatpak`, `scripted pc maintenance`, `dell command update automation`, `lenovo system update script`, `winget chocolatey installer`, `cisco ios firmware update backup`.

---

## 🛠️ Available CLIs & Scripts

| CLI Name | Primary OS | Primary Use Case | Dedicated File |
| :--- | :--- | :--- | :--- |
| **Command Prompt** | Windows | Basic tasks, legacy support | `Ultimate-Windows-Updater.cmd` |
| **PowerShell** | Windows / Cross-platform | Advanced automation, system admin | `PowerShell-Updater.ps1` |
| **Bash** | Linux / macOS | General purpose scripting and dev | `Bash-Linux-Updater.sh` |
| **Zsh** | macOS / Linux | Modern interactive use, high customization | `Zsh-Mac-Updater.zsh` |
| **Cisco IOS** | Network Hardware | Manual firmware and maintenance checklist | `Cisco-IOS-Maintenance.txt` |

---

## 🚀 Features by Platform

### 🪟 Windows (Command Prompt `cmd` & `powershell`)
- **Auto-Elevates to Administrator:** Requests Admin privileges automatically.
- **Windows OS & OEM Driver Updates:** Installs `PSWindowsUpdate` and handles pending OS updates. Attempts OEM driver updates via **Dell Command Update** and **Lenovo System Update**, with clear fallback messaging if unavailable.
- **Package Managers:** Upgrades software via **Winget** and **Chocolatey (Choco)**.
- **Developer Tools:** Updates **Node.js**, **NPM global packages**, and **Python (`pip-review`)**.

### 🐧 Linux (`bash`)
- **APT Packages:** Updates core OS packages via `apt update` & `upgrade` on Ubuntu/Debian arrays.
- **Snap & Flatpak:** Refreshes universal Linux app packages seamlessly.
- **Developer Packages:** Keeps global NPM modules updated without manual search.

### 🍎 macOS (`zsh`)
- **macOS Software Update:** Downloads and installs core Apple updates via `softwareupdate`.
- **Homebrew Automation:** Updates and scrubs the `brew` package directory automatically.
- **Ruby & Node:** Ensures system-level ruby gems (`gem update`) and global NPM binaries are at their latest version.

### 🌐 Cisco IOS (`network hardware`)
- **Manual Maintenance Routine:** Includes an essential CLI checklist for backing up configurations (`copy run start`), verifying connectivity, checking flash memory space, and loading new `.bin` IOS firmware images via TFTP.

---

## 📥 How to Download & Use

The easiest way to get the updater for your specific system is to run a simple download command directly in your terminal. **Run the command for your operating system below:**

### 🪟 Windows (Command Prompt)
Open `cmd.exe` as Administrator and run:
```cmd
curl -O "https://raw.githubusercontent.com/abdulwahidchohan/Ultimate-System-Updater/main/Ultimate-Windows-Updater.cmd" && Ultimate-Windows-Updater.cmd
```

### 🪟 Windows (PowerShell)
Open PowerShell as Administrator and run:
```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/abdulwahidchohan/Ultimate-System-Updater/main/PowerShell-Updater.ps1" -OutFile "PowerShell-Updater.ps1"; powershell -ExecutionPolicy Bypass -File .\PowerShell-Updater.ps1
```

### 🐧 Linux (Bash)
Open your terminal and run:
```bash
curl -O "https://raw.githubusercontent.com/abdulwahidchohan/Ultimate-System-Updater/main/Bash-Linux-Updater.sh" && chmod +x Bash-Linux-Updater.sh && sudo ./Bash-Linux-Updater.sh
```

### 🍎 macOS (Zsh)
Open your terminal and run:
```zsh
curl -O "https://raw.githubusercontent.com/abdulwahidchohan/Ultimate-System-Updater/main/Zsh-Mac-Updater.zsh" && chmod +x Zsh-Mac-Updater.zsh && ./Zsh-Mac-Updater.zsh
```

### 🌐 OR Download the Full ZIP
If you want the entire suite of scripts, click the green **`Code`** button at the top of this repository and select **`Download ZIP`**. Extract the files and double click the relevant script for your OS.

## ⚠️ Requirements & Warnings

* **Internet Connection:** An active internet connection is required to fetch software packages and driver bundles.
* **Permissions:** Make sure your user account has `sudo` (Linux/Mac) or `Administrator` privileges (Windows).
* **Automation Mode:** Scripts auto-detect non-interactive sessions and skip final keypress prompts. You can also pass `--non-interactive` to Linux/macOS scripts.
* **Aggressive Update Policy:** Developer package steps intentionally update global packages (pip/gem/cargo) in bulk.
* **Disclaimer:** Automatically updating deep OEM drivers and core packages can occasionally cause unexpected behavior depending on your system configuration. *Use at your own risk.* 

## 🤝 Customization & Contributing

Feel free to fork this project, edit the scripts, and modify any toolsets you find unnecessary for your specific setup! Contributions, pull requests, and forks are welcome to expand search visibility and usability.

---

<div align="center">
  <i>Automating the world one shell at a time. Made with ❤️ by Abdul Wahid Chohan.</i>
</div>
