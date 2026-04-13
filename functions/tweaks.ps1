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

# ===========================================================================
#  NEW TWEAKS — V0.8 beta Build 5046 (WinUtil integration)
# ===========================================================================

# ── Essential / Performance ─────────────────────────────────────────────────

function Disable-ConsumerFeatures {
    $p = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
    if (-not (Test-Path $p)) { New-Item $p -Force | Out-Null }
    Set-ItemProperty $p -Name "DisableWindowsConsumerFeatures" -Type DWord -Value 1 -Force
    Set-ItemProperty $p -Name "DisableSoftLanding"             -Type DWord -Value 1 -Force -ErrorAction SilentlyContinue
    Write-WTLog "Disabled Consumer Features (auto-install of store apps)"
}

function Disable-GameDVR {
    $dvrPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR"
    if (-not (Test-Path $dvrPath)) { New-Item $dvrPath -Force | Out-Null }
    Set-ItemProperty $dvrPath -Name "AppCaptureEnabled" -Type DWord -Value 0 -Force
    $gcPath = "HKCU:\System\GameConfigStore"
    if (-not (Test-Path $gcPath)) { New-Item $gcPath -Force | Out-Null }
    Set-ItemProperty $gcPath -Name "GameDVR_Enabled" -Type DWord -Value 0 -Force
    $polPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR"
    if (-not (Test-Path $polPath)) { New-Item $polPath -Force | Out-Null }
    Set-ItemProperty $polPath -Name "AllowGameDVR" -Type DWord -Value 0 -Force
    Write-WTLog "Disabled Xbox Game DVR"
}

function Clear-TempFiles {
    $dirs = @("$env:TEMP", "$env:SystemRoot\Temp")
    foreach ($d in $dirs) {
        Get-ChildItem -Path $d -Recurse -Force -ErrorAction SilentlyContinue |
            Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    }
    Write-WTLog "Deleted temporary files from $($dirs -join ', ')"
}

function Invoke-DiskCleanup {
    Start-Process cleanmgr.exe -ArgumentList "/d C: /VERYLOWDISK" -Wait -ErrorAction SilentlyContinue
    Start-Process Dism.exe -ArgumentList "/online /Cleanup-Image /StartComponentCleanup /ResetBase" -Wait -NoNewWindow -ErrorAction SilentlyContinue
    Write-WTLog "Ran Disk Cleanup and DISM component cleanup"
}

function Disable-ExplorerAutoDiscovery {
    $bags    = "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags"
    $bagsMRU = "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\BagMRU"
    Remove-Item -Path $bags    -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path $bagsMRU -Recurse -Force -ErrorAction SilentlyContinue
    $shellPath = "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags\AllFolders\Shell"
    if (-not (Test-Path $shellPath)) { New-Item $shellPath -Force | Out-Null }
    Set-ItemProperty $shellPath -Name "FolderType" -Value "NotSpecified" -Type String -Force
    Write-WTLog "Disabled Explorer automatic folder type discovery"
}

function Enable-EndTaskOnTaskbar {
    $p = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings"
    if (-not (Test-Path $p)) { New-Item $p -Force | Out-Null }
    Set-ItemProperty $p -Name "TaskbarEndTask" -Type DWord -Value 1 -Force
    Write-WTLog "Enabled End Task with right-click on Taskbar"
}

function Disable-LocationTracking {
    # System-wide HKLM location policy (more comprehensive than the existing HKCU version)
    $conPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location"
    if (-not (Test-Path $conPath)) { New-Item $conPath -Force | Out-Null }
    Set-ItemProperty $conPath -Name "Value" -Value "Deny" -Type String -Force
    $sensorPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}"
    if (-not (Test-Path $sensorPath)) { New-Item $sensorPath -Force | Out-Null }
    Set-ItemProperty $sensorPath -Name "SensorPermissionState" -Type DWord -Value 0 -Force
    $lfsvcPath = "HKLM:\SYSTEM\CurrentControlSet\Services\lfsvc\Service\Configuration"
    if (-not (Test-Path $lfsvcPath)) { New-Item $lfsvcPath -Force | Out-Null }
    Set-ItemProperty $lfsvcPath -Name "Status" -Type DWord -Value 0 -Force
    Write-WTLog "Disabled Location Tracking (HKLM system-wide)"
}

