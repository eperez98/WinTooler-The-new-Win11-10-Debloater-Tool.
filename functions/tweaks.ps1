# functions/tweaks.ps1
# All tweak implementation functions for WinToolerV1

function Set-HighPerformancePower {
    powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null
    if ($LASTEXITCODE -ne 0) {
        powercfg /duplicatescheme 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null | Out-Null
        powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null
    }
    Write-WTLog "Set High Performance power plan"
}

function Disable-SysMain {
    Stop-Service "SysMain" -Force -ErrorAction SilentlyContinue
    Set-Service  "SysMain" -StartupType Disabled -ErrorAction SilentlyContinue
    Write-WTLog "Disabled SysMain (Superfetch)"
}

function Disable-SearchIndexing {
    Stop-Service "WSearch" -Force -ErrorAction SilentlyContinue
    Set-Service  "WSearch" -StartupType Disabled -ErrorAction SilentlyContinue
    Write-WTLog "Disabled Windows Search indexing"
}

function Reduce-Animations {
    $regPath = "HKCU:\Control Panel\Desktop"
    Set-ItemProperty $regPath -Name "UserPreferencesMask" `
        -Value ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00)) -Type Binary
    Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" `
        -Name "VisualFXSetting" -Type DWord -Value 3 -Force -ErrorAction SilentlyContinue
    Write-WTLog "Reduced visual animations"
}

function Disable-Hibernation {
    powercfg /hibernate off 2>$null
    Write-WTLog "Disabled hibernation"
}

function Enable-GameMode {
    $gamePath = "HKCU:\Software\Microsoft\GameBar"
    if (-not (Test-Path $gamePath)) { New-Item $gamePath -Force | Out-Null }
    Set-ItemProperty $gamePath -Name "AllowAutoGameMode" -Type DWord -Value 1 -Force
    Set-ItemProperty $gamePath -Name "AutoGameModeEnabled" -Type DWord -Value 1 -Force

    $gpuPath = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
    Set-ItemProperty $gpuPath -Name "HwSchMode" -Type DWord -Value 2 -Force -ErrorAction SilentlyContinue
    Write-WTLog "Enabled GameMode and HAGS"
}

function Disable-Telemetry {
    $dcPath1 = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
    $dcPath2 = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection"
    foreach ($p in @($dcPath1, $dcPath2)) {
        if (-not (Test-Path $p)) { New-Item $p -Force | Out-Null }
        Set-ItemProperty $p -Name "AllowTelemetry" -Type DWord -Value 0 -Force
    }
    Stop-Service "DiagTrack" -Force -ErrorAction SilentlyContinue
    Set-Service  "DiagTrack" -StartupType Disabled -ErrorAction SilentlyContinue
    Stop-Service "dmwappushservice" -Force -ErrorAction SilentlyContinue
    Set-Service  "dmwappushservice" -StartupType Disabled -ErrorAction SilentlyContinue
    Write-WTLog "Disabled telemetry"
}

function Disable-AdvertisingId {
    $adPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
    if (-not (Test-Path $adPath)) { New-Item $adPath -Force | Out-Null }
    Set-ItemProperty $adPath -Name "Enabled" -Type DWord -Value 0
    Write-WTLog "Disabled Advertising ID"
}

function Disable-ActivityHistory {
    $syspath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
    if (-not (Test-Path $syspath)) { New-Item $syspath -Force | Out-Null }
    Set-ItemProperty $syspath -Name "EnableActivityFeed"    -Type DWord -Value 0 -Force
    Set-ItemProperty $syspath -Name "PublishUserActivities" -Type DWord -Value 0 -Force
    Set-ItemProperty $syspath -Name "UploadUserActivities"  -Type DWord -Value 0 -Force
    Write-WTLog "Disabled Activity History"
}

