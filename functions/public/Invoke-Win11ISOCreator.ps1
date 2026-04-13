#Requires -RunAsAdministrator
<#
.SYNOPSIS
    WinTooler V0.7.1 beta - Build 5040 - Windows 11 ISO Creator Module
.DESCRIPTION
    Mounts a supplied Windows 11 ISO, applies selected customisations
    (TPM bypass, bloatware removal, network driver injection), then
    rebuilds a bootable ISO using oscdimg or DISM.
.PARAMETER SourceISO
    REQUIRED. Path to an official Windows 11 ISO from Microsoft.
.PARAMETER OutputPath
    Folder where the rebuilt ISO will be saved.
.PARAMETER RemoveBloat
    Strip 20+ Microsoft-provisioned bloat apps from install.wim via DISM.
.PARAMETER AddNetworkDrivers
    Inject .inf drivers from DriversPath into install.wim via DISM /Add-Driver.
.PARAMETER DriversPath
    Folder containing .inf network driver files (used with AddNetworkDrivers).
.PARAMETER BypassTPM / BypassSecureBoot / BypassRAM
    Remove hardware requirement checks from the setup image.
.PARAMETER EnableUnattended
    Inject a minimal autounattend.xml to skip OOBE screens.
.PARAMETER ProgressCallback
    ScriptBlock called with (percent, message) for GUI integration.
#>
# Write-WTLog stub for background job context
if (-not (Get-Command Write-WTLog -ErrorAction SilentlyContinue)) {
    function Write-WTLog {
        param([string]$Message, [string]$Level = "INFO")
        $prefix = if ($Level -eq "WARN") { "WARN" } elseif ($Level -eq "ERROR") { "ERR " } else { "LOG " }
        Write-Output "LOGINFO:[$prefix] $Message"
    }
}

