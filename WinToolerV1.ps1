#Requires -RunAsAdministrator
<#
.SYNOPSIS
    WinToolerV1 v0.6 BETA - Windows 10/11 Optimization and Debloat Utility
    Made by ErickP (Eperez98) | https://github.com/eperez98
    Inspired by ChrisTitusTech/winutil
.NOTES
    Run as Administrator. Requires Windows 10/11.
    v0.6 BETA RELEASE - Windows 11 ISO Downloader + Roadmap.
#>

Set-StrictMode -Off
$ErrorActionPreference = "Continue"

# STA CHECK
if ([System.Threading.Thread]::CurrentThread.ApartmentState -ne "STA") {
    $scriptPath = if ($MyInvocation.MyCommand.Path) { $MyInvocation.MyCommand.Path } else { $PSCommandPath }
    if ($scriptPath) {
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -STA -File `"`"$scriptPath`"`"" -Verb RunAs
    }
    exit
}

# ROOT DETECTION
if ($PSScriptRoot -and (Test-Path $PSScriptRoot)) {
    $global:Root = $PSScriptRoot
} elseif ($MyInvocation.MyCommand.Path) {
    $global:Root = Split-Path -Parent $MyInvocation.MyCommand.Path
} else {
    $global:Root = $PWD.Path
}

# GLOBALS
$global:AppName       = "WinToolerV1"
$global:AppVersion    = "0.6 BETA"
$global:AppAuthor     = "ErickP (Eperez98)"
$global:AppGitHub     = "https://github.com/eperez98"
$global:LogFile       = "$env:TEMP\WinToolerV1_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$global:OSBuild       = [System.Environment]::OSVersion.Version.Build
$global:IsWin11       = $global:OSBuild -ge 22000
$global:OSLabel       = if ($global:IsWin11) { "Windows 11" } else { "Windows 10" }
$global:AppUpdates    = @{}   # populated during pre-flight: Id -> "X.Y.Z available"

function global:Write-WTLog {
    param([string]$Msg, [string]$Level = "INFO")
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[$ts][$Level] $Msg" | Out-File -Append -FilePath $global:LogFile -Encoding UTF8
}

function global:Write-CLI {
    param([string]$Msg, [string]$Color = "White", [string]$Prefix = "")
    $line = if ($Prefix) { "  [$Prefix] $Msg" } else { "  $Msg" }
    Write-Host $line -ForegroundColor $Color
}

function global:Write-CLISection {
    param([string]$Title)
    Write-Host ""
    Write-Host "  --[ $Title ]" -ForegroundColor DarkCyan
    Write-Host ""
}

# BANNER
Clear-Host
Write-Host ""
Write-Host "  ==========================================" -ForegroundColor DarkCyan
Write-Host "    WinToolerV1  v0.6 BETA" -ForegroundColor Cyan
Write-Host "    by ErickP (Eperez98) - github.com/eperez98" -ForegroundColor DarkGray
Write-Host "    $($global:OSLabel) Build $($global:OSBuild)" -ForegroundColor DarkGray
Write-Host "  ==========================================" -ForegroundColor DarkCyan
Write-Host ""
Write-WTLog "WinToolerV1 v0.6 BETA starting on $env:COMPUTERNAME | $($global:OSLabel) Build $($global:OSBuild)"

# ADMIN CHECK
$id = [Security.Principal.WindowsIdentity]::GetCurrent()
if (-not (New-Object Security.Principal.WindowsPrincipal($id)).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-CLI "ERROR: Run as Administrator." "Red"
    Read-Host "  Press Enter to exit"
    exit 1
}
Write-CLI "Administrator  OK" "Green"

# =====================================================
#  STEP 1 - CREATE RESTORE POINT
# =====================================================
Write-CLISection "System Restore Point"
Write-CLI "Creating restore point before making any changes..." "Cyan"
try {
    Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
    $rpDesc = "WinToolerV1 pre-run $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
    Checkpoint-Computer -Description $rpDesc -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
    Write-CLI "Restore point created successfully." "Green"
    Write-WTLog "Pre-run restore point created: $rpDesc"
} catch {
    # Windows enforces a 24hr cooldown by default - bypass it so we can always create one
    $freq = Get-ItemProperty "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\SystemRestore" `
            -Name "SystemRestorePointCreationFrequency" -ErrorAction SilentlyContinue
    if (-not $freq) {
        Set-ItemProperty "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\SystemRestore" `
            -Name "SystemRestorePointCreationFrequency" -Type DWord -Value 0 -Force
        try {
            Checkpoint-Computer -Description $rpDesc -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
            Write-CLI "Restore point created (frequency limit bypassed)." "Green"
            Write-WTLog "Pre-run restore point created after bypassing frequency limit"
        } catch {
            Write-CLI "Restore point skipped: $_" "DarkYellow"
            Write-WTLog "Restore point failed: $_" "WARN"
        }
    } else {
        Write-CLI "Restore point skipped (24hr cooldown active - previous point still valid)." "DarkYellow"
        Write-WTLog "Restore point skipped: cooldown active"
    }
}

# =====================================================
#  STEP 2 - DEPENDENCY BOOTSTRAP
# =====================================================
Write-CLISection "Dependency Check"

function global:Find-Winget {
    $wg = Get-Command winget -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
    if ($wg -and (Test-Path $wg)) { return $wg }
    $candidates = @(
        "$env:LOCALAPPDATA\Microsoft\WindowsApps\winget.exe",
        "$env:ProgramFiles\WindowsApps\Microsoft.DesktopAppInstaller*\winget.exe",
        "$env:USERPROFILE\AppData\Local\Microsoft\WindowsApps\winget.exe"
    )
    foreach ($p in $candidates) {
        $f = Get-Item $p -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($f -and (Test-Path $f.FullName)) { return $f.FullName }
    }
    $appx = Get-AppxPackage -Name "Microsoft.DesktopAppInstaller" -ErrorAction SilentlyContinue
    if ($appx) {
        $c = Join-Path $appx.InstallLocation "winget.exe"
        if (Test-Path $c) { return $c }
    }
    return $null
}

function Write-DepRow {
    param([string]$Name, [string]$Status, [string]$Color = "Green")
    $pad = " " * ([Math]::Max(1, 22 - $Name.Length))
    Write-Host "  $Name$pad" -NoNewline -ForegroundColor DarkGray
    Write-Host $Status -ForegroundColor $Color
}

$global:WingetPath = Find-Winget
if ($global:WingetPath) {
    Write-DepRow "winget" "Found" "Green"
    Write-WTLog "winget: $($global:WingetPath)"
} else {
    Write-DepRow "winget" "Not found - installing..." "Yellow"
    Write-WTLog "Installing winget"
    try {
        $vcUrl  = "https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx"
        $vcPath = "$env:TEMP\VCLibs.appx"
        (New-Object System.Net.WebClient).DownloadFile($vcUrl, $vcPath)
        Add-AppxPackage $vcPath -ErrorAction SilentlyContinue
        $apiUrl = "https://api.github.com/repos/microsoft/winget-cli/releases/latest"
        $rel    = Invoke-RestMethod -Uri $apiUrl -Headers @{"User-Agent"="WinToolerV1"} -ErrorAction Stop
        $asset  = $rel.assets | Where-Object { $_.name -like "*.msixbundle" } | Select-Object -First 1
        $wgPath = "$env:TEMP\winget.msixbundle"
        (New-Object System.Net.WebClient).DownloadFile($asset.browser_download_url, $wgPath)
        Add-AppxPackage $wgPath -ErrorAction Stop
        Start-Sleep -Seconds 2
        $global:WingetPath = Find-Winget
        Write-DepRow "winget" (if ($global:WingetPath) {"Installed"} else {"Installed (restart may be needed)"}) "Green"
        Write-WTLog "winget installed"
    } catch {
        Write-DepRow "winget" "FAILED (Install tab disabled)" "Red"
        Write-WTLog "winget install failed: $_" "ERROR"
    }
}

$nuget = Get-PackageProvider -Name NuGet -ListAvailable -ErrorAction SilentlyContinue |
         Sort-Object Version -Descending | Select-Object -First 1
if ($nuget -and $nuget.Version -ge [Version]"2.8.5.201") {
    Write-DepRow "NuGet provider" "v$($nuget.Version)" "Green"
    Write-WTLog "NuGet: v$($nuget.Version)"
} else {
    Write-DepRow "NuGet provider" "Installing..." "Yellow"
    try {
        # Download the DLL directly - avoids the interactive prompt entirely
        $nugetDll  = "$env:ProgramFiles\PackageManagement\ProviderAssemblies
uget.8.5.208\Microsoft.PackageManagement.NuGetProvider.dll"
        $nugetDir  = Split-Path $nugetDll
        $nugetUrl  = "https://cdn.oneget.org/providers/Microsoft.PackageManagement.NuGetProvider-2.8.5.208.dll"
        if (-not (Test-Path $nugetDll)) {
            New-Item $nugetDir -ItemType Directory -Force | Out-Null
            (New-Object System.Net.WebClient).DownloadFile($nugetUrl, $nugetDll)
        }
        # Now import silently - no prompt
        Import-PackageProvider -Name NuGet -Force -ErrorAction SilentlyContinue | Out-Null
        Write-DepRow "NuGet provider" "Installed" "Green"
        Write-WTLog "NuGet installed via direct download"
    } catch {
        # Fallback: try the cmdlet with -Force (suppresses prompt when DLL exists)
        try {
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 `
                -Force -Confirm:$false -Scope AllUsers -ErrorAction Stop | Out-Null
            Write-DepRow "NuGet provider" "Installed" "Green"
            Write-WTLog "NuGet installed via Install-PackageProvider"
        } catch {
            Write-DepRow "NuGet provider" "Not installed (PSWindowsUpdate may be limited)" "DarkYellow"
            Write-WTLog "NuGet install failed: $_" "WARN"
        }
    }
}

