# WinTooler — V0.8 beta · Build 5046

<p align="center">
  <img src="WinToolerV1_icon.png" width="96" alt="WinTooler"/>
</p>

<p align="center">
  <b>A modern Windows 11 optimization, debloat and deployment toolkit</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/version-V0.8%20beta-6A0DAD?style=flat-square"/>
  <img src="https://img.shields.io/badge/build-5046-informational?style=flat-square"/>
  <img src="https://img.shields.io/badge/released-April%202026-orange?style=flat-square"/>
  <img src="https://img.shields.io/badge/platform-Windows%2010%2F11-0078D4?style=flat-square"/>
  <img src="https://img.shields.io/badge/license-GPL--3.0-green?style=flat-square"/>
  <img src="https://img.shields.io/badge/PowerShell-5.1%2B-blue?style=flat-square"/>
</p>

---

## What's new in V0.8 beta — Build 5046

### Power Tools (6 new pages)

| Tool | Description |
|---|---|
| **Hosts File Editor** | Visual editor for the Windows hosts file. Ad-block and privacy presets built in |
| **Driver Updater** | WMI scan of installed drivers, outdated detection, winget update integration |
| **Performance Benchmarks** | WinSAT runner with CPU / RAM / Disk / GPU score cards and history loader |
| **Registry Cleaner** | Three-pass orphaned key scan, per-item preview, `reg.exe` backup before clean |
| **WSL Manager** | Full Linux distro lifecycle — install, set default, launch, remove — no terminal needed |
| **Custom Tweak Builder** | Form-based registry tweak creator with apply/undo and JSON persistence |

### WinUtil Tweaks Integration (Build 5046)

The System Tweaks catalog was expanded from **23 to 58 tweaks** by integrating the full WinUtil tweak catalogue. New tweaks span 5 categories:

| Category | Count | Examples |
|---|---|---|
| Performance | 10 | Set Services to Manual, Disable Xbox Game DVR, Run Disk Cleanup |
| Privacy | 12 | Disable WPBT, Disable PS7 Telemetry, Block Adobe Network, Disable Copilot |
| UI & Explorer | 10 | Remove Widgets, End Task on Taskbar, Revert Start Menu, Create Restore Point |
| Bloatware | 5 | Remove ALL Store Apps, Remove Widgets, Disable Consumer Features |
| Advanced | 21 | Remove Edge, Set UTC, Remove OneDrive, Classic Context Menu, Disable IPv6 |

Templates updated — **Standard** now applies 20 tweaks, **Minimal** 8, **Heavy** 36.

---

## Full Feature Overview

| Module | Description |
|---|---|
| **App Manager** | 376 apps, 9 categories — winget primary, Chocolatey auto-installed on demand |
| **System Tweaks** | 58 tweaks across 5 categories + Custom Tweak Builder |
| **Services Manager** | Enable / Disable / Manual for 18 Windows services |
| **Repair & Maintenance** | SFC+DISM, Clear Temp, DNS flush, Restore Point, Network Reset, Delete All Restore Points |
| **Startup Manager** | Registry Run keys + scheduled tasks, auto-starts TaskScheduler service |
| **DNS Changer** | Cloudflare, Google, Quad9, OpenDNS, or any custom primary/secondary pair |
| **Profile Backup** | Export / import tweak configuration as named JSON profiles |
| **Hosts File Editor** | Visual hosts editor. Ad-block preset (10 domains) + privacy preset (8 MS telemetry endpoints) |
| **Driver Updater** | Scan via `Win32_PnPSignedDriver`, flag drivers > 3 years old, update via winget |
| **Performance Benchmarks** | `winsat formal` runner with 5 score cards + history reader from DataStore XML |
| **Registry Cleaner** | 3-pass scan (Uninstall keys, HKCU Run, HKLM Run), backup + selective clean |
| **WSL Manager** | Install/remove/set-default/launch distros. Enable WSL2 in one click |
| **Custom Tweak Builder** | Name + description + risk + registry path/value form. Export/import JSON |
| **ISO Creator** | Mount official Win11 ISO → bloat removal → driver injection → app embedding → rebuild |
| **Light / Dark Mode** | Full Windows 11 Fluent palette, live switch, Segoe UI Symbol fallback for Win10 < 19041 |
| **EN / ES Language** | English and Spanish UI with live toggle, no restart required |

---

## Requirements

- Windows 10 (build 19041+) or Windows 11
- PowerShell 5.1 (built into Windows — no install needed)
- **Run as Administrator**
- Internet connection for App Manager (winget / Chocolatey)
- ISO Creator: ~8 GB free disk space, DISM (built-in)
- WSL Manager: WSL2 feature (tool can enable it for you)
- Performance Benchmarks: WinSAT is built into Windows

---

## Installation

No installer. Download, extract, right-click.

```
1. Download and extract WinTooler_V08beta_Build5046.zip
2. Right-click Launch.bat  →  Run as administrator
```

On first launch WinTooler bootstraps winget if absent, creates a System Restore Point, and loads all catalogs.

---

## Project Structure

```
BUILD5046/
├── WinToolerV1.ps1                         Main launcher
├── Launch.bat                              Batch shortcut
├── scripts/
│   └── gui.ps1                             WPF GUI (~6900 lines)
├── functions/
│   ├── public/Invoke-Win11ISOCreator.ps1
│   ├── private/  (Invoke-Oscdimg, Get-WindowsDownload, Convert-ESDtoISO)
│   ├── repair.ps1
│   └── tweaks.ps1                          707 lines — 58 tweak functions
├── config/
│   ├── wm_apps.json        (376 apps, 9 categories)
│   ├── tweaks.json         (58 tweaks, 5 categories)
│   ├── services.json       (18 services)
│   ├── custom_tweaks.json  (user-created — auto-generated)
│   └── themes.json         (Light / Dark palette tokens)
└── docs/
    ├── README.md
    ├── RELEASE_NOTES.html
    ├── RELEASE_NOTES.txt
    └── screenshots/
```

---

## Roadmap

**v1.0 RC:** `.msi` / NSIS installer, in-app update notifications from GitHub, code-signed script to eliminate SmartScreen warnings, full OS test coverage (Win10 21H2, Win11 22H2 / 23H2 / 24H2, Intel / AMD / ARM64).

---

## Changelog summary

| Build | Version | Date | Highlights |
|---|---|---|---|
| 5046 | V0.8 beta | Apr 2026 | WinUtil tweak integration — 23 → 58 tweaks; template overhaul |
| 5045 | V0.8 beta | Mar 2026 | 6 Power Tools: Hosts Editor, Driver Updater, Benchmarks, Registry Cleaner, WSL Manager, Custom Tweaks |
| 5040 | V0.7.1 beta | Mar 2026 | All 5 limitations resolved: ADK fallback, winget bootstrap, Chocolatey auto-install, TaskScheduler, icon compat |
| 5035 | V0.7 beta | Mar 2026 | ISO Creator, bloatware removal, app embedding, Delete Restore Points, full dark mode |

---

## License

GPL-3.0 © ErickP (Eperez98) — [github.com/eperez98](https://github.com/eperez98)
