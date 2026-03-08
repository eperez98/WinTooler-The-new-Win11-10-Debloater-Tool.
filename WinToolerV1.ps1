#Requires -RunAsAdministrator
<#
.SYNOPSIS
    WinToolerV1 - Windows 10/11 Debloat and Optimization Tool
    Made by Eperez98
.DESCRIPTION
    A powerful, menu-driven debloat and optimization tool for Windows 10 and 11.
#>

# -----------------------------------------------
#  CONFIGURATION AND GLOBALS
# -----------------------------------------------
$Host.UI.RawUI.WindowTitle = "WinToolerV1 - by Eperez98"
try { $Host.UI.RawUI.BufferSize = New-Object System.Management.Automation.Host.Size(120, 9999) } catch {}
try { $Host.UI.RawUI.WindowSize = New-Object System.Management.Automation.Host.Size(100, 42)  } catch {}

$script:LogFile = "$env:TEMP\WinToolerV1_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$script:OSBuild = [System.Environment]::OSVersion.Version.Build
$script:IsWin11 = $script:OSBuild -ge 22000

# -----------------------------------------------
#  COLOR PALETTE
# -----------------------------------------------
$C = @{
    Reset   = [char]27 + "[0m"
    Bold    = [char]27 + "[1m"
    Dim     = [char]27 + "[2m"
    Red     = [char]27 + "[91m"
    Green   = [char]27 + "[92m"
    Yellow  = [char]27 + "[93m"
    Blue    = [char]27 + "[94m"
    Magenta = [char]27 + "[95m"
    Cyan    = [char]27 + "[96m"
    White   = [char]27 + "[97m"
    Gray    = [char]27 + "[90m"
}

# -----------------------------------------------
#  LOGGING
# -----------------------------------------------
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[$ts][$Level] $Message" | Out-File -Append -FilePath $script:LogFile
}

# -----------------------------------------------
#  DRAW HELPERS
# -----------------------------------------------
function Write-Color {
    param([string]$Text, [string]$Color = $C.White, [switch]$NoNewline)
    if ($NoNewline) { Write-Host "$Color$Text$($C.Reset)" -NoNewline }
    else            { Write-Host "$Color$Text$($C.Reset)" }
}

function Draw-Line {
    param([int]$Width = 98, [string]$LineChar = "=", [string]$Color = $C.Gray)
    Write-Color ($LineChar * $Width) $Color
}

function Center-Text {
    param([string]$Text, [int]$Width = 98, [string]$Color = $C.White)
    $pad = [math]::Max(0, ($Width - $Text.Length) / 2)
    Write-Color (" " * [int]$pad + $Text) $Color
}

# -----------------------------------------------
#  HEADER BANNER
# -----------------------------------------------
function Draw-Header {
    Clear-Host
    Write-Host ""
    Write-Color ("=" * 98) $C.Cyan
    Write-Host ""
    Write-Color "  $($C.Bold)$($C.Cyan) __    __ _       _____           _            __      ___  " $C.Cyan
    Write-Color "  $($C.Bold)$($C.Cyan)/ / /\ \ (_)_ __  \__  \___   ___ | | ___ _ __  \ \    / / | " $C.Cyan
    Write-Color "  $($C.Bold)$($C.Cyan)\ \/  \/ / | '_ \   / /\/ _ \ / _ \| |/ _ \ '__|  \ \/\/ /| | " $C.Cyan
    Write-Color "  $($C.Bold)$($C.Cyan) \  /\  /| | | | | / / | (_) | (_) | |  __/ |      \  / | | " $C.Cyan
    Write-Color "  $($C.Bold)$($C.Cyan)  \/  \/ |_|_| |_| \/   \___/ \___/|_|\___|_|       \/  |_| " $C.Cyan
    Write-Color "  $($C.Bold)$($C.White)                  W i n T o o l e r  V 1   -   by  E p e r e z 9 8 " $C.White
    Write-Host ""
    $osLabel = if ($script:IsWin11) { "Windows 11" } else { "Windows 10" }
    Center-Text "[Windows Logo]  $osLabel Detected  |  Build $($script:OSBuild)  |  by Eperez98" 98 $C.Gray
    Write-Host ""
    Write-Color ("=" * 98) $C.Cyan
    Write-Host ""
}