$pswu = Get-Module -ListAvailable -Name PSWindowsUpdate -ErrorAction SilentlyContinue |
        Sort-Object Version -Descending | Select-Object -First 1
if ($pswu) {
    Write-DepRow "PSWindowsUpdate" "v$($pswu.Version)" "Green"
    Write-WTLog "PSWindowsUpdate: v$($pswu.Version)"
} else {
    Write-DepRow "PSWindowsUpdate" "Installing..." "Yellow"
    try {
        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction SilentlyContinue
        Install-Module -Name PSWindowsUpdate -Scope AllUsers -Force -AllowClobber -ErrorAction Stop
        Write-DepRow "PSWindowsUpdate" "Installed" "Green"
        Write-WTLog "PSWindowsUpdate installed"
    } catch {
        Write-DepRow "PSWindowsUpdate" "Failed" "Red"
        Write-WTLog "PSWindowsUpdate failed: $_" "ERROR"
    }
}

$policy = Get-ExecutionPolicy -Scope LocalMachine
if ($policy -in @("Restricted","AllSigned")) {
    try {
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine -Force -ErrorAction Stop
        Write-DepRow "ExecutionPolicy" "Set to RemoteSigned" "Green"
    } catch {
        Write-DepRow "ExecutionPolicy" "Could not set" "DarkYellow"
    }
} else {
    Write-DepRow "ExecutionPolicy" "$policy" "Green"
    Write-WTLog "ExecutionPolicy: $policy"
}