function Disable-PS7Telemetry {
    [Environment]::SetEnvironmentVariable("POWERSHELL_TELEMETRY_OPTOUT", "1", "Machine")
    Write-WTLog "Disabled PowerShell 7 Telemetry (POWERSHELL_TELEMETRY_OPTOUT=1)"
}

function New-WTRestorePoint {
    Enable-ComputerRestore -Drive $env:SystemDrive -ErrorAction SilentlyContinue
    $freq = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore"
    Set-ItemProperty $freq -Name "SystemRestorePointCreationFrequency" -Type DWord -Value 0 -Force -ErrorAction SilentlyContinue
    Checkpoint-Computer -Description "WinTooler System Restore Point" -RestorePointType "MODIFY_SETTINGS" -ErrorAction SilentlyContinue
    Write-WTLog "Created System Restore Point"
}

function Revert-StartMenu {
    # Revert Start Menu to classic layout by disabling the 25H2 gradual rollout feature IDs
    $featureIds = @(45862431, 41598172)
    $vivePath   = "$env:TEMP\ViVeTool"
    $viveExe    = "$vivePath\ViVeTool.exe"
    if (-not (Test-Path $viveExe)) {
        try {
            $url = "https://github.com/thebookisclosed/ViVe/releases/download/v0.3.4/ViVeTool-v0.3.4-IntelAmd.zip"
            $zip = "$env:TEMP\ViVeTool.zip"
            (New-Object Net.WebClient).DownloadFile($url, $zip)
            Expand-Archive $zip -DestinationPath $vivePath -Force
        } catch { Write-WTLog "Could not download ViVeTool: $_" "WARN"; return }
    }
    foreach ($id in $featureIds) {
        & $viveExe /disable /id:$id 2>&1 | Out-Null
    }
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 800
    Start-Process explorer.exe
    Write-WTLog "Reverted Start Menu layout using ViVeTool"
}