# -----------------------------------------------
#  STATUS BAR
# -----------------------------------------------
function Draw-StatusBar {
    $time = Get-Date -Format "HH:mm:ss"
    $user = $env:USERNAME
    Write-Color "  [*] $user   [T] $time   [LOG] $script:LogFile" $C.Gray
    Write-Host ""
}

# -----------------------------------------------
#  MENU ITEM RENDERER
# -----------------------------------------------
function Draw-MenuItem {
    param(
        [string]$Key,
        [string]$Icon,
        [string]$Label,
        [string]$Description,
        [string]$KeyColor = $C.Cyan
    )
    Write-Host "  $KeyColor$($C.Bold)[$Key]$($C.Reset)  $Icon  $($C.White)$($C.Bold)$Label$($C.Reset)"
    Write-Host "        $($C.Gray)$Description$($C.Reset)"
    Write-Host ""
}

# -----------------------------------------------
#  MAIN MENU
# -----------------------------------------------
function Show-MainMenu {
    Draw-Header
    Draw-StatusBar

    Write-Color "  +-- $($C.Bold)$($C.Cyan)DEBLOAT AND REMOVE APPS$($C.Reset)$($C.Gray) ------------------------------------------------------+" $C.Gray
    Write-Host ""
    Draw-MenuItem "1" "[X]" "Remove Bloatware Apps"        "Uninstall pre-installed Microsoft and OEM bloatware"
    Draw-MenuItem "2" "[P]" "Remove Specific App"           "Interactively select and remove individual apps"
    Draw-MenuItem "3" "[S]" "Disable Telemetry and Tracking" "Block data collection, diagnostics, advertising ID and tracking"
    Draw-MenuItem "4" "[W]" "Disable Edge / Browser Bloat"  "Remove Edge startup boost, tracking, and browser suggestions"

    Write-Color "  +-- $($C.Bold)$($C.Yellow)TWEAKS AND OPTIMIZATION$($C.Reset)$($C.Gray) -------------------------------------------------------+" $C.Gray
    Write-Host ""
    Draw-MenuItem "5" "[F]" "Performance Tweaks"            "Disable animations, adjust power plan, optimize services"
    Draw-MenuItem "6" "[V]" "UI / Visual Tweaks"            "Dark mode, remove ads from Start, clean taskbar and File Explorer"
    Draw-MenuItem "7" "[K]" "Privacy Hardening"             "Disable activity history, timeline, location, diagnostics"
    Draw-MenuItem "8" "[D]" "Disable Unwanted Services"     "Stop and disable non-essential background services"

    Write-Color "  +-- $($C.Bold)$($C.Green)INSTALL AND REPAIR$($C.Reset)$($C.Gray) ------------------------------------------------------------+" $C.Gray
    Write-Host ""
    Draw-MenuItem "9" "[I]" "Install Essentials via winget" "Install browsers, 7-zip, VLC, notepad++ via winget"
    Draw-MenuItem "R" "[T]" "Run Windows Repair"            "SFC scannow + DISM restore health + clear temp files"
    Draw-MenuItem "U" "[U]" "Windows Update"                "Force check and install all available Windows Updates"

    Write-Color "  +-- $($C.Bold)$($C.Magenta)ADVANCED$($C.Reset)$($C.Gray) ----------------------------------------------------------------------+" $C.Gray
    Write-Host ""
    Draw-MenuItem "A" "[!]" "Run Full Auto Debloat"         "Apply ALL recommended debloat + tweaks automatically"
    Draw-MenuItem "L" "[L]" "View Log File"                 "Open the session log in Notepad"

    Write-Color "  +-- $($C.Bold)$($C.Red)EXIT$($C.Reset)$($C.Gray) --------------------------------------------------------------------------+" $C.Gray
    Write-Host ""
    Draw-MenuItem "Q" "[Q]" "Quit"                          "Exit WinToolerV1"

    Write-Color ("=" * 98) $C.Gray
    Write-Host ""
    Write-Color "  $($C.Bold)$($C.Cyan)Enter your choice: $($C.Reset)" $C.White -NoNewline
}

