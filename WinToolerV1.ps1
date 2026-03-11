#Requires -RunAsAdministrator
<#
.SYNOPSIS
    WinToolerV1 v0.6.1 BETA Build 4.100 - Windows 10/11 Optimization and Debloat Utility
    Made by ErickP (Eperez98) | https://github.com/eperez98
    Inspired by ChrisTitusTech/winutil
.NOTES
    Run as Administrator. Requires Windows 10/11.
    v0.6.1 BETA Build 4.100 RELEASE - Windows 11 ISO Downloader + Roadmap.
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
$global:AppVersion    = "0.6.1 BETA Build 4.100"
$global:AppAuthor     = "ErickP (Eperez98)"
$global:AppGitHub     = "https://github.com/eperez98"
$global:LogFile       = "$env:TEMP\WinToolerV1_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$global:OSBuild       = [System.Environment]::OSVersion.Version.Build
$global:IsWin11       = $global:OSBuild -ge 22000
$global:OSLabel       = if ($global:IsWin11) { "Windows 11" } else { "Windows 10" }

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
Write-Host "    WinToolerV1  v0.6.1 BETA Build 4.100" -ForegroundColor Cyan
Write-Host "    by ErickP (Eperez98) - github.com/eperez98" -ForegroundColor DarkGray
Write-Host "    $($global:OSLabel) Build $($global:OSBuild)" -ForegroundColor DarkGray
Write-Host "  ==========================================" -ForegroundColor DarkCyan
Write-Host ""
Write-WTLog "WinToolerV1 v0.6.1 BETA Build 4.100 starting on $env:COMPUTERNAME | $($global:OSLabel) Build $($global:OSBuild)"

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

    # Remove any previous WinToolerV1 restore points to avoid clutter
    try {
        $oldPoints = Get-ComputerRestorePoint -ErrorAction SilentlyContinue |
                     Where-Object { $_.Description -like "WinToolerV1*" }
        if ($oldPoints) {
            foreach ($pt in $oldPoints) {
                $null = vssadmin delete shadows /shadow="{$($pt.SequenceNumber)}" /quiet 2>$null
            }
            # Preferred method via WMI
            $oldPoints | ForEach-Object {
                $null = (Get-WmiObject -Class Win32_ShadowCopy -ErrorAction SilentlyContinue |
                         Where-Object { $_.ID -and $_.Description -like "WinToolerV1*" } |
                         Remove-WmiObject -ErrorAction SilentlyContinue)
            }
            Write-CLI "Removed $($oldPoints.Count) previous WinTooler restore point(s)." "DarkGray"
            Write-WTLog "Removed $($oldPoints.Count) old restore point(s)"
        }
    } catch {
        # Non-fatal — continue to create new restore point
        Write-WTLog "Could not remove old restore points: $_" "WARN"
    }

    $rpDesc = "WinToolerV1 pre-run $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
    # Temporarily set frequency to 0 to bypass the 24hr cooldown warning, then restore
    $regPath = "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\SystemRestore"
    $prevFreq = Get-ItemProperty $regPath -Name "SystemRestorePointCreationFrequency" -ErrorAction SilentlyContinue
    $prev = if ($prevFreq) { $prevFreq.SystemRestorePointCreationFrequency } else { $null }
    Set-ItemProperty $regPath -Name "SystemRestorePointCreationFrequency" -Type DWord -Value 0 -Force -ErrorAction SilentlyContinue
    Checkpoint-Computer -Description $rpDesc -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop 2>$null
    # Restore original value (or remove if it wasn't set before)
    if ($null -ne $prev) {
        Set-ItemProperty $regPath -Name "SystemRestorePointCreationFrequency" -Type DWord -Value $prev -Force -ErrorAction SilentlyContinue
    } else {
        Remove-ItemProperty $regPath -Name "SystemRestorePointCreationFrequency" -ErrorAction SilentlyContinue
    }
    Write-CLI "Restore point created successfully." "Green"
    Write-WTLog "Pre-run restore point created: $rpDesc"
} catch {
    Write-CLI "Restore point skipped (system protection may be off on C:\)." "DarkYellow"
    Write-WTLog "Restore point failed: $_" "WARN"
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
    # NuGet not required - Windows Updates tab uses winget directly
    Write-DepRow "NuGet provider" "Not required (using winget)" "DarkGray"
    Write-WTLog "NuGet: skipped - Windows Updates uses winget"
}

# PSWindowsUpdate not used - Windows Updates handled via winget + UsoClient
Write-WTLog "PSWindowsUpdate: skipped - using winget"

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
# =====================================================
#  STEP 3 - APP UPDATE CHECK  (skipped at startup — runs in background from GUI)
# =====================================================
# Update scan moved to GUI background job (BtnReCheckUpdates / ModePillUpdates).
# Avoids blocking the CLI window before the GUI opens.
Write-WTLog "App update scan deferred to GUI background job"

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