function Set-ServicesToManual {
    $services = @(
        "ALG","AppMgmt","AppReadiness","AppVClient","AssignedAccessManagerSvc","AxInstSV",
        "BDESVC","BTAGService","CDPSvc","COMSysApp","CertPropSvc","CscService",
        "DevQueryBroker","DeviceAssociationService","DeviceInstall","DialogBlockingService",
        "DisplayEnhancementService","EFS","EapHost","FDResPub","FrameServer","FrameServerMonitor",
        "GraphicsPerfSvc","HvHost","IKEEXT","InstallService","IpxlatCfgSvc","KtmRm",
        "LicenseManager","LxpSvc","MSDTC","MSiSCSI","MapsBroker","McpManagementService",
        "MicrosoftEdgeElevationService","NaturalAuthentication","NcaSvc","NcbService",
        "NcdAutoSetup","NetSetupSvc","Netman","NlaSvc","PcaSvc","PeerDistSvc","PerfHost",
        "PhoneSvc","PolicyAgent","PrintNotify","PushToInstall","QWAVE","RasAuto","RasMan",
        "RetailDemo","RmSvc","RpcLocator","SCPolicySvc","SCardSvr","SDRSVC","SEMgrSvc",
        "SNMPTRAP","SNMPTrap","SSDPSRV","ScDeviceEnum","SensorDataService","SensorService",
        "SensrSvc","SessionEnv","SharedAccess","SmsRouter","SstpSvc","StiSvc","TapiSrv",
        "TermService","TieringEngineService","TokenBroker","TrkWks","TroubleshootingSvc",
        "TrustedInstaller","UmRdpService","UsoSvc","VSS","VaultSvc","W32Time",
        "WEPHOSTSVC","WFDSConMgrSvc","WMPNetworkSvc","WManSvc","WPDBusEnum","WalletService",
        "WarpJITSvc","WbioSrvc","WdiServiceHost","WdiSystemHost","WebClient","Wecsvc",
        "WerSvc","WiaRpc","WinRM","WpcMonSvc","autotimesvc","bthserv","camsvc",
        "cloudidsvc","dcsvc","defragsvc","diagsvc","dmwappushservice","dot3svc",
        "edgeupdate","edgeupdatem","fdPHost","fhsvc","hidserv","icssvc","lfsvc",
        "lltdsvc","lmhosts","netprofm","perceptionsimulation","pla","seclogon",
        "smphost","svsvc","swprv","upnphost","vds","wcncsvc","webthreatdefsvc",
        "wercplsupport","wisvc","wlidsvc","wlpasvc","wmiApSrv","workfolderssvc","wuauserv"
    )
    $disabled = @("AppVClient","AssignedAccessManagerSvc","DialogBlockingService","NetTcpPortSharing",
                  "RemoteAccess","RemoteRegistry","UevAgentService","shpamsvc","ssh-agent","tzautoupdate")
    foreach ($s in $services) {
        Set-Service -Name $s -StartupType Manual -ErrorAction SilentlyContinue
    }
    foreach ($s in $disabled) {
        Stop-Service $s -Force -ErrorAction SilentlyContinue
        Set-Service -Name $s -StartupType Disabled -ErrorAction SilentlyContinue
    }
    # Keep critical services automatic
    foreach ($s in @("AudioSrv","AudioEndpointBuilder","CryptSvc","DPS","Dhcp","EventLog","EventSystem",
                     "FontCache","KeyIso","LanmanServer","LanmanWorkstation","Power","ProfSvc","SENS",
                     "SamSs","ShellHWDetection","Spooler","SysMain","Themes","TrkWks","UserManager",
                     "Winmgmt","Wcmsvc","nsi","iphlpsvc")) {
        Set-Service -Name $s -StartupType Automatic -ErrorAction SilentlyContinue
    }
    Write-WTLog "Set non-critical services to Manual startup"
}

function Disable-WPBT {
    $p = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager"
    Set-ItemProperty $p -Name "DisableWpbtExecution" -Type DWord -Value 1 -Force
    Write-WTLog "Disabled Windows Platform Binary Table (WPBT)"
}

function Remove-Widgets {
    Stop-Process -Name Widgets -Force -ErrorAction SilentlyContinue
    Get-AppxPackage "Microsoft.WidgetsPlatformRuntime" -AllUsers -ErrorAction SilentlyContinue |
        Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
    Get-AppxPackage "MicrosoftWindows.Client.WebExperience" -AllUsers -ErrorAction SilentlyContinue |
        Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
    Write-WTLog "Removed Widgets"
}

function Disable-StoreSearch {
    $dbPath = "$env:LocalAppData\Packages\Microsoft.WindowsStore_8wekyb3d8bbwe\LocalState\store.db"
    if (Test-Path $dbPath) {
        icacls $dbPath /deny Everyone:F 2>&1 | Out-Null
    }
    $searchPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"
    if (-not (Test-Path $searchPath)) { New-Item $searchPath -Force | Out-Null }
    Set-ItemProperty $searchPath -Name "BingSearchEnabled" -Type DWord -Value 0 -Force
    Write-WTLog "Disabled Microsoft Store search results in Start Menu"
}

# ── Advanced / Caution ──────────────────────────────────────────────────────

function Disable-BraveFeatures {
    $p = "HKLM:\SOFTWARE\Policies\BraveSoftware\Brave"
    if (-not (Test-Path $p)) { New-Item $p -Force | Out-Null }
    $settings = @{
        "BraveRewardsDisabled"  = 1
        "BraveWalletDisabled"   = 1
        "BraveVPNDisabled"      = 1
        "BraveAIChatEnabled"    = 0
        "BraveStatsPingEnabled" = 0
    }
    foreach ($k in $settings.Keys) {
        Set-ItemProperty $p -Name $k -Type DWord -Value $settings[$k] -Force
    }
    Write-WTLog "Disabled Brave Rewards, Leo AI, Crypto Wallet, VPN via policy"
}

