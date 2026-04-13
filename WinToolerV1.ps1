#Requires -RunAsAdministrator
Set-StrictMode -Off
$ErrorActionPreference = "Continue"

# STA CHECK
if ([System.Threading.Thread]::CurrentThread.ApartmentState -ne "STA") {
    $scriptPath = if ($MyInvocation.MyCommand.Path) { $MyInvocation.MyCommand.Path } else { $PSCommandPath }
    if ($scriptPath) { Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -STA -File `"`"$scriptPath`"`"" -Verb RunAs }
    exit
}

# ROOT
if ($PSScriptRoot -and (Test-Path $PSScriptRoot)) { $global:Root = $PSScriptRoot }
elseif ($MyInvocation.MyCommand.Path)             { $global:Root = Split-Path -Parent $MyInvocation.MyCommand.Path }
else                                               { $global:Root = $PWD.Path }

# GLOBALS
$global:AppName    = "WinTooler"
$global:AppVersion = "V0.8 beta"
$global:AppBuild   = "5046"
$global:AppAuthor  = "ErickP (Eperez98)"
$global:AppGitHub  = "https://github.com/eperez98"
$global:BuildDate  = (Get-Date -Format "yyyy-MM-dd")
$global:BuildMode  = "Beta"
$global:LogFile    = "$env:TEMP\WinTooler_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$global:OSBuild    = [System.Environment]::OSVersion.Version.Build
$global:IsWin11    = $global:OSBuild -ge 22000
$global:OSLabel    = if ($global:IsWin11) { "Windows 11" } else { "Windows 10" }

function global:Write-WTLog { param([string]$Msg,[string]$Level="INFO"); "[$( Get-Date -Format 'yyyy-MM-dd HH:mm:ss')][$Level] $Msg" | Out-File -Append -FilePath $global:LogFile -Encoding UTF8 }
function global:Write-CLI {
    param([string]$Msg,[string]$Color="White",[string]$Prefix="")
    $line = if ($Prefix) { "  [$Prefix] $Msg" } else { "  $Msg" }
    Write-Host $line -ForegroundColor $Color
}

# TASK 4 — CLI BANNER
$w = 54
Write-Host ""
Write-Host ("  " + ("=" * $w)) -ForegroundColor Cyan
Write-Host "   WinTooler $($global:AppVersion)  -  Build $($global:AppBuild)" -ForegroundColor White
Write-Host "   Author  : $($global:AppAuthor)" -ForegroundColor Gray
Write-Host "   Core    : PowerShell GUI Utility" -ForegroundColor Gray
Write-Host "   Engine  : WinTooler Native Engine v0.7" -ForegroundColor Gray
Write-Host "   OS      : $($global:OSLabel) (Build $($global:OSBuild))" -ForegroundColor Gray
Write-Host ""
Write-Host "   Modules Loaded:" -ForegroundColor DarkCyan
Write-Host "    - App Manager       (winget / choco)" -ForegroundColor DarkGray
Write-Host "    - System Tweaks     (registry / services)" -ForegroundColor DarkGray
Write-Host "    - Repair Tools      (SFC / DISM / DNS)" -ForegroundColor DarkGray
Write-Host "    - Startup Manager   (registry / tasks)" -ForegroundColor DarkGray
Write-Host "    - DNS Changer       (adapter config)" -ForegroundColor DarkGray
Write-Host "    - Profile Backup    (JSON export/import)" -ForegroundColor DarkGray
Write-Host "    - ISO Creator       (Windows 11 media)" -ForegroundColor DarkGray
Write-Host ""
Write-Host "   Build Date : $($global:BuildDate)" -ForegroundColor Gray
Write-Host "   Mode       : $($global:BuildMode)" -ForegroundColor Yellow
Write-Host ""
Write-Host "   Starting GUI..." -ForegroundColor Cyan
Write-Host ("  " + ("=" * $w)) -ForegroundColor Cyan
Write-Host ""
Write-WTLog "WinTooler $($global:AppVersion) Build $($global:AppBuild) starting on $env:COMPUTERNAME | $($global:OSLabel) Build $($global:OSBuild)"

# ADMIN CHECK
$id = [Security.Principal.WindowsIdentity]::GetCurrent()
if (-not (New-Object Security.Principal.WindowsPrincipal($id)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-CLI "ERROR: Run as Administrator." "Red"; Read-Host "  Press Enter to exit"; exit 1
}
Write-CLI "Administrator OK" "Green" "OK"

# RESTORE POINT
Write-CLI "Creating restore point..." "Cyan"
try {
    Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
    $regPath = "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\SystemRestore"
    $prev = (Get-ItemProperty $regPath -Name "SystemRestorePointCreationFrequency" -ErrorAction SilentlyContinue).SystemRestorePointCreationFrequency
    Set-ItemProperty $regPath -Name "SystemRestorePointCreationFrequency" -Type DWord -Value 0 -Force -ErrorAction SilentlyContinue
    Checkpoint-Computer -Description "WinTooler pre-run $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop 2>$null
    if ($null -ne $prev) { Set-ItemProperty $regPath "SystemRestorePointCreationFrequency" -Type DWord -Value $prev -Force -ErrorAction SilentlyContinue }
    else { Remove-ItemProperty $regPath "SystemRestorePointCreationFrequency" -ErrorAction SilentlyContinue }
    Write-CLI "Restore point created." "Green" "OK"; Write-WTLog "Restore point created"
} catch { Write-CLI "Restore point skipped." "DarkYellow" "WARN"; Write-WTLog "Restore point failed: $_" "WARN" }

# WINGET
function global:Find-Winget {
    $wg = Get-Command winget -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
    if ($wg -and (Test-Path $wg)) { return $wg }
    foreach ($p in @("$env:LOCALAPPDATA\Microsoft\WindowsApps\winget.exe","$env:USERPROFILE\AppData\Local\Microsoft\WindowsApps\winget.exe")) {
        if (Test-Path $p) { return $p }
    }
    $appx = Get-AppxPackage -Name "Microsoft.DesktopAppInstaller" -ErrorAction SilentlyContinue
    if ($appx) { $c = Join-Path $appx.InstallLocation "winget.exe"; if (Test-Path $c) { return $c } }
    return $null
}
$global:WingetPath = Find-Winget
if ($global:WingetPath) { Write-CLI "winget found." "Green" "OK"; Write-WTLog "winget: $($global:WingetPath)" }
else { Write-CLI "winget not found." "Yellow" "WARN"; Write-WTLog "winget not found" "WARN" }

$pol = Get-ExecutionPolicy -Scope LocalMachine
if ($pol -in @("Restricted","AllSigned")) {
    try { Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine -Force -ErrorAction Stop } catch {}
}
if ($global:WingetPath) { & $global:WingetPath source update --disable-interactivity 2>&1 | Out-Null }
Write-WTLog "Bootstrap complete"

# LOAD MODULES
foreach ($mp in @("functions","functions\private","functions\public") | ForEach-Object { Join-Path $global:Root $_ }) {
    if (Test-Path $mp) {
        Get-ChildItem -Path $mp -Filter "*.ps1" | Sort-Object Name | ForEach-Object {
            try { . $_.FullName; Write-WTLog "Loaded: $($_.Name)" }
            catch { Write-CLI "WARN: $($_.Name): $_" "Yellow"; Write-WTLog "Load fail $($_.Name): $_" "WARN" }
        }
    }
}

# LOAD CONFIG
$configPath = Join-Path $global:Root "config"
$global:AppCatalog = @(); $global:TweaksCatalog = @(); $global:ServicesList = @()
foreach ($pair in @(@{Var="AppCatalog";File="apps.json";Label="Apps"},@{Var="TweaksCatalog";File="tweaks.json";Label="Tweaks"},@{Var="ServicesList";File="services.json";Label="Services"})) {
    $path = Join-Path $configPath $pair.File
    if (Test-Path $path) {
        try { $d = Get-Content $path -Raw | ConvertFrom-Json; Set-Variable -Name $pair.Var -Value $d -Scope Global; Write-WTLog "Loaded $($pair.Label): $($d.Count)" }
        catch { Write-CLI "WARN: $($pair.File): $_" "Yellow" }
    }
}

# LAUNCH GUI
$guiScript = Join-Path $global:Root "scripts\gui.ps1"
if (Test-Path $guiScript) {
    Write-WTLog "Launching GUI"
    try {
        . $guiScript
        $global:UILanguage = "EN"
        $global:UITheme    = "Light"
        Start-WinToolerGUI
    } catch {
        Write-Host "  [ERROR] GUI crashed: $_" -ForegroundColor Red
        Write-Host "  Log: $global:LogFile" -ForegroundColor Yellow
        Write-WTLog "GUI crash: $_" "ERROR"
        Read-Host "  Press Enter to exit"
    }
} else {
    Write-Host "  [ERROR] GUI not found: $guiScript" -ForegroundColor Red
    Read-Host "  Press Enter to exit"
}