# -----------------------------------------------
#  STATUS WRITERS
# -----------------------------------------------
function Write-Step { param([string]$M) Write-Host "  >> $M" ; Write-Log $M }
function Write-OK   { param([string]$M) Write-Host "  $($C.Green)[OK]$($C.Reset) $M"   ; Write-Log $M "OK"    }
function Write-WARN { param([string]$M) Write-Host "  $($C.Yellow)[!!]$($C.Reset) $M"  ; Write-Log $M "WARN"  }
function Write-ERR  { param([string]$M) Write-Host "  $($C.Red)[XX]$($C.Reset) $M"     ; Write-Log $M "ERROR" }

function Pause-Menu {
    Write-Host ""
    Write-Color "  Press any key to return to menu..." $C.Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# -----------------------------------------------
#  SECTION HEADER
# -----------------------------------------------
function Draw-SectionHeader {
    param([string]$Icon, [string]$Title)
    Clear-Host
    Write-Host ""
    Write-Color ("=" * 98) $C.Cyan
    Center-Text "$Icon  $Title" 98 $C.Bold
    Write-Color ("=" * 98) $C.Cyan
    Write-Host ""
}

# -----------------------------------------------
#  1 - REMOVE BLOATWARE APPS
# -----------------------------------------------
function Remove-BloatwareApps {
    Draw-SectionHeader "[X]" "REMOVE BLOATWARE APPS"

    $bloatApps = @(
        "Microsoft.3DBuilder","Microsoft.BingWeather","Microsoft.GetHelp",
        "Microsoft.Getstarted","Microsoft.Messaging","Microsoft.MicrosoftOfficeHub",
        "Microsoft.MicrosoftSolitaireCollection","Microsoft.MixedReality.Portal",
        "Microsoft.NetworkSpeedTest","Microsoft.News","Microsoft.Office.Lens",
        "Microsoft.Office.OneNote","Microsoft.Office.Sway","Microsoft.OneConnect",
        "Microsoft.People","Microsoft.Print3D","Microsoft.RemoteDesktop",
        "Microsoft.SkypeApp","Microsoft.StorePurchaseApp","Microsoft.Todos",
        "Microsoft.Whiteboard","Microsoft.WindowsAlarms","Microsoft.WindowsCamera",
        "Microsoft.windowscommunicationsapps","Microsoft.WindowsFeedbackHub",
        "Microsoft.WindowsMaps","Microsoft.WindowsSoundRecorder",
        "Microsoft.XboxApp","Microsoft.XboxGamingOverlay","Microsoft.XboxGameOverlay",
        "Microsoft.XboxSpeechToTextOverlay","Microsoft.YourPhone",
        "Microsoft.ZuneMusic","Microsoft.ZuneVideo",
        "MicrosoftTeams","Microsoft.Cortana",
        "SpotifyAB.SpotifyMusic","Disney.37853D22215","Facebook.Facebook",
        "TikTok.TikTok","BytedancePte.TikTok","king.com.BubbleWitch3Saga",
        "king.com.CandyCrushSaga","king.com.CandyCrushFriends",
        "AdobeSystemsIncorporated.AdobePhotoshopExpress",
        "Clipchamp.Clipchamp","Microsoft.BingSearch"
    )

    Write-Step "Scanning for bloatware packages..."
    $removed = 0
    $failed  = 0

    foreach ($app in $bloatApps) {
        $pkg = Get-AppxPackage -Name $app -AllUsers -ErrorAction SilentlyContinue
        if ($pkg) {
            try {
                Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction Stop | Out-Null
                Write-OK "Removed: $app"
                $removed++
            } catch {
                Write-WARN "Could not remove: $app"
                $failed++
            }
        }
        $prov = Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -eq $app }
        if ($prov) {
            try {
                Remove-AppxProvisionedPackage -Online -PackageName $prov.PackageName -ErrorAction Stop | Out-Null
            } catch {}
        }
    }

    Write-Host ""
    Write-OK "Done!  Removed: $removed apps.  Skipped (not found/protected): $failed"
    Pause-Menu
}