function Disable-EdgeFull {
    $edgePol = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
    if (-not (Test-Path $edgePol)) { New-Item $edgePol -Force | Out-Null }
    $settings = @{
        "PersonalizationReportingEnabled"      = 0
        "ShowRecommendationsEnabled"           = 0
        "HideFirstRunExperience"               = 1
        "UserFeedbackAllowed"                  = 0
        "ConfigureDoNotTrack"                  = 1
        "AlternateErrorPagesEnabled"           = 0
        "EdgeCollectionsEnabled"               = 0
        "EdgeShoppingAssistantEnabled"         = 0
        "MicrosoftEdgeInsiderPromotionEnabled" = 0
        "ShowMicrosoftRewards"                 = 0
        "WebWidgetAllowed"                     = 0
        "DiagnosticData"                       = 0
        "EdgeAssetDeliveryServiceEnabled"      = 0
        "WalletDonationEnabled"                = 0
        "StartupBoostEnabled"                  = 0
        "BackgroundModeEnabled"                = 0
    }
    foreach ($k in $settings.Keys) {
        Set-ItemProperty $edgePol -Name $k -Type DWord -Value $settings[$k] -Force
    }
    $updatePol = "HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate"
    if (-not (Test-Path $updatePol)) { New-Item $updatePol -Force | Out-Null }
    Set-ItemProperty $updatePol -Name "CreateDesktopShortcutDefault" -Type DWord -Value 0 -Force
    # Block Rewards extension
    $extBlk = "HKLM:\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallBlocklist"
    if (-not (Test-Path $extBlk)) { New-Item $extBlk -Force | Out-Null }
    Set-ItemProperty $extBlk -Name "1" -Value "ofefcgjbeghpigppfmkologfjadafddi" -Type String -Force
    Write-WTLog "Applied full Edge debloat policy (16 settings)"
}

function Remove-MSEdge {
    # Unblock the Edge uninstaller then remove
    $edgeBase = "$env:ProgramFiles(x86)\Microsoft\Edge\Application"
    $edgeVer  = (Get-ChildItem $edgeBase -Directory -ErrorAction SilentlyContinue |
                 Sort-Object Name -Descending | Select-Object -First 1).Name
    if ($edgeVer) {
        $uninstaller = "$edgeBase\$edgeVer\Installer\setup.exe"
        if (Test-Path $uninstaller) {
            $regEdge = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\ClientState\{56EB18F8-B008-4CBD-B6D2-8C97FE7E9062}"
            Set-ItemProperty $regEdge -Name "experiment_control_labels" -Value "" -Type String -Force -ErrorAction SilentlyContinue
            Start-Process $uninstaller -ArgumentList "--uninstall --system-level --verbose-logging --force-uninstall" -Wait -NoNewWindow
            Write-WTLog "Ran Edge uninstaller: $uninstaller"
        }
    } else {
        Write-WTLog "Edge installation not found at $edgeBase" "WARN"
    }
}

function Set-UTCTime {
    Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation" `
        -Name "RealTimeIsUniversal" -Type QWord -Value 1 -Force
    Write-WTLog "Set hardware clock to UTC (for dual-boot with Linux)"
}

