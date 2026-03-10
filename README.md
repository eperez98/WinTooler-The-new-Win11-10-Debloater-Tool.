# WinToolerV1 — Windows 11/10 System Utility

<p align="center">
  <img src="WinToolerV1_icon.png" width="96" alt="WinTooler Icon"/>
</p>

<p align="center">
  <b>A powerful, lightweight Windows utility built with PowerShell + WPF.</b><br/>
  Install apps, remove bloat, tune performance, manage services, and repair your system — all from one clean GUI.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Windows%2010%2F11-0078D4?style=flat-square&logo=windows"/>
  <img src="https://img.shields.io/badge/PowerShell-5.1%2B-012456?style=flat-square&logo=powershell"/>
  <img src="https://img.shields.io/badge/Version-0.6.1%20BETA-blue?style=flat-square"/>
  <img src="https://img.shields.io/badge/Build-4100-lightgrey?style=flat-square"/>
  <img src="https://img.shields.io/badge/License-MIT-green?style=flat-square"/>
</p>

---

## ✨ Features

### 📦 Applications
Browse and install **111 curated apps** across 10 categories via winget — no browser required.

| Category | Apps |
|---|---|
| 🌐 Browsers | Brave, Chrome, Firefox, LibreWolf, Opera, Tor, Thorium, Waterfox, Chromium… |
| 💬 Communications | Discord, Signal, Telegram, Slack, Teams, Zoom, AnyDesk, TeamViewer… |
| 🛠️ Development | VS Code, Git, Node.js, Python, Docker, Android Studio, Postman, GitHub Desktop… |
| 📄 Document | LibreOffice, ONLYOFFICE, SumatraPDF, Foxit Reader, Okular… |
| 🎮 Gaming | Steam, Epic, GOG Galaxy, EA App, Heroic, Parsec, Playnite, Ubisoft Connect… |
| 🎨 Media | VLC, OBS Studio, Audacity, GIMP, Blender, Inkscape, DaVinci Resolve, Krita… |
| 🌍 Network | FileZilla, PuTTY, WinSCP, Nmap, MobaXterm, Angry IP Scanner… |
| ⚡ Productivity | PowerToys, KeePassXC, Obsidian, Notion, Thunderbird, AutoHotkey, Bitwarden… |
| 🔒 Security | Malwarebytes, ProtonVPN, VeraCrypt, Wireshark… |
| 🔧 Utilities | 7-Zip, WinRAR, CPU-Z, GPU-Z, HWiNFO64, Rufus, Ventoy, Everything, qBittorrent… |

- **Smart install cascade** — 6 retry attempts covering scope conflicts, CDN 404s and hash mismatches automatically
- **Uninstall mode** — lists all winget-tracked apps installed on your system, remove with one click
- **Update All Apps** — launches an external PowerShell window running `winget upgrade --all`
- **Live search** — filter the full catalog instantly by name or description
- **Category sidebar** — browse by category or view all apps at once
- **Bilingual** — full English / Spanish UI with in-app toggle

### ⚙️ Tweaks (23 tweaks)
Safe, reversible system optimizations organized by risk level.

**Performance**
- High Performance Power Plan, Disable SysMain / Superfetch, Disable Search Indexing
- Reduce Visual Animations, Disable Hibernation, GameMode & GPU Scheduling

**Privacy**
- Disable Telemetry & Advertising ID, Block Telemetry Hosts, Disable Activity History
- Disable Location Services, Disable Webcam / Microphone Access

**UI / Bloat Removal**
- Enable Dark Mode, Show File Extensions & Hidden Files
- Remove Start Menu Ads, Clean Taskbar, Disable Bing in Start
- Remove Microsoft Bloatware, Remove Xbox Components, Disable Edge Bloat, Disable OneDrive Startup

**Templates** — apply preset combinations in one click:
- `Standard` — recommended daily-driver tweaks
- `Minimal` — only the safest, lowest-risk tweaks
- `Heavy` — aggressive optimization (advanced users)

### 🔌 Services Manager (18 services)
Enable, disable or set services to Manual. Includes telemetry, Xbox, Remote Registry, Fax, WMP Network Share, and more. Color-coded by current state.

