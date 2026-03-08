<div align="center">

```
 __    __ _       _____           _            __   ___
/ / /\ \ (_)_ __  \__  \___   ___ | | ___ _ __  \ \ / / |
\ \/  \/ / | '_ \   / /\/ _ \ / _ \| |/ _ \ '__|  \ V /| |
 \  /\  /| | | | | / / | (_) | (_) | |  __/ |      | | |_|
  \/  \/ |_|_| |_| \/   \___/ \___/|_|\___|_|       \_/ (_)
              W i n T o o l e r  V 1   -   by  E p e r e z 9 8
```

**A powerful, menu-driven PowerShell debloat and optimization tool for Windows 10 and 11**

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue?style=flat-square&logo=powershell)](https://microsoft.com/powershell)
[![Windows](https://img.shields.io/badge/Windows-10%20%7C%2011-0078D4?style=flat-square&logo=windows)](https://microsoft.com/windows)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)
[![Version](https://img.shields.io/badge/Version-1.0RC-orange?style=flat-square)](../../releases)
[![Made by](https://img.shields.io/badge/Made%20by-Eperez98-purple?style=flat-square)](https://github.com/Eperez98)

</div>

---

## Overview

**WinToolerV1** is a terminal-based PowerShell script that brings together the most effective Windows debloat and optimization techniques into a single, easy-to-use interactive menu. It runs natively in PowerShell on Windows 10 and 11, with a Linux-inspired dark terminal interface using ANSI colors and a clean layout.

---

## Features

| Key | Option | Description |
|-----|--------|-------------|
| `1` | Remove Bloatware Apps | Silently uninstall ~40 pre-installed Microsoft and OEM apps |
| `2` | Remove Specific App | Interactively search and remove any installed Appx package |
| `3` | Disable Telemetry and Tracking | Stop DiagTrack, block telemetry hosts, disable Advertising ID |
| `4` | Disable Edge / Browser Bloat | Kill Edge startup boost, Bing in Start, browser suggestions |
| `5` | Performance Tweaks | High Performance power plan, disable SysMain, reduce animations |
| `6` | UI / Visual Tweaks | Dark mode, clean taskbar, show file extensions, remove Start ads |
| `7` | Privacy Hardening | Disable camera/mic/location access, Timeline, activity tracking |
| `8` | Disable Unwanted Services | Disable ~15 non-essential background services (Xbox, telemetry...) |
| `9` | Install Essentials via winget | Auto-install 7-Zip, VLC, Firefox, Notepad++, PowerToys and more |
| `R` | Run Windows Repair | SFC scannow + DISM RestoreHealth + clear Temp + flush DNS |
| `U` | Windows Update | Force-check and install updates via PSWindowsUpdate module |
| `A` | Run Full Auto Debloat | Apply ALL tweaks automatically, creates restore point first |
| `L` | View Log File | Open the session log in Notepad |
| `Q` | Quit | Exit WinToolerV1 |

---

## Preview

```
==================================================================================================

  __    __ _       _____           _            __   ___
 / / /\ \ (_)_ __  \__  \___   ___ | | ___ _ __  \ \ / / |
 \ \/  \/ / | '_ \   / /\/ _ \ / _ \| |/ _ \ '__|  \ V /| |
  \  /\  /| | | | | / / | (_) | (_) | |  __/ |      | | |_|
   \/  \/ |_|_| |_| \/   \___/ \___/|_|\___|_|       \_/ (_)
               W i n T o o l e r  V 1   -   by  E p e r e z 9 8

              [Windows 11 Detected]  |  Build 26100  |  by Eperez98

==================================================================================================

  [*] YourUser   [T] 14:32:01   [LOG] C:\Users\...\WinToolerV1_20260307.log

  +-- DEBLOAT AND REMOVE APPS -----------------------------------------------------------------+

  [1]  [X]  Remove Bloatware Apps
            Uninstall pre-installed Microsoft and OEM bloatware

  [2]  [P]  Remove Specific App
            Interactively select and remove individual apps

  +-- TWEAKS AND OPTIMIZATION -----------------------------------------------------------------+

  [5]  [F]  Performance Tweaks
            Disable animations, adjust power plan, optimize services

  +-- ADVANCED --------------------------------------------------------------------------------+

  [A]  [!]  Run Full Auto Debloat
            Apply ALL recommended debloat + tweaks automatically
```

---

## Quick Start

### Option 1 - Download and Run (recommended)

1. Download `WinToolerV1.ps1` from [Releases](../../releases)
2. Right-click the file and select **"Run with PowerShell"**
3. If prompted, click **"Run anyway"** and accept the UAC elevation prompt

### Option 2 - Run from an elevated PowerShell terminal

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\WinToolerV1.ps1
```

### Option 3 - One-liner from GitHub (coming soon)

```powershell
irm https://raw.githubusercontent.com/Eperez98/WinToolerV1/main/WinToolerV1.ps1 | iex
```

> Always review scripts before running them from the internet.

---

## Requirements

| Requirement | Details |
|-------------|---------|
| **OS** | Windows 10 (build 1903+) or Windows 11 |
| **Shell** | PowerShell 5.1 or PowerShell 7+ |
| **Privileges** | Must be run as **Administrator** |
| **Internet** | Required only for options `9` (winget) and `U` (updates) |
| **Terminal** | Windows Terminal recommended for best ANSI color rendering |

---

## Safety and Restore Points

- **Option `A` (Full Auto Debloat)** automatically creates a **System Restore Point** before making any changes.
- For individual options, it is recommended to create a restore point manually first:

```powershell
Checkpoint-Computer -Description "Before WinToolerV1" -RestorePointType "MODIFY_SETTINGS"
```

- To undo changes: **Control Panel > System > System Protection > System Restore**

---

## Apps Removed (Option 1)

<details>
<summary>Click to expand the full list</summary>

**Microsoft Built-ins:**
- Microsoft 3D Builder, Bing Weather, Get Help, Get Started
- Microsoft Messaging, Office Hub, Solitaire Collection
- Mixed Reality Portal, News, Office Lens, Office OneNote
- Office Sway, OneConnect, People, Print3D
- Remote Desktop (preinstalled), Skype, To Do, Whiteboard
- Alarms, Camera, Mail and Calendar, Feedback Hub, Maps
- Sound Recorder, Xbox App, Xbox Gaming Overlay
- Xbox Game Overlay, Xbox Speech to Text, Your Phone
- Groove Music, Films and TV, Teams (personal), Cortana
- Clipchamp, Bing Search

**OEM / Third-party:**
- Spotify, Disney+, Facebook, TikTok
- Bubble Witch 3 Saga, Candy Crush Saga, Candy Crush Friends
- Adobe Photoshop Express

</details>

---

## Telemetry Blocked (Option 3)

The following hosts are redirected to `0.0.0.0` in your HOSTS file:

```
vortex.data.microsoft.com
settings-win.data.microsoft.com
watson.telemetry.microsoft.com
telecommand.telemetry.microsoft.com
oca.telemetry.microsoft.com
sqm.telemetry.microsoft.com
```

---

## Apps Installed via Winget (Option 9)

| App | Winget ID |
|-----|-----------|
| 7-Zip | `7zip.7zip` |
| VLC Media Player | `VideoLAN.VLC` |
| Notepad++ | `Notepad++.Notepad++` |
| Mozilla Firefox | `Mozilla.Firefox` |
| Google Chrome | `Google.Chrome` |
| Microsoft PowerToys | `Microsoft.PowerToys` |
| Git | `Git.Git` |
| Greenshot | `Greenshot.Greenshot` |

---

## Project Structure

```
WinToolerV1/
├── WinToolerV1.ps1     # Main script
├── README.md           # This file
└── LICENSE             # MIT License
```

---

## License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

---

## Author

**Eperez98**
- GitHub: [@Eperez98](https://github.com/Eperez98)

---

## Support

If this tool saved you time, consider giving it a star on GitHub — it helps others find it!

Found a bug or have a feature request? [Open an issue](../../issues/new).

---

<div align="center">
<sub>Made with care for the Windows community &nbsp;&middot;&nbsp; WinToolerV1 by Eperez98</sub>
</div>