function Remove-OneDriveFull {
    # Use the OneDrive uninstaller
    $od32 = "$env:SystemRoot\System32\OneDriveSetup.exe"
    $od64 = "$env:SystemRoot\SysWOW64\OneDriveSetup.exe"
    $odLocalUser = "$env:LocalAppData\Microsoft\OneDrive\OneDriveSetup.exe"
    $uninstaller = @($od32,$od64,$odLocalUser) | Where-Object { Test-Path $_ } | Select-Object -First 1
    if ($uninstaller) {
        Stop-Process -Name OneDrive -Force -ErrorAction SilentlyContinue
        Start-Process $uninstaller -ArgumentList "/uninstall" -Wait -NoNewWindow
    }
    # Remove registry startup entries
    $runPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
    Remove-ItemProperty $runPath -Name "OneDrive" -ErrorAction SilentlyContinue
    # Policy: disable sync
    $odPol = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive"
    if (-not (Test-Path $odPol)) { New-Item $odPol -Force | Out-Null }
    Set-ItemProperty $odPol -Name "DisableFileSyncNGSC" -Type DWord -Value 1 -Force
    # Remove leftover folders
    foreach ($folder in @("$env:USERPROFILE\OneDrive","$env:LocalAppData\Microsoft\OneDrive")) {
        Remove-Item $folder -Recurse -Force -ErrorAction SilentlyContinue
    }
    Write-WTLog "Removed OneDrive"
}

function Remove-ExplorerHome {
    Remove-Item "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{f874310e-b6b7-47dc-bc84-b9e6b38f5903}" -Force -ErrorAction SilentlyContinue
    $expPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    Set-ItemProperty $expPath -Name "LaunchTo" -Type DWord -Value 1 -Force -ErrorAction SilentlyContinue
    Write-WTLog "Removed Home from Explorer, set This PC as default"
}

function Remove-ExplorerGallery {
    Remove-Item "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}" -Force -ErrorAction SilentlyContinue
    $expPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    Set-ItemProperty $expPath -Name "LaunchTo" -Type DWord -Value 1 -Force -ErrorAction SilentlyContinue
    Write-WTLog "Removed Gallery from Explorer, set This PC as default"
}

function Set-DisplayForPerformance {
    $deskPath = "HKCU:\Control Panel\Desktop"
    Set-ItemProperty $deskPath -Name "DragFullWindows" -Value "0" -Type String -Force
    Set-ItemProperty $deskPath -Name "MenuShowDelay"   -Value "200" -Type String -Force
    Set-ItemProperty $deskPath -Name "UserPreferencesMask" -Type Binary -Value ([byte[]](144,18,3,128,16,0,0,0))
    Set-ItemProperty "HKCU:\Control Panel\Desktop\WindowMetrics" -Name "MinAnimate" -Value "0" -Type String -Force -ErrorAction SilentlyContinue
    Set-ItemProperty "HKCU:\Control Panel\Keyboard" -Name "KeyboardDelay" -Type DWord -Value 0 -Force -ErrorAction SilentlyContinue
    $adv = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    foreach ($k in @("ListviewAlphaSelect","ListviewShadow","TaskbarAnimations")) {
        Set-ItemProperty $adv -Name $k -Type DWord -Value 0 -Force -ErrorAction SilentlyContinue
    }
    Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Type DWord -Value 3 -Force -ErrorAction SilentlyContinue
    Set-ItemProperty "HKCU:\Software\Microsoft\Windows\DWM" -Name "EnableAeroPeek" -Type DWord -Value 0 -Force -ErrorAction SilentlyContinue
    Write-WTLog "Set display to Performance mode"
}

