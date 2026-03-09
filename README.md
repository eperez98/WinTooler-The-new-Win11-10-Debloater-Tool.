<div align="center">

<img src="https://img.shields.io/badge/WinToolerV1-v0.6%20BETA-0067C0?style=for-the-badge&logo=windows&logoColor=white"/>

**A modern Windows 10/11 optimization and app management utility**  
Built with PowerShell 5.1 and a native WPF GUI — no .NET 6+, no runtimes, no dependencies to install.

Made by **[ErickP (Eperez98)](https://github.com/eperez98)**  
Inspired by [ChrisTitusTech/winutil](https://github.com/christitustech/winutil)

![Platform](https://img.shields.io/badge/platform-Windows%2010%20%7C%2011-0078D4?style=flat-square&logo=windows)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue?style=flat-square&logo=powershell)
![Version](https://img.shields.io/badge/version-v0.6%20BETA-orange?style=flat-square)
![License](https://img.shields.io/badge/license-GPL--3.0-green?style=flat-square)

</div>

---

## Table of Contents

- [Quick Start](#quick-start)
- [What's New in v0.6 BETA](#whats-new-in-v06-beta)
- [v0.5 BETA vs v0.6 BETA: Bug Report and Fix Log](#v05-beta-vs-v06-beta-bug-report-and-fix-log)
- [Features](#features)
- [Roadmap](#roadmap)
- [Project Structure](#project-structure)
- [Requirements](#requirements)
- [Known Limitations](#known-limitations)
- [License](#license)

---

## Quick Start

> **Requirements:** Windows 10/11 · PowerShell 5.1+ · Administrator rights

1. Download and extract **WinToolerV1_v06_BETA.zip** from [Releases](../../releases)
2. Right-click **`Launch.bat`** and select **Run as administrator**
3. Accept the UAC prompt
4. Wait for the CLI boot sequence to complete (14 steps, roughly 10 seconds)
5. Pick your **language** on the startup screen
6. Click **Launch WinToolerV1**

<details>
<summary>Alternative — run from PowerShell directly</summary>

```powershell
# Open PowerShell as Administrator, then:
Set-ExecutionPolicy Bypass -Scope Process -Force
cd "C:\path\to\WinToolerV1"
.\WinToolerV1.ps1
```

</details>

---

## What's New in v0.6 BETA

| Change | Details |
|---|---|
| Full light mode | Every control, panel, toolbar, card and label now correctly displays in light colors. Previously only the window chrome changed. |
| Startup screen rebuilt | Language-only picker with a clean layout. No more clipped Launch button. Auto-sizes to content at any DPI. |
| ISO Downloader removed | Feature removed pending a stable, non-rate-limited solution. Was unreliable across different network environments. |
| Nav active state fixed | The active tab highlight now correctly reflects which tab is open. Was stuck on dark blue in light mode. |
| Dynamic panel theming | App tiles, tweak cards, service rows, uninstall rows, and update rows are all repainted correctly on theme change. |
| Dark mode removed | Application is now light mode only. Removes significant complexity and eliminates an entire class of theme bugs. |
| Output consoles | Repair and Windows Update output areas now display readable dark text on a light background instead of green-on-black. |

---

## v0.5 BETA vs v0.6 BETA: Bug Report and Fix Log

> Every issue listed below is fully resolved in v0.6 BETA. If you are still on v0.5, download the latest release from [Releases](../../releases).

---

### BUG-01 · Startup screen: Launch button clipped at the bottom

**Reported in:** v0.5 BETA &nbsp;|&nbsp; **Status:** Fixed in v0.6 BETA

**What happened:**
The **Launch WinToolerV1** button on the startup screen was partially or fully hidden at the bottom of the window. Because `ResizeMode="NoResize"` was set, users could not resize the window to reach it.

**Root cause:**
The Launch button was injected into the layout dynamically via `Add_ContentRendered` — after the window had already been measured and sized. WPF does not re-expand a fixed-height window for runtime content additions, so the extra row was silently clipped.

**Fix in v0.6:**
Button moved directly into the XAML Grid at declaration time so WPF accounts for it in the initial layout pass. `SizeToContent="Height"` added to the window so it always auto-fits its content at any DPI or scale setting.

---

### BUG-02 · Theme toggle icon showing literal text `&#x2600;` instead of the sun or moon symbol

**Reported in:** v0.5 BETA &nbsp;|&nbsp; **Status:** Fixed in v0.6 BETA

**What happened:**
After clicking the Dark/Light toggle, the button label changed from the expected sun or moon character to the raw entity string `&#x2600;` or `&#x263D;` displayed as plain text.

**Root cause:**
XML entities like `&#x2600;` are decoded by the XAML parser at load time only. Assigning the same string at runtime through PowerShell passes it as a literal string — no entity decoding happens.

```powershell
# v0.5 — broken: assigns the 8-character string literally
$ctrl["ThemeIcon"].Text = if ($dark) { "&#x2600;" } else { "&#x263D;" }

# v0.6 — fixed: assigns the actual Unicode codepoint
$ctrl["ThemeIcon"].Text = if ($dark) { [char]0x2600 } else { [char]0x263D }
```

**Resolution in v0.6:**
Dark mode and theme toggle were removed entirely. This bug is no longer applicable.

---

### BUG-03 · Light mode incomplete — most tabs and panels staying dark

**Reported in:** v0.5 BETA &nbsp;|&nbsp; **Status:** Fixed in v0.6 BETA

**What happened:**
Selecting Light mode on the startup screen or clicking the toggle in the sidebar only changed the window background and sidebar. Everything else — app tiles, tweak cards, service rows, all toolbars, all bottom action bars, comboboxes, search boxes, output consoles, and text labels — remained dark.

**Root cause (two separate layers):**

The first layer was that dynamic panels (app rows, tweak cards, service rows, uninstall rows, update rows) were built in PowerShell using hardcoded dark RGB values (`FromRgb(20,20,20)`, `Brushes::White`) with no connection to the theme token system.

The second layer was that XAML-declared structural surfaces — toolbars, bottom action bars, the category sidebar, output areas — had hardcoded `Background="#0D0D0D"` or `"#0A0A0A"` values with no `x:Name` assigned, meaning `Apply-Theme` had no way to reference them at runtime.

**Fix in v0.6:**
All XAML dark color values replaced with light equivalents at the source. All dynamic panel builders updated to read from the `$script:T` theme token palette. `Apply-Theme` extended to repaint all dynamic panels, all named structural borders, sidebar texts, and the footer card in-place on every theme change. Dark mode was then removed entirely, eliminating the whole category of problem permanently.

---

### BUG-04 · ISO Downloader frozen indefinitely on "Fetching..."

**Reported in:** v0.5 BETA (feature introduced during v0.6 development) &nbsp;|&nbsp; **Status:** Feature removed in v0.6 BETA

**What happened:**
Clicking **Get Download Link** in the ISO Downloader tab started the background job, displayed "Fetching..." in the spinner, and never completed. The spinner ran indefinitely regardless of edition, architecture, or language selected. No download link was ever returned.

**Root cause:**
The Microsoft Software Download API requires an active browser session cookie established by first visiting the download page. A direct API call from a script without that session step returns an empty or error response. The v0.5 job had no session-establishment step, so all downstream calls failed silently — leaving the polling timer waiting forever for a result that would never come.

A secondary issue: the UUP Dump fallback method does not serve direct `.iso` download links. It serves build metadata only, not downloadable files.

**Resolution in v0.6:**
The ISO Downloader tab has been removed from this release. A reliable implementation requires either a proper session flow that works consistently across all regions and network environments, or a third-party bridge. This will be re-evaluated for a future version.

---

### BUG-05 · Active nav button not reflecting light mode

**Reported in:** v0.5 / v0.6 BETA &nbsp;|&nbsp; **Status:** Fixed in v0.6 BETA

**What happened:**
Even after switching to light mode, the currently active navigation button in the sidebar stayed dark blue (`#1E3A5F` background, white text) — clearly a dark-mode color sitting against the white sidebar.

**Root cause:**
`NavBtnActive` was a XAML `Style` resource with hardcoded `Background="#1E3A5F"` and `Foreground="White"`. When `switchPage` assigned this style to a button, WPF's style precedence system took over — a direct property assignment from `Apply-Theme` cannot override a value set by a style.

**Fix in v0.6:**
`switchPage` no longer assigns a style object. It now directly sets `Background`, `Foreground`, and `FontWeight` on each button using `$script:T` token values at the moment of navigation. `Apply-Theme` runs the same logic to repaint the active button whenever called.

---

## Features

### Install Apps
111 apps across 10 categories: Browsers, Communications, Development, Documents, Gaming, Media, Network, Productivity, Security, Utilities. Category sidebar with live filtering, live search bar, macOS-style icon tiles with per-app status badges, progress bar, and smart retry logic for scope conflicts and hash errors.

### Uninstall Apps
Queries `winget list` live when the tab is opened. Live search filter, checkbox multi-select, and silent bulk uninstall.

### App Updates
Scanned automatically at boot in the CLI window before the GUI opens. Red badge on the sidebar nav shows the update count. Update All, Update Selected, and Re-Check buttons. Smart retry: version-mismatch exit code retries with `--force`; hash mismatch clears the cache and retries.

### Tweaks
23 system tweaks organized by Low, Medium, and High risk. Templates: **None**, **Minimal** (6 safe tweaks), **Standard** (13 tweaks), **Heavy** (20 tweaks — includes irreversible bloatware removal). Live search, select all, select none.

### Services
18 Windows background services with live Automatic, Manual, and Disabled status badges. Bulk Disable, Set Manual, and Re-Enable actions.

### Repair and Maintenance
Six action cards: **SFC + DISM** (runs asynchronously with live streaming output so the GUI stays responsive), **Clear Temp Files**, **Flush DNS**, **Reset Microsoft Store**, **Create Restore Point**, **Network Reset**.

### Windows Update
Check and install updates via PSWindowsUpdate. Pause for 7 days. Resume paused updates.

### English and Espanol
Full bilingual UI. Language is selected at startup. Every label, button, and status message switches language.

---

## Roadmap

> These are planned features, not committed release dates.

---

### v0.7 BETA — Tools Expansion

| Feature | Description |
|---|---|
| **Driver Updater** | Scan and update outdated device drivers via winget or direct vendor sources |
| **Startup Manager** | View, enable, and disable startup programs and scheduled tasks |
| **Hosts File Editor** | Visual editor for the Windows hosts file with built-in ad-block and privacy presets |
| **In-App Language Toggle** | Switch between EN and ES at any time without restarting the application |
| **Disk Cleaner** | Deep scan for junk files, old Windows update caches, WinSxS backups, and Delivery Optimization leftovers |
| **Profile Backup** | Export and restore your tweak and service configuration as a shareable JSON file |

---

### v0.8 BETA — Power Features

| Feature | Description |
|---|---|
| **Performance Benchmarks** | Before and after scoring for CPU, RAM, and disk using built-in WinSAT metrics |
| **Registry Cleaner** | Safe scan for orphaned registry keys from uninstalled software, with a preview step and full undo support |
| **WSL Manager** | Install, update, and manage Windows Subsystem for Linux distros from the GUI |
| **Custom Tweak Builder** | Create and save your own registry, service, and Group Policy tweaks inside the app |
| **Multi-Language Expansion** | Add French, Portuguese, German, and Italian UI translations |
| **ISO Downloader (re-evaluated)** | Re-implement with a stable method that works reliably across all regions and network environments |

---

### v1.0 Release Candidate — Stability and Polish

The 1.0 RC will focus on completeness and production readiness rather than new features.

| Goal | Details |
|---|---|
| **Zero known bugs** | All open issues from the BETA cycle resolved before tagging 1.0 |
| **Installer and Uninstaller** | Proper `.msi` or NSIS-based installer with a Start Menu shortcut and clean uninstall |
| **Auto-update check** | Notify the user in-app when a new version is available on GitHub |
| **Code-signed script** | Signed `.ps1` to eliminate SmartScreen warnings on first run |
| **Full OS compatibility test** | Verified on Windows 10 (1809, 21H2), Windows 11 (22H2, 23H2, 24H2), Intel, AMD, and ARM64 |
| **Wiki and documentation** | Full GitHub wiki with per-tweak explanations, risk descriptions, and screenshots |

---

## GUI Boot Sequence

| # | Stage | Description |
|:---:|---|---|
| 01 | STA Thread Check | Auto-restarts with `-STA` flag if needed for WPF compatibility |
| 02 | Root Detection | 3-tier path fallback using `$PSScriptRoot`, script path, and working directory |
| 03 | Admin Verification | Exits cleanly with a message if not running as Administrator |
| 04 | Restore Point | Creates a system snapshot before any changes; bypasses the 24-hour cooldown |
| 05 | winget Bootstrap | Auto-installs winget if not present on the system |
| 06 | NuGet Provider | Silent DLL download — eliminates the interactive PSGallery install prompt |
| 07 | PSWindowsUpdate | Auto-installs the module from PSGallery if missing |
| 08 | Execution Policy | Sets `RemoteSigned` for the current process scope if restricted |
| 09 | .NET Framework | Detects installed version from 4.5 through 4.8.1 |
| 10 | winget Sources | Refreshes package metadata |
| 11 | App Update Scan | Runs `winget upgrade`, parses results for the App Updates tab |
| 12 | Module Load | Dot-sources `repair.ps1`, `tweaks.ps1`, `updates.ps1` |
| 13 | Config Load | Loads `apps.json`, `tweaks.json`, `services.json` into memory |
| 14 | Startup Screen | Language picker, then launches the main GUI window |

---

## Project Structure

```
WinToolerV1\
  WinToolerV1.ps1        <- Main launcher and 14-step boot sequence
  Launch.bat             <- Double-click entry point (runs as Admin with -STA)
  README.md
  scripts\
    gui.ps1              <- Full WPF GUI and startup screen (~2900 lines)
  functions\
    tweaks.ps1           <- 23 tweak functions
    repair.ps1           <- Async SFC/DISM, DNS flush, temp clean, restore, network reset
    updates.ps1          <- PSWindowsUpdate integration
  config\
    apps.json            <- 111 apps across 10 categories (all Default: false)
    tweaks.json          <- 23 tweaks with risk levels (all Default: false)
    services.json        <- 18 Windows services with descriptions
```

---

## Requirements

| | |
|---|---|
| OS | Windows 10 (build 1809 or later) or Windows 11 |
| PowerShell | 5.1 or later (built into Windows — no extra install needed) |
| Privileges | Administrator (UAC prompt fires automatically via Launch.bat) |
| Network | Required for Install Apps, App Updates, and Windows Update tabs only |
| winget | Auto-installed at boot if missing |
| NuGet provider | Auto-installed silently at boot |
| PSWindowsUpdate | Auto-installed from PSGallery at boot if missing |

---

## Known Limitations

- **Heavy template tweaks are irreversible.** The boot-time restore point is your primary safety net — confirm it was created before applying the Heavy template.
- **Language cannot be changed after launch** without a full restart. In-app language toggle is planned for v0.7.
- **System Protection must be enabled on C:** for restore points to work. This may be disabled by Group Policy on managed or enterprise machines.
- **winget must be able to reach the internet** for Install, App Updates, and Windows Update. Tweaks, Services, and Repair work fully offline.

---

## License

[GPL-3.0](https://www.gnu.org/licenses/gpl-3.0.html) — Free to use, modify, and distribute. Any derivative work must also be released under GPL-3.0 and remain open source.

---

<div align="center">

Made with care by **[ErickP (Eperez98)](https://github.com/eperez98)**

*If this tool saved you time, a star on the repo goes a long way.*

</div>
