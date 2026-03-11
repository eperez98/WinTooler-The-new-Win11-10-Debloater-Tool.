# WinToolerV1 — Windows 11/10 System Utility

<p align="center">
  <img src="banner.png" width="515" alt="WinTooler Icon"/>
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
  <img src="https://img.shields.io/badge/License-GPL--3.0-green?style=flat-square"/>
</p>

---

## Features

### App Manager — 376 Apps across 9 Categories

Browse, install, and uninstall apps from a curated WinUtil-sourced catalog via winget, no browser needed.

| Category | Count | Highlights |
|---|---|---|
| Utilities | 134 | 7-Zip, Everything, KeePassXC, qBittorrent, Rufus, Ventoy, Rainmeter, AutoHotkey… |
| Multimedia Tools | 59 | VLC, OBS Studio, Audacity, GIMP, Blender, Inkscape, Krita, Kdenlive, HandBrake… |
| Development | 56 | VS Code, Git, Node.js, Python, Docker, JetBrains Toolbox, Postman, Neovim, Zed… |
| Document | 25 | LibreOffice, Obsidian, Notepad++, Sumatra PDF, Joplin, Calibre, Zotero… |
| Microsoft Tools | 25 | PowerToys, Windows Terminal, .NET Runtimes, Sysinternals Suite, PowerShell… |
| Communications | 22 | Discord, Signal, Telegram, Slack, Teams, Thunderbird, Zoom, Vesktop, Session… |
| Games | 20 | Steam, Epic Games, GOG Galaxy, Heroic, Playnite, Moonlight, Sunshine, Parsec… |
| Pro Tools | 18 | Nmap, Wireshark, PuTTY, WinSCP, RustDesk, Mullvad VPN, WireGuard, Portmaster… |
| Browsers | 17 | Brave, Firefox, LibreWolf, Zen Browser, Thorium, Tor Browser, Vivaldi, Waterfox… |

**App Manager highlights:**
- **Install mode** — category sidebar, live search, multi-select, one-click install via winget
- **Uninstall mode** — fetches all winget-tracked apps on your system, remove with one click
- **MS Store support** — Store product IDs like `9PF4KZ2VN4W9` automatically use `--source msstore`
- **Chocolatey fallback** — if winget fails, falls back to Chocolatey automatically
- **Diagnostic log** — every install session writes a log to `%TEMP%\WinTooler_install_job.log`
- **Update All Apps** — launches `winget upgrade --all` in a live external window

### Tweaks — 23 System Optimizations

Safe, reversible tweaks with risk levels. Apply presets or pick individually. All tweaks support full undo.

**Performance** — High Performance Power Plan, Disable SysMain, Disable Search Indexing, Reduce Animations, Disable Hibernation, GameMode & GPU Scheduling

**Privacy** — Disable Telemetry & Advertising ID, Block Telemetry Hosts, Disable Activity History, Disable Location Services, Disable Webcam/Microphone

**UI & Bloat** — Dark Mode, Show File Extensions & Hidden Files, Remove Start Menu Ads, Clean Taskbar, Disable Bing in Start, Remove Bloatware, Remove Xbox Components, Disable Edge Bloat, Disable OneDrive Startup

**Preset Templates:** `Standard` · `Minimal` · `Heavy`

### Services Manager — 18 Services

Enable, disable, or set to Manual. Covers telemetry, Xbox, Remote Registry, Fax, WMP Network Share, and more. Color-coded by current state.

### Repair Tools

| Tool | What it does |
|---|---|
| SFC Scan | System File Checker — async with live log output |
| DISM Restore | Component store health repair |
| Clear Temp Files | User + system temp cleanup |
| Flush DNS | `ipconfig /flushdns` |
| Reset Windows Store | `wsreset.exe` |
| Create Restore Point | Manual snapshot on demand |
| Reset Network Stack | Full Winsock / TCP-IP reset |

### Windows Updates

Trigger update scans, pause for 7 days, or resume — without opening Settings.

---

## Quick Start