### 🔧 Repair Tools
- **SFC Scan** — System File Checker (async, real-time log output)
- **DISM Restore** — Component store health repair
- **Clear Temp Files** — User and system temp cleanup
- **Flush DNS** — `ipconfig /flushdns`
- **Reset Windows Store** — `wsreset.exe`
- **Create Restore Point** — Manual snapshot before changes
- **Reset Network Stack** — Full Winsock / TCP-IP reset

### 🪟 Windows Updates
Trigger Windows Update scans, pause updates for 7 days, or resume them — directly from the GUI without opening Settings.

---

## 🚀 Quick Start

### Requirements
- Windows 10 (Build 19041+) or Windows 11
- PowerShell 5.1 (built-in) — no PowerShell 7 required
- **winget** (App Installer from Microsoft Store) — required for the Applications tab
- Administrator privileges (required for tweaks, services, and repairs)

### How to Run

1. **Download** the latest release ZIP and extract it anywhere
2. **Right-click** `Launch.bat` → **Run as administrator**
3. The CLI bootstrap window checks dependencies, creates a restore point, then opens the GUI

> ⚠️ Running without administrator rights will disable tweaks, services, and repair tools.

---

## 📁 Project Structure

```
WinToolerV1/
├── Launch.bat              ← Entry point (run as admin)
├── WinToolerV1.ps1         ← Bootstrap, dependency check, restore point
├── WinToolerV1_icon.png    ← App icon
├── scripts/
│   └── gui.ps1             ← Full WPF GUI (~3 500 lines)
├── functions/
│   ├── tweaks.ps1          ← Tweak apply/undo logic
│   ├── repair.ps1          ← SFC, DISM, DNS, etc.
│   └── updates.ps1         ← Windows Update control
└── config/
    ├── apps.json           ← 111 app definitions (Id, Category, Icon, Color, Scope)
    ├── tweaks.json         ← 23 tweaks (registry keys, risk level, undo info)
    └── services.json       ← 18 services (name, safe state, description)
```

---

## 🛡️ Safety

- A **System Restore Point** is automatically created at every launch before any changes are made
- All tweaks include full **undo** support — revert individual tweaks or all at once
- Services are only toggled; no service is deleted
- No changes are made until you explicitly click Apply
- All actions are logged to `%TEMP%\WinToolerV1_<timestamp>.log`

---

## 🌐 Language Support

WinTooler supports **English** and **Spanish** with a live toggle in the sidebar — no restart required. The language preference is applied immediately to all labels, buttons, and page titles.

---

## 📋 Changelog

### v0.6.1 BETA — Build 4100
- **New:** Unified Applications page (Install + Uninstall in one tab with mode bar)
- **New:** "Update All Apps" button — launches external PowerShell window with `winget upgrade --all`
- **New:** Background winget ID validator — checks all 111 app IDs on first visit
- **New:** In-app language toggle (EN / ES) — no restart required
- **Fix:** App install cascade now retries 6 ways (scope, no-scope, hash bypass) before failing
- **Fix:** Removed blocking startup scan — app now opens instantly
- **Fix:** Restore point 24hr warning suppressed — frequency bypass applied silently
- **Fix:** Language toggle crash (inline `if` in WPF event handlers)
- **Fix:** Uninstall search freeze (split fetch/filter into separate operations)

### v0.6.0 BETA — Build 4034
- Initial public beta release
- App catalog with 111 apps across 10 categories
- 23 system tweaks with risk levels and undo
- Services manager with 18 configurable services
- Async SFC / DISM repair tools
- Windows Update control (scan, pause, resume)
- Dark/Light theme toggle
- Aero glass transparency effect

---

## ⚖️ License

GPL-3.0 License — see [LICENSE](LICENSE) for details.

---

## 🙏 Credits

Inspired by [ChrisTitusTech/winutil](https://github.com/ChrisTitusTech/winutil) and the Windows tweaking community.

Built with ❤️ using PowerShell + WPF — no Electron, no Python, no bloat.