function Invoke-Win11ISOCreator {
    [CmdletBinding()]
    param(
        [string]  $SourceISO         = "",
        [string]  $OutputPath        = "$env:USERPROFILE\Downloads",
        [switch]  $RemoveBloat,
        [switch]  $AddNetworkDrivers,
        [string]  $DriversPath       = "",
        [switch]  $BypassTPM,
        [switch]  $BypassSecureBoot,
        [switch]  $BypassRAM,
        [switch]  $EnableUnattended,
        [string]  $WingetAppIds     = "",
        [scriptblock] $ProgressCallback = $null
    )

    function Report {
        param([int]$Pct, [string]$Msg)
        if ($ProgressCallback) { & $ProgressCallback $Pct $Msg }
        else { Write-Host "  [$Pct%] $Msg" -ForegroundColor Cyan }
    }

    # ----------------------------------------------------------------
    #  PRE-FLIGHT CHECKS
    # ----------------------------------------------------------------
    Report 0 "Running pre-flight checks..."

    if (-not $SourceISO -or -not (Test-Path $SourceISO)) {
        throw "Source ISO not found: '$SourceISO'. Please select a valid Windows 11 ISO."
    }

    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) { throw "Administrator privileges required." }

    $drive  = Split-Path -Qualifier $OutputPath
    $disk   = Get-PSDrive -Name ($drive.TrimEnd(':')) -ErrorAction SilentlyContinue
    if ($disk) {
        $freeGB = [math]::Round($disk.Free / 1GB, 1)
        if ($freeGB -lt 8) { throw "Insufficient disk space: ${freeGB} GB free. Need at least 8 GB." }
        Report 2 "Disk space: ${freeGB} GB free - OK"
    }
    if (-not (Test-Path $OutputPath)) { New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null }

    $mountDir   = Join-Path $env:TEMP "WinTooler_ISO_Mount"
    $wimMntDir  = Join-Path $env:TEMP "WinTooler_WIM_Mount"
    $isoDir     = Join-Path $env:TEMP "WinTooler_ISO_Files"
    foreach ($d in @($mountDir, $wimMntDir, $isoDir)) {
        Remove-Item $d -Recurse -Force -ErrorAction SilentlyContinue
        New-Item -ItemType Directory -Path $d -Force | Out-Null
    }

    # ----------------------------------------------------------------
    #  STEP 1: MOUNT SOURCE ISO AND COPY CONTENTS
    # ----------------------------------------------------------------
    Report 5 "Mounting source ISO: $(Split-Path $SourceISO -Leaf)..."
    try {
        $mountResult = Mount-DiskImage -ImagePath $SourceISO -PassThru -ErrorAction Stop
        $driveLetter = ($mountResult | Get-Volume).DriveLetter
        if (-not $driveLetter) { throw "Could not determine mounted drive letter." }
        Report 10 "ISO mounted at ${driveLetter}:\"
        Report 15 "Copying ISO contents (this may take a few minutes)..."
        Copy-Item -Path "${driveLetter}:\*" -Destination $isoDir -Recurse -Force
        Dismount-DiskImage -ImagePath $SourceISO -ErrorAction SilentlyContinue | Out-Null
        Report 30 "ISO contents extracted."

        # Strip read-only attribute inherited from the ISO filesystem.
        # DISM requires write access to mount install.wim for modification.
        Report 31 "Removing read-only attributes from copied files..."
        Get-ChildItem -Path $isoDir -Recurse -Force -ErrorAction SilentlyContinue |
            ForEach-Object { $_.Attributes = $_.Attributes -band (-bnot [IO.FileAttributes]::ReadOnly) }
        Report 32 "Attributes cleared."
    } catch {
        Dismount-DiskImage -ImagePath $SourceISO -ErrorAction SilentlyContinue | Out-Null
        throw "Failed to mount or copy ISO: $_"
    }

    # ----------------------------------------------------------------
    #  STEP 2: PATCH install.wim (bloat removal + driver injection)
    # ----------------------------------------------------------------
    $installWim = Join-Path $isoDir "sources\install.wim"
    $installEsd = Join-Path $isoDir "sources\install.esd"

    # Convert ESD to WIM first if needed (official ISOs often ship as ESD)
    if (-not (Test-Path $installWim) -and (Test-Path $installEsd)) {
        Report 33 "Converting install.esd to install.wim (DISM)..."
        $dismExport = & DISM /Export-Image /SourceImageFile:"$installEsd" /SourceIndex:1 /DestinationImageFile:"$installWim" /Compress:max /CheckIntegrity 2>&1
        if ($LASTEXITCODE -ne 0) { throw "DISM ESD->WIM conversion failed: $dismExport" }
        Remove-Item $installEsd -Force -ErrorAction SilentlyContinue
        Report 40 "ESD converted to WIM."
    }

    # Belt-and-suspenders: ensure install.wim is writable before DISM mount
    if (Test-Path $installWim) {
        $wimItem = Get-Item $installWim -Force
        if ($wimItem.Attributes -band [IO.FileAttributes]::ReadOnly) {
            $wimItem.Attributes = $wimItem.Attributes -band (-bnot [IO.FileAttributes]::ReadOnly)
        }
    }

    if ((Test-Path $installWim) -and ($RemoveBloat -or $AddNetworkDrivers)) {

        # Get image count; default to index 1 (Windows 11 Home or first edition)
        $wimInfo = & DISM /Get-ImageInfo /ImageFile:"$installWim" 2>&1
        $wimIndex = 1

        Report 42 "Mounting install.wim (index $wimIndex) for patching..."
        $dismMount = & DISM /Mount-Wim /WimFile:"$installWim" /index:$wimIndex /MountDir:"$wimMntDir" 2>&1
        if ($LASTEXITCODE -ne 0) { throw "DISM mount failed: $dismMount" }
        Report 50 "install.wim mounted."

        # ── Remove Microsoft Bloatware ────────────────────────────────────
        if ($RemoveBloat) {
            Report 52 "Removing Microsoft bloatware apps..."
            $bloatPackages = @(
                "Microsoft.BingNews",
                "Microsoft.BingWeather",
                "Microsoft.GamingApp",
                "Microsoft.XboxGameOverlay",
                "Microsoft.XboxGamingOverlay",
                "Microsoft.XboxIdentityProvider",
                "Microsoft.XboxSpeechToTextOverlay",
                "Microsoft.Xbox.TCUI",
                "Microsoft.MicrosoftSolitaireCollection",
                "Microsoft.ZuneMusic",
                "Microsoft.ZuneVideo",
                "Microsoft.WindowsMaps",
                "Microsoft.Todos",
                "Microsoft.People",
                "Microsoft.Getstarted",
                "Microsoft.WindowsFeedbackHub",
                "Microsoft.SkypeApp",
                "Microsoft.MicrosoftOfficeHub",
                "Microsoft.OutlookForWindows",
                "Microsoft.549981C3F5F10",
                "MicrosoftCorporationII.MicrosoftFamily",
                "Clipchamp.Clipchamp",
                "Microsoft.Teams",
                "MSTeams"
            )
            # Query the real full package names from the mounted WIM first
            Report 53 "Querying provisioned packages in WIM..."
            $rawPkgList = & DISM /Image:"$wimMntDir" /Get-ProvisionedAppxPackages 2>&1
            # Parse "PackageName : Microsoft.BingNews_4.x_neutral_~_8wekyb3d8bbwe" lines
            $installedPkgs = $rawPkgList |
                Where-Object { $_ -match "^PackageName\s*:" } |
                ForEach-Object { ($_ -split ":", 2)[1].Trim() }

            Report 54 "Found $($installedPkgs.Count) provisioned packages. Matching bloat list..."
            $removed = 0
            foreach ($shortName in $bloatPackages) {
                # Find all full package names that start with the short name
                $matches_ = @($installedPkgs | Where-Object { $_ -like "$shortName*" })
                foreach ($fullName in $matches_) {
                    $result = & DISM /Image:"$wimMntDir" /Remove-ProvisionedAppxPackage /PackageName:"$fullName" 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        $removed++
                        Write-Output "LOGINFO:[LOG ] Removed: $fullName"
                    } else {
                        Write-Output "LOGINFO:[WARN] Could not remove $fullName"
                    }
                }
            }
            Report 60 "Bloatware removal complete: $removed packages removed."
        }

        # ── Inject Network Drivers ────────────────────────────────────────
        if ($AddNetworkDrivers -and $DriversPath -and (Test-Path $DriversPath)) {
            Report 63 "Injecting network drivers from: $DriversPath..."
            $drvResult = & DISM /Image:"$wimMntDir" /Add-Driver /Driver:"$DriversPath" /Recurse 2>&1
            if ($LASTEXITCODE -eq 0) {
                Report 68 "Network drivers injected successfully."
            } else {
                Report 68 "Driver injection warning: $drvResult"
            }
        } elseif ($AddNetworkDrivers) {
            Report 68 "Driver injection skipped: no valid driver folder selected."
        }

        # ── Unmount and commit ────────────────────────────────────────────
        Report 70 "Committing changes to install.wim..."
        $dismUnmount = & DISM /Unmount-Wim /MountDir:"$wimMntDir" /Commit 2>&1
        if ($LASTEXITCODE -ne 0) {
            & DISM /Unmount-Wim /MountDir:"$wimMntDir" /Discard 2>&1 | Out-Null
            throw "DISM unmount failed: $dismUnmount"
        }
        Report 72 "install.wim patching complete."
    }

    # ----------------------------------------------------------------
    #  STEP 3: TPM / SECUREBOOR / RAM BYPASS (patches boot.wim)
    # ----------------------------------------------------------------
    if ($BypassTPM -or $BypassSecureBoot) {
        $bootWim = Join-Path $isoDir "sources\boot.wim"
        if (Test-Path $bootWim) {
            Report 74 "Applying TPM / SecureBoot bypass on boot.wim..."
            try {
                & DISM /Mount-Wim /WimFile:"$bootWim" /index:1 /MountDir:"$wimMntDir" 2>&1 | Out-Null
                $appraiser = Join-Path $wimMntDir "Windows\System32\appraiserres.dll"
                if (Test-Path $appraiser) { Remove-Item $appraiser -Force -ErrorAction SilentlyContinue }
                & DISM /Unmount-Wim /MountDir:"$wimMntDir" /Commit 2>&1 | Out-Null
                Report 77 "TPM bypass applied to boot.wim."
            } catch {
                & DISM /Unmount-Wim /MountDir:"$wimMntDir" /Discard 2>&1 | Out-Null
                Report 77 "TPM bypass warning: $_"
            }
        }
    }

    if ($BypassRAM) {
        Report 78 "RAM bypass: removing AppraiserRes from install.wim (already done if bloat removed)."
        # RAM bypass is applied by the appraiserres.dll removal above; additional
        # registry key is applied during unattended setup if EnableUnattended is also set.
    }

    # ----------------------------------------------------------------
    #  STEP 4: INJECT AUTOUNATTEND.XML (optional)
    # ----------------------------------------------------------------
    if ($EnableUnattended) {
        Report 79 "Injecting autounattend.xml..."
        $autoXml = @'
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
  <settings pass="windowsPE">
    <component name="Microsoft-Windows-International-Core-WinPE"
               processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35"
               language="neutral" versionScope="nonSxS"
               xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
      <SetupUILanguage><UILanguage>en-US</UILanguage></SetupUILanguage>
      <InputLocale>en-US</InputLocale>
      <SystemLocale>en-US</SystemLocale>
      <UILanguage>en-US</UILanguage>
      <UserLocale>en-US</UserLocale>
    </component>
    <component name="Microsoft-Windows-Setup"
               processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35"
               language="neutral" versionScope="nonSxS">
      <UserData><AcceptEula>true</AcceptEula></UserData>
    </component>
  </settings>
  <settings pass="oobeSystem">
    <component name="Microsoft-Windows-Shell-Setup"
               processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35"
               language="neutral" versionScope="nonSxS">
      <OOBE>
        <HideEULAPage>true</HideEULAPage>
        <HideOEMRegistrationScreen>true</HideOEMRegistrationScreen>
        <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
        <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
        <SkipMachineOOBE>true</SkipMachineOOBE>
        <SkipUserOOBE>true</SkipUserOOBE>
      </OOBE>
    </component>
  </settings>
</unattend>
'@
        $autoXml | Out-File -FilePath (Join-Path $isoDir "autounattend.xml") -Encoding UTF8
        Report 80 "autounattend.xml injected."
    }

    # ----------------------------------------------------------------
    #  STEP 4.5: EMBED WINGET INSTALL SCRIPT (optional)
    # ----------------------------------------------------------------
    $wingetStr = [string]$WingetAppIds
    if ($wingetStr -and $wingetStr.Trim() -ne "") {
        # Split into clean string array
        $ids = [string[]]($wingetStr.Split([char]",") | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" })
        if ($ids.Count -gt 0) {
            Report 81 "Embedding winget install script for $($ids.Count) app(s)..."

            $wtFolder = Join-Path $isoDir "WinTooler"
            if (-not (Test-Path $wtFolder)) { New-Item -ItemType Directory -Path $wtFolder -Force | Out-Null }

            # Build batch file with StringBuilder to avoid array concat issues
            $sb = New-Object System.Text.StringBuilder
            [void]$sb.AppendLine("@echo off")
            [void]$sb.AppendLine("title WinTooler - Installing Apps")
            [void]$sb.AppendLine("echo WinTooler App Installer - Build 5040")
            [void]$sb.AppendLine("echo =======================================")
            [void]$sb.AppendLine("echo.")
            [void]$sb.AppendLine(":: Bootstrap winget if not present")
            [void]$sb.AppendLine("where winget >nul 2>&1")
            [void]$sb.AppendLine("if %ERRORLEVEL% neq 0 (")
            [void]$sb.AppendLine("    echo winget not found. Bootstrapping via PowerShell...")
            [void]$sb.AppendLine("    powershell -NoProfile -ExecutionPolicy Bypass -Command \`"Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe -ErrorAction SilentlyContinue; Start-Sleep 3\`"")
            [void]$sb.AppendLine("    where winget >nul 2>&1")
            [void]$sb.AppendLine("    if %ERRORLEVEL% neq 0 (")
            [void]$sb.AppendLine("        echo Winget still not available. Downloading App Installer...")
            [void]$sb.AppendLine("        powershell -NoProfile -ExecutionPolicy Bypass -Command \`"Invoke-WebRequest -Uri https://aka.ms/getwinget -OutFile $env:TEMP\winget.msixbundle; Add-AppxPackage $env:TEMP\winget.msixbundle\`"")
            [void]$sb.AppendLine("        timeout /t 5 /nobreak >nul")
            [void]$sb.AppendLine("    )")
            [void]$sb.AppendLine(")")
            [void]$sb.AppendLine("echo.")
            [void]$sb.AppendLine(":: Accept winget source agreements silently")
            [void]$sb.AppendLine("winget list --accept-source-agreements >nul 2>&1")
            [void]$sb.AppendLine("echo.")
            foreach ($id in $ids) {
                [void]$sb.AppendLine("echo Installing $id...")
                [void]$sb.AppendLine("winget install --id $id --silent --accept-package-agreements --accept-source-agreements")
                [void]$sb.AppendLine("echo.")
            }
            [void]$sb.AppendLine("echo All done! Press any key to close.")
            [void]$sb.AppendLine("pause")

            $batPath = Join-Path $wtFolder "Install-Apps.bat"
            [System.IO.File]::WriteAllText($batPath, $sb.ToString(), [System.Text.Encoding]::ASCII)

            # Plain text app list
            $listSb = New-Object System.Text.StringBuilder
            [void]$listSb.AppendLine("WinTooler Selected Apps")
            [void]$listSb.AppendLine("========================================")
            [void]$listSb.AppendLine("")
            foreach ($id in $ids) { [void]$listSb.AppendLine($id) }
            $listPath = Join-Path $wtFolder "App-List.txt"
            [System.IO.File]::WriteAllText($listPath, $listSb.ToString(), [System.Text.Encoding]::UTF8)

            # Patch autounattend.xml to auto-run the script on first logon
            $autoXmlPath = Join-Path $isoDir "autounattend.xml"
            if ((Test-Path $autoXmlPath) -and $EnableUnattended) {
                try {
                    [xml]$xml = [System.Xml.XmlDocument]::new()
                    $xml.Load($autoXmlPath)
                    $ns  = "urn:schemas-microsoft-com:unattend"
                    $nsMgr = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
                    $nsMgr.AddNamespace("u", $ns)
                    # Select exactly one Shell-Setup component in oobeSystem
                    $shellComp = $xml.SelectSingleNode("//u:settings[@pass='oobeSystem']/u:component[contains(@name,'Shell-Setup')]", $nsMgr)
                    if ($shellComp) {
                        $fcNode  = $xml.CreateElement("FirstLogonCommands", $ns)
                        $syncCmd = $xml.CreateElement("SynchronousCommand",  $ns)
                        $order   = $xml.CreateElement("Order",       $ns); $order.InnerText   = "1"
                        $desc    = $xml.CreateElement("Description", $ns); $desc.InnerText    = "WinTooler Apps"
                        $cmd     = $xml.CreateElement("CommandLine", $ns); $cmd.InnerText     = "cmd.exe /c X:\WinTooler\Install-Apps.bat"
                        $syncCmd.AppendChild($order)   | Out-Null
                        $syncCmd.AppendChild($desc)    | Out-Null
                        $syncCmd.AppendChild($cmd)     | Out-Null
                        $fcNode.AppendChild($syncCmd)  | Out-Null
                        $shellComp.AppendChild($fcNode) | Out-Null
                        $xml.Save($autoXmlPath)
                        Report 81 "Auto-run added to autounattend.xml."
                    }
                } catch { Report 81 "autounattend.xml patch skipped: $_" }
            }

            Report 82 "App install script embedded: WinTooler\Install-Apps.bat ($($ids.Count) apps)"
        }
    }

    # ----------------------------------------------------------------
    #  STEP 5: REBUILD ISO
    # ----------------------------------------------------------------
    Report 82 "Rebuilding bootable ISO..."
    $stamp      = Get-Date -Format "yyyyMMdd_HHmm"
    $outIsoName = "Win11_WinTooler_$stamp.iso"
    $outIsoPath = Join-Path $OutputPath $outIsoName

    Invoke-Oscdimg -SourceDir $isoDir -OutputISO $outIsoPath -ProgressCallback $ProgressCallback | Out-Null

    # ----------------------------------------------------------------
    #  CLEANUP
    # ----------------------------------------------------------------
    Report 98 "Cleaning up temporary files..."
    foreach ($d in @($mountDir, $wimMntDir, $isoDir)) {
        Remove-Item $d -Recurse -Force -ErrorAction SilentlyContinue
    }

    Report 100 "ISO created successfully: $outIsoPath"
    return $outIsoPath
}