function Disable-LocationServices {
    $locPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location"
    if (-not (Test-Path $locPath)) { New-Item $locPath -Force | Out-Null }
    Set-ItemProperty $locPath -Name "Value" -Value "Deny" -Type String
    Write-WTLog "Disabled Location Services"
}

function Disable-WebcamAccess {
    $camPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\webcam"
    if (-not (Test-Path $camPath)) { New-Item $camPath -Force | Out-Null }
    Set-ItemProperty $camPath -Name "Value" -Value "Deny" -Type String
    Write-WTLog "Disabled Webcam access"
}

function Disable-MicrophoneAccess {
    $micPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\microphone"
    if (-not (Test-Path $micPath)) { New-Item $micPath -Force | Out-Null }
    Set-ItemProperty $micPath -Name "Value" -Value "Deny" -Type String
    Write-WTLog "Disabled Microphone access"
}

function Block-TelemetryHosts {
    $hostsFile = "$env:SystemRoot\System32\drivers\etc\hosts"
    $existing  = Get-Content $hostsFile -ErrorAction SilentlyContinue
    $entries = @(
        "0.0.0.0 vortex.data.microsoft.com",
        "0.0.0.0 settings-win.data.microsoft.com",
        "0.0.0.0 watson.telemetry.microsoft.com",
        "0.0.0.0 telecommand.telemetry.microsoft.com",
        "0.0.0.0 oca.telemetry.microsoft.com",
        "0.0.0.0 sqm.telemetry.microsoft.com",
        "0.0.0.0 telemetry.microsoft.com",
        "0.0.0.0 statsfe2.update.microsoft.com.akadns.net"
    )
    foreach ($e in $entries) {
        if ($existing -notcontains $e) {
            Add-Content -Path $hostsFile -Value $e -ErrorAction SilentlyContinue
        }
    }
    Write-WTLog "Blocked telemetry hosts in HOSTS file"
}

function Enable-DarkMode {
    $pPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
    Set-ItemProperty $pPath -Name "AppsUseLightTheme"    -Type DWord -Value 0
    Set-ItemProperty $pPath -Name "SystemUsesLightTheme" -Type DWord -Value 0
    Write-WTLog "Enabled Dark Mode"
}

function Show-FileExtensions {
    Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
        -Name "HideFileExt" -Type DWord -Value 0
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 800
    Start-Process explorer.exe
    Write-WTLog "Enabled file extension visibility"
}

function Show-HiddenFiles {
    Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
        -Name "Hidden" -Type DWord -Value 1
    Write-WTLog "Showing hidden files"
}

function Remove-StartMenuAds {
    $cdmPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
    $keys = @("SubscribedContent-338388Enabled","SubscribedContent-338389Enabled",
              "SubscribedContent-353698Enabled","SilentInstalledAppsEnabled",
              "SystemPaneSuggestionsEnabled","SoftLandingEnabled")
    foreach ($k in $keys) {
        Set-ItemProperty $cdmPath -Name $k -Type DWord -Value 0 -ErrorAction SilentlyContinue
    }
    Write-WTLog "Removed Start Menu ads"
}

function Clean-Taskbar {
    $tbPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    Set-ItemProperty $tbPath -Name "ShowTaskViewButton" -Type DWord -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty $tbPath -Name "TaskbarDa"          -Type DWord -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty $tbPath -Name "TaskbarMn"          -Type DWord -Value 0 -ErrorAction SilentlyContinue
    $sPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"
    if (-not (Test-Path $sPath)) { New-Item $sPath -Force | Out-Null }
    Set-ItemProperty $sPath -Name "SearchboxTaskbarMode" -Type DWord -Value 0
    Write-WTLog "Cleaned Taskbar"
}

function Disable-BingSearch {
    $sPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"
    if (-not (Test-Path $sPath)) { New-Item $sPath -Force | Out-Null }
    Set-ItemProperty $sPath -Name "BingSearchEnabled" -Type DWord -Value 0
    Set-ItemProperty $sPath -Name "CortanaConsent"    -Type DWord -Value 0
    Write-WTLog "Disabled Bing search in Start"
}