**Requirements**
- Windows 10 (Build 19041+) or Windows 11
- PowerShell 5.1 — built-in, no PowerShell 7 required
- **winget** (App Installer from Microsoft Store) — for the App Manager tab
- Administrator privileges — required for tweaks, services, and repairs

**How to run**
1. Download the latest release ZIP and extract it anywhere
2. Right-click `Launch.bat` → **Run as administrator**
3. CLI bootstrap checks dependencies and creates a System Restore Point
4. GUI opens automatically

> Without administrator rights, tweaks, services, and repair tools are disabled.

---

## Project Structure

```
WinToolerV1/
├── Launch.bat              <- Entry point — right-click → Run as administrator
├── WinToolerV1.ps1         <- Bootstrap, dependency check, restore point
├── WinToolerV1_icon.png    <- App icon
├── scripts/
│   └── gui.ps1             <- Full WPF GUI (~3 345 lines)
├── functions/
│   ├── tweaks.ps1          <- Tweak apply/undo logic
│   ├── repair.ps1          <- SFC, DISM, DNS, network reset
│   └── updates.ps1         <- Windows Update control
└── config/
    ├── wm_apps.json        <- 376-app catalog (WinUtil-sourced, 9 categories)
    ├── tweaks.json         <- 23 tweaks with risk levels and undo info
    └── services.json       <- 18 services with safe states
```

---

## Safety

- **System Restore Point** is automatically created at every launch before any changes
- All tweaks support full **undo** — revert individually or all at once
- No service is ever deleted — only toggled or set to Manual
- No changes happen until you explicitly click Apply or Install
- Every session is logged to `%TEMP%\WinToolerV1_<timestamp>.log`

---

## Language Support

WinTooler supports **English** and **Spanish** with a live toggle in the sidebar footer. All labels, titles, and buttons update instantly — no restart required.

---

## Changelog

### v0.6.1 BETA — Build 4100 *(March 2026)*

**App Manager — Critical Fixes**
- Fixed: apps not installing — `Start-Process -NoNewWindow` fails silently inside background jobs (no console to attach to); replaced with the `&` call operator which always blocks correctly
- Fixed: install job output returned 0 results — `.Success` was inaccessible on deserialized hashtables; jobs now emit `[PSCustomObject]` with explicit `-eq $true` comparison
- Fixed: only first app installed when multi-selecting — `Start-Job -ArgumentList ($array)` unrolls arrays; serialized as JSON string and deserialized inside the job instead
- Fixed: `Test-Path` on winget's Store symlink fails in elevated job context; now falls back to `Get-Command winget` automatically
- Fixed: 3 wrong winget package IDs: `starship` → `Starship.Starship`, `netbird` → `Netbird.Netbird`, `ForceAutoHDR.7gxycn08` → `7gxycn08.ForceAutoHDR`
- Fixed: MS Store apps (Tidal, TranslucentTB, Ambie) always failed — alphanumeric Store IDs now auto-detected and routed to `--source msstore`
- Fixed: UTF-8 BOM — box-drawing chars in comments caused PS5.1 to parse file as Windows-1252; file is now UTF-8 with BOM, all non-ASCII removed from PS code
- Fixed: `DispatcherTimer.Add_Tick` crash — removed `.GetNewClosure()` from timer handlers; job IDs stored as `$script:` variables
- Fixed: category click crash — removed `.GetNewClosure()` from all WPF event handlers; per-element data passed via the `Tag` property pattern
- New: 376-app catalog (expanded from 111, sourced from WinUtil)
- New: install job writes diagnostic log to `%TEMP%\WinTooler_install_job.log`

### v0.6.0 BETA — Build 4034 *(March 2026)*
- Initial public beta
- 111-app catalog, unified Install/Uninstall tab, EN/ES language toggle
- 23 tweaks, 18 services, async repair tools, Windows Update control

---

## License

[GPL-3.0](LICENSE) — free to use, modify, and distribute with attribution.

---

## Credits

App catalog sourced from [ChrisTitusTech/winutil](https://github.com/ChrisTitusTech/winutil).

Built with PowerShell + WPF — no Electron, no Python, no bloat.