# -----------------------------------------------
#  2 - REMOVE SPECIFIC APP
# -----------------------------------------------
function Remove-SpecificApp {
    Draw-SectionHeader "[P]" "REMOVE SPECIFIC APP"
    Write-Step "Listing all installed Appx packages..."
    $apps = Get-AppxPackage -AllUsers | Select-Object Name, PackageFullName | Sort-Object Name
    $apps | Format-Table -AutoSize | Out-Host

    Write-Host ""
    Write-Color "  Enter the app Name (or part of it) to remove, or Q to cancel: " $C.Cyan -NoNewline
    $input = Read-Host
    if ($input -eq 'Q' -or $input -eq 'q') { return }

    $matches = $apps | Where-Object { $_.Name -like "*$input*" }
    if (-not $matches) { Write-WARN "No matching app found."; Pause-Menu; return }

    $matches | Format-Table -AutoSize | Out-Host
    Write-Color "  Confirm removal of all matched apps? [Y/N]: " $C.Yellow -NoNewline
    $confirm = Read-Host
    if ($confirm -ne 'Y' -and $confirm -ne 'y') { return }

    foreach ($m in $matches) {
        try {
            Remove-AppxPackage -Package $m.PackageFullName -AllUsers -ErrorAction Stop | Out-Null
            Write-OK "Removed: $($m.Name)"
        } catch { Write-ERR "Failed: $($m.Name) - $_" }
    }
    Pause-Menu
}