function Remove-MSBloatware {
    $bloat = @(
        "Microsoft.3DBuilder","Microsoft.BingWeather","Microsoft.GetHelp","Microsoft.Getstarted",
        "Microsoft.Messaging","Microsoft.MicrosoftOfficeHub","Microsoft.MicrosoftSolitaireCollection",
        "Microsoft.MixedReality.Portal","Microsoft.News","Microsoft.Office.OneNote",
        "Microsoft.Office.Sway","Microsoft.People","Microsoft.Print3D","Microsoft.SkypeApp",
        "Microsoft.Todos","Microsoft.Whiteboard","Microsoft.WindowsAlarms","Microsoft.WindowsFeedbackHub",
        "Microsoft.WindowsMaps","Microsoft.WindowsSoundRecorder","Microsoft.YourPhone",
        "Microsoft.ZuneMusic","Microsoft.ZuneVideo","MicrosoftTeams","Microsoft.Cortana",
        "Microsoft.BingSearch","Clipchamp.Clipchamp","king.com.CandyCrushSaga",
        "king.com.CandyCrushFriends","king.com.BubbleWitch3Saga",
        "AdobeSystemsIncorporated.AdobePhotoshopExpress"
    )
    foreach ($app in $bloat) {
        $pkg = Get-AppxPackage -Name $app -AllUsers -ErrorAction SilentlyContinue
        if ($pkg) {
            Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction SilentlyContinue | Out-Null
            Write-WTLog "Removed: $app"
        }
        $prov = Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue |
                Where-Object { $_.DisplayName -eq $app }
        if ($prov) {
            Remove-AppxProvisionedPackage -Online -PackageName $prov.PackageName -ErrorAction SilentlyContinue | Out-Null
        }
    }
    Write-WTLog "Completed bloatware removal"
}

function Remove-XboxApps {
    $xboxApps = @(
        "Microsoft.XboxApp","Microsoft.XboxGamingOverlay","Microsoft.XboxGameOverlay",
        "Microsoft.XboxSpeechToTextOverlay","Microsoft.XboxIdentityProvider"
    )
    foreach ($app in $xboxApps) {
        $pkg = Get-AppxPackage -Name $app -AllUsers -ErrorAction SilentlyContinue
        if ($pkg) {
            Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction SilentlyContinue | Out-Null
        }
    }
    $xboxSvcs = @("XboxGipSvc","XblAuthManager","XblGameSave","XboxNetApiSvc")
    foreach ($s in $xboxSvcs) {
        Stop-Service $s -Force -ErrorAction SilentlyContinue
        Set-Service  $s -StartupType Disabled -ErrorAction SilentlyContinue
    }
    Write-WTLog "Removed Xbox components"
}

function Disable-EdgeBloat {
    $edgePath = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
    if (-not (Test-Path $edgePath)) { New-Item $edgePath -Force | Out-Null }
    $settings = @{
        "StartupBoostEnabled"          = 0
        "BackgroundModeEnabled"        = 0
        "EdgeShoppingAssistantEnabled" = 0
        "ShowMicrosoftRewards"         = 0
        "HubsSidebarEnabled"           = 0
    }
    foreach ($k in $settings.Keys) {
        Set-ItemProperty $edgePath -Name $k -Type DWord -Value $settings[$k] -Force
    }
    Write-WTLog "Disabled Edge bloat features"
}

function Disable-OneDrive {
    $runPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
    Remove-ItemProperty $runPath -Name "OneDrive" -ErrorAction SilentlyContinue
    $odPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive"
    if (-not (Test-Path $odPath)) { New-Item $odPath -Force | Out-Null }
    Set-ItemProperty $odPath -Name "DisableFileSyncNGSC" -Type DWord -Value 1 -Force
    Write-WTLog "Disabled OneDrive startup"
}