function Remove-MSStoreAppsAll {
    $bloat = @(
        "Microsoft.Microsoft3DViewer","Microsoft.BingFinance","Microsoft.BingNews","Microsoft.BingSports",
        "Microsoft.BingWeather","Clipchamp.Clipchamp","Microsoft.Todos","MicrosoftCorporationII.QuickAssist",
        "Microsoft.MicrosoftStickyNotes","Microsoft.GetHelp","Microsoft.GetStarted","Microsoft.Messaging",
        "Microsoft.MicrosoftSolitaireCollection","Microsoft.NetworkSpeedTest","Microsoft.News",
        "Microsoft.Office.Lens","Microsoft.Office.Sway","Microsoft.Office.OneNote","Microsoft.People",
        "Microsoft.Print3D","Microsoft.SkypeApp","Microsoft.Wallet","Microsoft.Whiteboard",
        "Microsoft.WindowsAlarms","Microsoft.WindowsCommunicationsApps","Microsoft.WindowsFeedbackHub",
        "Microsoft.WindowsMaps","Microsoft.WindowsSoundRecorder","Microsoft.ConnectivityStore",
        "Microsoft.ScreenSketch","Microsoft.MixedReality.Portal","Microsoft.ZuneMusic","Microsoft.ZuneVideo",
        "Microsoft.MicrosoftOfficeHub","MsTeams","MicrosoftTeams","Microsoft.Cortana",
        "king.com.CandyCrushSaga","king.com.CandyCrushFriends","king.com.BubbleWitch3Saga",
        "AdobeSystemsIncorporated.AdobePhotoshopExpress","Flipboard.Flipboard","Twitter.Twitter",
        "Facebook.Facebook","EclipseManager","ActiproSoftwareLLC","Dolby","Netflix"
    )
    foreach ($app in $bloat) {
        Get-AppxPackage    -Name "*$app*" -AllUsers -ErrorAction SilentlyContinue |
            Remove-AppxPackage    -AllUsers -ErrorAction SilentlyContinue | Out-Null
        Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName -like "*$app*" } |
            Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Out-Null
    }
    Write-WTLog "Removed all Microsoft Store apps (not recommended)"
}

function Disable-BackgroundApps {
    $p = "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications"
    if (-not (Test-Path $p)) { New-Item $p -Force | Out-Null }
    Set-ItemProperty $p -Name "GlobalUserDisabled" -Type DWord -Value 1 -Force
    Write-WTLog "Disabled background access for all Store apps"
}

function Disable-FullscreenOptimizations {
    $p = "HKCU:\System\GameConfigStore"
    if (-not (Test-Path $p)) { New-Item $p -Force | Out-Null }
    Set-ItemProperty $p -Name "GameDVR_DXGIHonorFSEWindowsCompatible" -Type DWord -Value 1 -Force
    Set-ItemProperty $p -Name "GameDVR_FSEBehaviorMode"                -Type DWord -Value 2 -Force -ErrorAction SilentlyContinue
    Set-ItemProperty $p -Name "GameDVR_HonorUserFSEBehaviorMode"       -Type DWord -Value 1 -Force -ErrorAction SilentlyContinue
    Write-WTLog "Disabled Fullscreen Optimizations globally"
}

function Disable-IPv6 {
    $p = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters"
    if (-not (Test-Path $p)) { New-Item $p -Force | Out-Null }
    Set-ItemProperty $p -Name "DisabledComponents" -Type DWord -Value 255 -Force
    Disable-NetAdapterBinding -Name "*" -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue
    Write-WTLog "Disabled IPv6 on all adapters"
}

function Disable-Notifications {
    $expPol = "HKCU:\Software\Policies\Microsoft\Windows\Explorer"
    if (-not (Test-Path $expPol)) { New-Item $expPol -Force | Out-Null }
    Set-ItemProperty $expPol -Name "DisableNotificationCenter" -Type DWord -Value 1 -Force
    $pushPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications"
    if (-not (Test-Path $pushPath)) { New-Item $pushPath -Force | Out-Null }
    Set-ItemProperty $pushPath -Name "ToastEnabled" -Type DWord -Value 0 -Force
    Write-WTLog "Disabled Notification Tray and Calendar"
}

function Block-AdobeNetwork {
    $hostsFile = "$env:SystemRoot\System32\drivers\etc\hosts"
    $adobeHosts = @(
        "0.0.0.0 activate.adobe.com",
        "0.0.0.0 activate-sea.adobe.com",
        "0.0.0.0 activate-sjc0.adobe.com",
        "0.0.0.0 adobe-dns.adobe.com",
        "0.0.0.0 adobe-dns-2.adobe.com",
        "0.0.0.0 adobe-dns-3.adobe.com",
        "0.0.0.0 adobe-dns-4.adobe.com",
        "0.0.0.0 adobeereg.com",
        "0.0.0.0 ereg.adobe.com",
        "0.0.0.0 ereg.wip3.adobe.com",
        "0.0.0.0 3dns.adobe.com",
        "0.0.0.0 3dns-3.adobe.com",
        "0.0.0.0 3dns-4.adobe.com",
        "0.0.0.0 cc-api-data.adobe.io",
        "0.0.0.0 ims-na1.adobelogin.com"
    )
    $existing = Get-Content $hostsFile -ErrorAction SilentlyContinue
    foreach ($entry in $adobeHosts) {
        if ($existing -notcontains $entry) {
            Add-Content -Path $hostsFile -Value $entry -ErrorAction SilentlyContinue
        }
    }
    Write-WTLog "Blocked Adobe activation/telemetry hosts"
}