$dotnet = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" -ErrorAction SilentlyContinue).Release
$dotnetVer = if     ($dotnet -ge 533320) { "4.8.1" } `
             elseif ($dotnet -ge 528040) { "4.8"   } `
             elseif ($dotnet -ge 461808) { "4.7.2" } `
             elseif ($dotnet -ge 394802) { "4.6.2" } `
             else                        { "4.5+"  }
Write-DepRow ".NET Framework" $dotnetVer "Green"
Write-WTLog ".NET Framework: $dotnetVer (release=$dotnet)"

if ($global:WingetPath) {
    Write-DepRow "winget sources" "Refreshing..." "DarkGray"
    & $global:WingetPath source update --disable-interactivity 2>&1 | Out-Null
    Write-DepRow "winget sources" "Updated" "Green"
    Write-WTLog "winget source update done"
}

# =====================================================
#  STEP 3 - APP UPDATE CHECK (CLI, before GUI)
# =====================================================
if ($global:WingetPath) {
    Write-CLISection "Checking Installed App Updates"
    Write-CLI "Scanning for outdated apps via winget..." "Cyan"
    Write-CLI "(This runs once - results shown in the App Updates tab)" "DarkGray"

    try {
        $upgradeRaw = & $global:WingetPath upgrade --include-unknown --disable-interactivity 2>&1 |
                      Where-Object { $_ -match '\S' }

        $updateCount = 0
        $inTable     = $false
        foreach ($line in $upgradeRaw) {
            # Detect table start (header row with "Name" and "Version")
            if ($line -match 'Name\s+Id\s+Version\s+Available') { $inTable = $true; continue }
            if (-not $inTable) { continue }
            if ($line -match '^[-\s]+$') { continue }

            # Parse lines: columns are space-separated, Id is the key col
            $parts = $line -split '\s{2,}'
            if ($parts.Count -ge 3) {
                $id        = ($parts | Select-Object -Index 1).Trim()
                $current   = ($parts | Select-Object -Index 2).Trim()
                $available = if ($parts.Count -ge 4) { ($parts | Select-Object -Index 3).Trim() } else { "newer" }

                if ($id -and $available -and $available -ne "Unknown" -and $id -notmatch 'pinned') {
                    $global:AppUpdates[$id] = @{ Current=$current; Available=$available }
                    $updateCount++
                    $shortId = if ($id.Length -gt 35) { $id.Substring(0,32) + "..." } else { $id }
                    Write-CLI "$shortId  $current -> $available" "DarkYellow"
                    Write-WTLog "Update available: $id  $current -> $available"
                }
            }
        }

        if ($updateCount -eq 0) {
            Write-CLI "All apps are up to date." "Green"
            Write-WTLog "App update check: all current"
        } else {
            Write-CLI "" "White"
            Write-CLI "$updateCount update(s) available - see App Updates tab in GUI" "Yellow"
            Write-WTLog "App update check: $updateCount updates available"
        }
    } catch {
        Write-CLI "Could not check for updates: $_" "DarkYellow"
        Write-WTLog "App update check failed: $_" "WARN"
    }
}