# -----------------------------------------------
#  3 - DISABLE TELEMETRY
# -----------------------------------------------
function Disable-Telemetry {
    Draw-SectionHeader "[S]" "DISABLE TELEMETRY AND TRACKING"

    Write-Step "Setting Telemetry level to 0 (Security)..."
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Type DWord -Value 0 -Force
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry" -Type DWord -Value 0 -Force
    Write-OK "Telemetry disabled"

    Write-Step "Disabling DiagTrack (Connected User Experiences)..."
    Stop-Service "DiagTrack" -Force -ErrorAction SilentlyContinue
    Set-Service  "DiagTrack" -StartupType Disabled -ErrorAction SilentlyContinue
    Write-OK "DiagTrack stopped and disabled"

    Write-Step "Disabling dmwappushservice..."
    Stop-Service "dmwappushservice" -Force -ErrorAction SilentlyContinue
    Set-Service  "dmwappushservice" -StartupType Disabled -ErrorAction SilentlyContinue
    Write-OK "dmwappushservice disabled"

    Write-Step "Disabling Advertising ID..."
    if (-not (Test-Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo")) {
        New-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Force | Out-Null
    }
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Type DWord -Value 0
    Write-OK "Advertising ID disabled"

    Write-Step "Disabling Windows Error Reporting..."
    Disable-WindowsOptionalFeature -Online -FeatureName "Windows-Error-Reporting" -NoRestart -ErrorAction SilentlyContinue | Out-Null
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting" -Name "Disabled" -Type DWord -Value 1 -Force
    Write-OK "Windows Error Reporting disabled"

    Write-Step "Blocking telemetry hosts in HOSTS file..."
    $telemetryHosts = @(
        "0.0.0.0 vortex.data.microsoft.com",
        "0.0.0.0 settings-win.data.microsoft.com",
        "0.0.0.0 watson.telemetry.microsoft.com",
        "0.0.0.0 telecommand.telemetry.microsoft.com",
        "0.0.0.0 oca.telemetry.microsoft.com",
        "0.0.0.0 sqm.telemetry.microsoft.com"
    )
    $hostsFile = "$env:SystemRoot\System32\drivers\etc\hosts"
    $existing  = Get-Content $hostsFile -ErrorAction SilentlyContinue
    foreach ($h in $telemetryHosts) {
        if ($existing -notcontains $h) {
            Add-Content -Path $hostsFile -Value $h -ErrorAction SilentlyContinue
        }
    }
    Write-OK "Telemetry hosts blocked"

    Pause-Menu
}

# -----------------------------------------------
#  4 - DISABLE EDGE BLOAT
# -----------------------------------------------
function Disable-EdgeBloat {
    Draw-SectionHeader "[W]" "DISABLE EDGE AND BROWSER BLOAT"

    Write-Step "Disabling Edge startup boost..."
    $edgePolicy = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
    if (-not (Test-Path $edgePolicy)) { New-Item -Path $edgePolicy -Force | Out-Null }
    Set-ItemProperty -Path $edgePolicy -Name "StartupBoostEnabled"   -Type DWord -Value 0 -Force
    Set-ItemProperty -Path $edgePolicy -Name "BackgroundModeEnabled" -Type DWord -Value 0 -Force
    Write-OK "Edge startup boost disabled"

    Write-Step "Disabling Edge tracking and suggestions..."
    Set-ItemProperty -Path $edgePolicy -Name "EdgeShoppingAssistantEnabled" -Type DWord -Value 0 -Force
    Set-ItemProperty -Path $edgePolicy -Name "ShowMicrosoftRewards"          -Type DWord -Value 0 -Force
    Write-OK "Edge shopping assistant and rewards disabled"

    Write-Step "Removing Edge from autostart..."
    $msedgeStartup = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
    Remove-ItemProperty -Path $msedgeStartup -Name "MicrosoftEdgeAutoLaunch*" -ErrorAction SilentlyContinue
    Write-OK "Edge autostart entries cleaned"

    Write-Step "Disabling Bing Search in Start Menu..."
    $searchPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"
    if (-not (Test-Path $searchPath)) { New-Item -Path $searchPath -Force | Out-Null }
    Set-ItemProperty -Path $searchPath -Name "BingSearchEnabled" -Type DWord -Value 0
    Set-ItemProperty -Path $searchPath -Name "CortanaConsent"    -Type DWord -Value 0
    Write-OK "Bing search in Start Menu disabled"

    Pause-Menu
}

# -----------------------------------------------
#  5 - PERFORMANCE TWEAKS
# -----------------------------------------------
function Apply-PerformanceTweaks {
    Draw-SectionHeader "[F]" "PERFORMANCE TWEAKS"

    Write-Step "Setting power plan to High Performance..."
    powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null
    if ($LASTEXITCODE -ne 0) {
        powercfg /duplicatescheme 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null | Out-Null
        powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null
    }
    Write-OK "High Performance power plan activated"

    Write-Step "Disabling visual animations..."
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask" -Value ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00)) -Type Binary
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Type DWord -Value 3 -Force -ErrorAction SilentlyContinue
    Write-OK "Animations reduced"

    Write-Step "Enabling Storage Sense..."
    $storagePath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\StorageSense"
    if (-not (Test-Path $storagePath)) { New-Item -Path $storagePath -Force | Out-Null }
    Set-ItemProperty -Path $storagePath -Name "AllowStorageSenseGlobal" -Type DWord -Value 1
    Write-OK "Storage Sense enabled"

    Write-Step "Disabling Hibernation..."
    powercfg /hibernate off 2>$null
    Write-OK "Hibernation disabled"

    Write-Step "Adjusting SystemResponsiveness..."
    $mmPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
    Set-ItemProperty -Path $mmPath -Name "SystemResponsiveness" -Type DWord -Value 0 -ErrorAction SilentlyContinue
    Write-OK "SystemResponsiveness set to 0"

    Write-Step "Disabling SysMain (Superfetch) service..."
    Stop-Service "SysMain" -Force -ErrorAction SilentlyContinue
    Set-Service  "SysMain" -StartupType Disabled -ErrorAction SilentlyContinue
    Write-OK "SysMain disabled"

    Pause-Menu
}

# -----------------------------------------------
#  6 - UI / VISUAL TWEAKS
# -----------------------------------------------
function Apply-UITweaks {
    Draw-SectionHeader "[V]" "UI AND VISUAL TWEAKS"

    Write-Step "Enabling Dark Mode..."
    $personalize = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
    Set-ItemProperty -Path $personalize -Name "AppsUseLightTheme"    -Type DWord -Value 0
    Set-ItemProperty -Path $personalize -Name "SystemUsesLightTheme" -Type DWord -Value 0
    Write-OK "Dark mode enabled"

    Write-Step "Removing ads from Start Menu and Lock Screen..."
    $cdmPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
    Set-ItemProperty -Path $cdmPath -Name "SubscribedContent-338388Enabled" -Type DWord -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $cdmPath -Name "SubscribedContent-338389Enabled" -Type DWord -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $cdmPath -Name "SubscribedContent-353698Enabled" -Type DWord -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $cdmPath -Name "SilentInstalledAppsEnabled"      -Type DWord -Value 0 -ErrorAction SilentlyContinue
    Write-OK "Start Menu and Lock Screen ads removed"

    Write-Step "Cleaning Taskbar..."
    $taskbarPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    Set-ItemProperty -Path $taskbarPath -Name "ShowTaskViewButton" -Type DWord -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $taskbarPath -Name "TaskbarDa"          -Type DWord -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $taskbarPath -Name "TaskbarMn"          -Type DWord -Value 0 -ErrorAction SilentlyContinue
    $searchBarPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"
    if (-not (Test-Path $searchBarPath)) { New-Item $searchBarPath -Force | Out-Null }
    Set-ItemProperty -Path $searchBarPath -Name "SearchboxTaskbarMode" -Type DWord -Value 0
    Write-OK "Taskbar cleaned"

    Write-Step "Showing file extensions in Explorer..."
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Type DWord -Value 0
    Write-OK "File extensions visible"

    Write-Step "Showing hidden files..."
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Type DWord -Value 1
    Write-OK "Hidden files shown"

    Write-Step "Restarting Explorer to apply changes..."
    Stop-Process -Name "explorer" -Force -ErrorAction SilentlyContinue
    Start-Sleep 2
    Start-Process "explorer.exe"
    Write-OK "Explorer restarted"

    Pause-Menu
}

# -----------------------------------------------
#  7 - PRIVACY HARDENING
# -----------------------------------------------
function Apply-PrivacyHardening {
    Draw-SectionHeader "[K]" "PRIVACY HARDENING"

    $tweaks = @(
        @{ Path="HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location";   Name="Value";                    Value="Deny"; Type="String"; Desc="Location access disabled"         },
        @{ Path="HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\webcam";     Name="Value";                    Value="Deny"; Type="String"; Desc="Webcam access set to Deny"        },
        @{ Path="HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\microphone"; Name="Value";                    Value="Deny"; Type="String"; Desc="Microphone access set to Deny"    },
        @{ Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\System";                                                Name="EnableActivityFeed";       Value=0;      Type="DWord";  Desc="Activity Feed disabled"           },
        @{ Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\System";                                                Name="PublishUserActivities";    Value=0;      Type="DWord";  Desc="User Activity Publishing disabled" },
        @{ Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\System";                                                Name="UploadUserActivities";     Value=0;      Type="DWord";  Desc="Activity Upload disabled"         },
        @{ Path="HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced";                               Name="Start_TrackProgs";         Value=0;      Type="DWord";  Desc="App launch tracking disabled"     },
        @{ Path="HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced";                               Name="Start_TrackDocs";          Value=0;      Type="DWord";  Desc="Recent docs tracking disabled"    }
    )

    foreach ($t in $tweaks) {
        try {
            if (-not (Test-Path $t.Path)) { New-Item -Path $t.Path -Force | Out-Null }
            Set-ItemProperty -Path $t.Path -Name $t.Name -Value $t.Value -Type $t.Type -Force
            Write-OK $t.Desc
        } catch { Write-WARN "Could not set: $($t.Desc)" }
    }

    Write-Step "Disabling Windows Timeline..."
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableActivityFeed" -Type DWord -Value 0 -Force
    Write-OK "Timeline disabled"

    Pause-Menu
}

# -----------------------------------------------
#  8 - DISABLE UNWANTED SERVICES
# -----------------------------------------------
function Disable-UnwantedServices {
    Draw-SectionHeader "[D]" "DISABLE UNWANTED SERVICES"

    $services = @(
        @{ Name="DiagTrack";         Desc="Connected User Experiences and Telemetry" },
        @{ Name="dmwappushservice";  Desc="WAP Push Message Routing"                 },
        @{ Name="lfsvc";             Desc="Geolocation Service"                      },
        @{ Name="MapsBroker";        Desc="Downloaded Maps Manager"                  },
        @{ Name="NetTcpPortSharing"; Desc="Net.Tcp Port Sharing"                     },
        @{ Name="RemoteAccess";      Desc="Routing and Remote Access"                },
        @{ Name="RemoteRegistry";    Desc="Remote Registry"                          },
        @{ Name="SharedAccess";      Desc="Internet Connection Sharing"              },
        @{ Name="TrkWks";            Desc="Distributed Link Tracking Client"         },
        @{ Name="WbioSrvc";          Desc="Windows Biometric Service"                },
        @{ Name="WMPNetworkSvc";     Desc="Windows Media Player Network Sharing"     },
        @{ Name="XboxGipSvc";        Desc="Xbox Accessory Management"                },
        @{ Name="XblAuthManager";    Desc="Xbox Live Auth Manager"                   },
        @{ Name="XblGameSave";       Desc="Xbox Live Game Save"                      },
        @{ Name="XboxNetApiSvc";     Desc="Xbox Live Networking Service"             }
    )

    foreach ($svc in $services) {
        try {
            Stop-Service $svc.Name -Force -ErrorAction SilentlyContinue
            Set-Service  $svc.Name -StartupType Disabled -ErrorAction Stop
            Write-OK "Disabled: $($svc.Desc)"
        } catch { Write-WARN "Not found or skipped: $($svc.Desc)" }
    }

    Pause-Menu
}

# -----------------------------------------------
#  9 - INSTALL ESSENTIALS
# -----------------------------------------------
function Install-Essentials {
    Draw-SectionHeader "[I]" "INSTALL ESSENTIALS VIA WINGET"

    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-ERR "winget is not available on this system."
        Write-WARN "Please install App Installer from the Microsoft Store."
        Pause-Menu
        return
    }

    $packages = @(
        @{ Id="7zip.7zip";             Name="7-Zip"            },
        @{ Id="VideoLAN.VLC";          Name="VLC Media Player" },
        @{ Id="Notepad++.Notepad++";   Name="Notepad++"        },
        @{ Id="Mozilla.Firefox";       Name="Mozilla Firefox"  },
        @{ Id="Google.Chrome";         Name="Google Chrome"    },
        @{ Id="Microsoft.PowerToys";   Name="PowerToys"        },
        @{ Id="Git.Git";               Name="Git"              },
        @{ Id="Greenshot.Greenshot";   Name="Greenshot"        }
    )

    Write-Step "The following packages will be installed via winget:"
    $packages | ForEach-Object { Write-Host "    >> $($_.Name)" }
    Write-Host ""
    Write-Color "  Proceed? [Y/N]: " $C.Yellow -NoNewline
    $confirm = Read-Host
    if ($confirm -ne 'Y' -and $confirm -ne 'y') { return }

    foreach ($pkg in $packages) {
        Write-Step "Installing $($pkg.Name)..."
        try {
            winget install --id $pkg.Id --silent --accept-package-agreements --accept-source-agreements 2>&1 | Out-Null
            Write-OK "Installed: $($pkg.Name)"
        } catch { Write-WARN "Could not install: $($pkg.Name)" }
    }

    Pause-Menu
}

# -----------------------------------------------
#  R - WINDOWS REPAIR
# -----------------------------------------------
function Run-WindowsRepair {
    Draw-SectionHeader "[T]" "WINDOWS REPAIR"

    Write-Step "Running SFC scannow (this may take several minutes)..."
    sfc /scannow | Out-Host

    Write-Step "Running DISM RestoreHealth..."
    DISM /Online /Cleanup-Image /RestoreHealth | Out-Host

    Write-Step "Clearing Temp files..."
    Remove-Item "$env:TEMP\*"        -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "C:\Windows\Temp\*"  -Recurse -Force -ErrorAction SilentlyContinue
    Write-OK "Temp files cleared"

    Write-Step "Clearing DNS cache..."
    ipconfig /flushdns | Out-Null
    Write-OK "DNS cache flushed"

    Pause-Menu
}

# -----------------------------------------------
#  U - WINDOWS UPDATE
# -----------------------------------------------
function Run-WindowsUpdate {
    Draw-SectionHeader "[U]" "WINDOWS UPDATE"

    Write-Step "Checking for PSWindowsUpdate module..."
    if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
        Write-Step "Installing PSWindowsUpdate module..."
        Install-PackageProvider -Name NuGet -Force -Scope CurrentUser | Out-Null
        Install-Module -Name PSWindowsUpdate -Force -Scope CurrentUser | Out-Null
    }

    Write-Step "Fetching available updates..."
    Import-Module PSWindowsUpdate -ErrorAction SilentlyContinue
    Get-WindowsUpdate -AcceptAll -Install -AutoReboot:$false | Out-Host

    Write-OK "Update check complete"
    Pause-Menu
}

# -----------------------------------------------
#  A - FULL AUTO DEBLOAT
# -----------------------------------------------
function Run-FullAutoDebloat {
    Draw-SectionHeader "[!]" "FULL AUTO DEBLOAT"

    Write-Color "  $($C.Yellow)WARNING:$($C.Reset) This will automatically apply ALL recommended debloat tweaks," $C.Yellow
    Write-Color "  remove bloatware, disable telemetry, apply UI fixes, and disable services." $C.Gray
    Write-Color "  A System Restore Point will be created first." $C.Gray
    Write-Host ""
    Write-Color "  Proceed? [Y/N]: " $C.Red -NoNewline
    $confirm = Read-Host
    if ($confirm -ne 'Y' -and $confirm -ne 'y') { return }

    Write-Step "Creating System Restore Point..."
    try {
        Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "WinToolerV1 - Pre-Debloat" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        Write-OK "Restore point created"
    } catch { Write-WARN "Could not create restore point (may be disabled in system settings)" }

    Write-Host ""
    Write-Step "Phase 1 of 5: Removing Bloatware..."
    Remove-BloatwareApps

    Write-Step "Phase 2 of 5: Disabling Telemetry..."
    Disable-Telemetry

    Write-Step "Phase 3 of 5: Applying Performance Tweaks..."
    Apply-PerformanceTweaks

    Write-Step "Phase 4 of 5: Applying UI Tweaks..."
    Apply-UITweaks

    Write-Step "Phase 5 of 5: Disabling Unwanted Services..."
    Disable-UnwantedServices

    Write-Host ""
    Write-OK "Full Auto Debloat COMPLETE! A restart is recommended."
    Pause-Menu
}

# -----------------------------------------------
#  L - VIEW LOG
# -----------------------------------------------
function View-Log {
    if (Test-Path $script:LogFile) {
        Start-Process notepad.exe $script:LogFile
    } else {
        Write-WARN "No log file found yet."
        Pause-Menu
    }
}

# -----------------------------------------------
#  MAIN LOOP
# -----------------------------------------------
function Main {
    $identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host ""
        Write-Host "  [ERROR] This script must be run as Administrator." -ForegroundColor Red
        Write-Host "  Right-click the script and choose 'Run with PowerShell as Administrator'." -ForegroundColor Yellow
        Write-Host ""
        Read-Host "  Press Enter to exit"
        exit 1
    }

    Write-Log "WinToolerV1 session started by $env:USERNAME on $env:COMPUTERNAME"

    while ($true) {
        Show-MainMenu
        $choice = Read-Host

        switch ($choice.ToUpper()) {
            "1" { Remove-BloatwareApps      }
            "2" { Remove-SpecificApp         }
            "3" { Disable-Telemetry          }
            "4" { Disable-EdgeBloat          }
            "5" { Apply-PerformanceTweaks    }
            "6" { Apply-UITweaks             }
            "7" { Apply-PrivacyHardening     }
            "8" { Disable-UnwantedServices   }
            "9" { Install-Essentials         }
            "R" { Run-WindowsRepair          }
            "U" { Run-WindowsUpdate          }
            "A" { Run-FullAutoDebloat        }
            "L" { View-Log                   }
            "Q" {
                Clear-Host
                Write-Host ""
                Write-Color ("=" * 98) $C.Cyan
                Center-Text "Thank you for using WinToolerV1  -  by Eperez98" 98 $C.Cyan
                Write-Host ""
                Center-Text "Log saved to: $script:LogFile" 98 $C.Gray
                Write-Host ""
                Write-Color ("=" * 98) $C.Cyan
                Write-Host ""
                Write-Log "Session ended."
                exit 0
            }
            default {
                Write-WARN "Invalid option. Please try again."
                Start-Sleep 1
            }
        }
    }
}

# Entry point
Main