function Prefer-IPv4 {
    $p = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters"
    if (-not (Test-Path $p)) { New-Item $p -Force | Out-Null }
    Set-ItemProperty $p -Name "DisabledComponents" -Type DWord -Value 32 -Force
    Write-WTLog "Set IPv4 preference over IPv6"
}

function Block-RazerInstalls {
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" `
        -Name "SearchOrderConfig" -Type DWord -Value 0 -Force -ErrorAction SilentlyContinue
    $devPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Device Installer"
    if (-not (Test-Path $devPath)) { New-Item $devPath -Force | Out-Null }
    Set-ItemProperty $devPath -Name "DisableCoInstallers" -Type DWord -Value 1 -Force
    $razerPath = "C:\Windows\Installer\Razer"
    if (-not (Test-Path $razerPath)) { New-Item -Path $razerPath -ItemType Directory -Force | Out-Null }
    icacls $razerPath /deny "Everyone:(OI)(CI)(F)" 2>&1 | Out-Null
    Write-WTLog "Blocked Razer software co-installer"
}

function Disable-Copilot {
    $polPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot"
    if (-not (Test-Path $polPath)) { New-Item $polPath -Force | Out-Null }
    Set-ItemProperty $polPath -Name "TurnOffWindowsCopilot" -Type DWord -Value 1 -Force
    $uPath = "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot"
    if (-not (Test-Path $uPath)) { New-Item $uPath -Force | Out-Null }
    Set-ItemProperty $uPath -Name "TurnOffWindowsCopilot" -Type DWord -Value 1 -Force
    $adv = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    Set-ItemProperty $adv -Name "ShowCopilotButton" -Type DWord -Value 0 -Force -ErrorAction SilentlyContinue
    $shellCopilot = "HKLM:\SOFTWARE\Microsoft\Windows\Shell\Copilot"
    if (-not (Test-Path $shellCopilot)) { New-Item $shellCopilot -Force | Out-Null }
    Set-ItemProperty $shellCopilot -Name "IsCopilotAvailable" -Type DWord -Value 0 -Force
    Get-AppxPackage -AllUsers "*Copilot*" -ErrorAction SilentlyContinue |
        Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue | Out-Null
    Write-WTLog "Disabled Microsoft Copilot"
}

function Remove-ExplorerGalleryNav {
    # Alias kept for catalog compatibility - calls Remove-ExplorerGallery
    Remove-ExplorerGallery
}

function Set-ClassicContextMenu {
    $clsidPath = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"
    if (-not (Test-Path $clsidPath)) { New-Item $clsidPath -Force | Out-Null }
    Set-ItemProperty $clsidPath -Name "(Default)" -Value "" -Type String -Force
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 800
    Start-Process explorer.exe
    Write-WTLog "Set classic right-click context menu"
}

function Disable-StorageSense {
    $storagePath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy"
    if (-not (Test-Path $storagePath)) { New-Item $storagePath -Force | Out-Null }
    Set-ItemProperty $storagePath -Name "01" -Type DWord -Value 0 -Force
    Write-WTLog "Disabled Storage Sense"
}

function Disable-Teredo {
    $p = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters"
    if (-not (Test-Path $p)) { New-Item $p -Force | Out-Null }
    Set-ItemProperty $p -Name "DisabledComponents" -Type DWord -Value 1 -Force
    netsh interface teredo set state disabled 2>&1 | Out-Null
    Write-WTLog "Disabled Teredo tunneling"
}