Write-Host ""
Write-Host "  Dependency check complete. Launching GUI..." -ForegroundColor Green
Write-Host ""
Write-WTLog "Dependency bootstrap complete"

# =====================================================
#  LOAD FUNCTION MODULES
# =====================================================
$functionsPath = Join-Path $global:Root "functions"
if (Test-Path $functionsPath) {
    Get-ChildItem -Path $functionsPath -Filter "*.ps1" | Sort-Object Name | ForEach-Object {
        try {
            . $_.FullName
            Write-CLI "Loaded: $($_.Name)" "DarkGray"
            Write-WTLog "Loaded module: $($_.Name)"
        } catch {
            Write-CLI "WARN: Failed to load $($_.Name): $_" "Yellow"
            Write-WTLog "Failed to load $($_.Name): $_" "WARN"
        }
    }
}

# =====================================================
#  LOAD CONFIG
# =====================================================
$configPath = Join-Path $global:Root "config"
$global:AppCatalog    = @()
$global:TweaksCatalog = @()
$global:ServicesList  = @()

foreach ($pair in @(
    @{ Var="AppCatalog";    File="apps.json";     Label="Apps"     },
    @{ Var="TweaksCatalog"; File="tweaks.json";   Label="Tweaks"   },
    @{ Var="ServicesList";  File="services.json"; Label="Services" }
)) {
    $path = Join-Path $configPath $pair.File
    if (Test-Path $path) {
        try {
            $data = Get-Content $path -Raw | ConvertFrom-Json
            Set-Variable -Name $pair.Var -Value $data -Scope Global
            Write-CLI "$($pair.Label): $($data.Count) items" "DarkGray"
            Write-WTLog "Loaded $($pair.Label): $($data.Count)"
        } catch {
            Write-CLI "WARN: Failed to parse $($pair.File): $_" "Yellow"
        }
    } else {
        Write-CLI "WARN: $($pair.File) not found" "Yellow"
    }
}

# =====================================================
#  LAUNCH GUI
# =====================================================
$guiScript = Join-Path $global:Root "scripts\gui.ps1"

if (Test-Path $guiScript) {
    Write-WTLog "Launching GUI"
    try {
        . $guiScript

        # Show startup selection screen (language + theme)
        Write-Host "  Showing startup selection screen..." -ForegroundColor DarkGray
        $startChoice = Show-StartupScreen

        $global:UILanguage = $startChoice.Language  # "EN" or "ES"
        $global:UITheme    = $startChoice.Theme      # "Dark" or "Light"
        Write-Host "  Language: $($global:UILanguage)  |  Theme: $($global:UITheme)" -ForegroundColor DarkGray
        Write-WTLog "Startup choice: Language=$($global:UILanguage) Theme=$($global:UITheme)"

        Start-WinToolerGUI
    } catch {
        Write-Host ""
        Write-Host "  [ERROR] GUI crashed: $_" -ForegroundColor Red
        Write-Host "  Log: $global:LogFile" -ForegroundColor Yellow
        Write-WTLog "GUI crash: $_" "ERROR"
        Read-Host "  Press Enter to exit"
    }
} else {
    Write-Host "  [ERROR] GUI script not found: $guiScript" -ForegroundColor Red
    Write-WTLog "GUI script not found: $guiScript" "ERROR"
    Read-Host "  Press Enter to exit"
}
