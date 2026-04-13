<#
.SYNOPSIS
    WinTooler V0.7.1 beta - Build 5040
    Private helper: Convert Windows ESD to bootable ISO

.DESCRIPTION
    Uses DISM to apply the ESD to a WIM format, then oscdimg (ADK) or
    wimlib-imagex to create a bootable ISO image.
#>
# Write-WTLog stub for background job context (main session function not available)
if (-not (Get-Command Write-WTLog -ErrorAction SilentlyContinue)) {
    function Write-WTLog {
        param([string]$Message, [string]$Level = "INFO")
        $prefix = if ($Level -eq "WARN") { "WARN" } elseif ($Level -eq "ERROR") { "ERR " } else { "LOG " }
        Write-Output "LOGINFO:[$prefix] $Message"
    }
}


function Convert-ESDtoISO {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string] $ESDPath,
        [Parameter(Mandatory)][string] $OutputDir,
        [string]  $MountDir,
        [string]  $ScratchDir,
        [string]  $ISOFilesDir,
        [switch]  $BypassTPM,
        [switch]  $EnableUnattended,
        [scriptblock] $ProgressCallback = $null
    )

    function Report {
        param([int]$Pct, [string]$Msg)
        if ($ProgressCallback) { & $ProgressCallback $Pct $Msg }
        else { Write-Host "  [$Pct%] $Msg" -ForegroundColor DarkCyan }
        Write-WTLog "ISO-CONV: $Msg"
    }

    $wimPath = Join-Path $ScratchDir "install.wim"
    $isoName = "WinTooler_Win11_$(Get-Date -Format 'yyyyMMdd_HHmm').iso"
    $isoOut  = Join-Path $OutputDir $isoName

    # ---- Extract ESD index information ----
    Report 68 "Reading ESD file structure..."
    $esdInfo = & dism.exe /Get-WimInfo /WimFile:"$ESDPath" 2>&1
    $indices = [regex]::Matches($esdInfo, 'Index\s*:\s*(\d+)') | ForEach-Object { [int]$_.Groups[1].Value }
    # Find the Windows 11 Pro or Home index (typically last index)
    $installIdx = $indices | Where-Object { $_ -ge 3 } | Select-Object -Last 1
    if (-not $installIdx) { $installIdx = $indices | Select-Object -Last 1 }
    Report 69 "Using WIM index $installIdx for conversion"

    # ---- ESD → WIM via DISM ----
    Report 70 "Exporting ESD index $installIdx to WIM (may take 5-10 minutes)..."
    $dismResult = & dism.exe /Export-Image `
        /SourceImageFile:"$ESDPath" `
        /SourceIndex:$installIdx `
        /DestinationImageFile:"$wimPath" `
        /Compress:Max `
        /CheckIntegrity 2>&1

    $dismExit = $LASTEXITCODE
    if ($dismExit -ne 0) {
        Write-WTLog "DISM export output: $dismResult" "WARN"
        # Fallback: try wimlib if available
        $wimlibPath = Invoke-Oscdimg -CheckWimlib
        if ($wimlibPath) {
            Report 71 "DISM failed, trying wimlib fallback..."
            & "$wimlibPath" wim "$ESDPath" $installIdx --to-stdout `
                | & "$wimlibPath" --command "wim add - '$wimPath'"
        } else {
            throw "DISM ESD export failed (exit $dismExit). Ensure Windows ADK is installed."
        }
    }
    Report 82 "WIM creation complete: $wimPath"

    # ---- Build ISO file tree ----
    Report 83 "Building ISO file structure..."

    # Copy boot files from ESD (index 1 = Windows PE / boot)
    $bootWim = Join-Path $ScratchDir "boot.wim"
    & dism.exe /Export-Image /SourceImageFile:"$ESDPath" /SourceIndex:1 `
        /DestinationImageFile:"$bootWim" /Compress:Fast 2>&1 | Out-Null

    # Copy WIM files into ISO staging area
    $sourcesDir = Join-Path $ISOFilesDir "sources"
    if (-not (Test-Path $sourcesDir)) { New-Item -ItemType Directory $sourcesDir -Force | Out-Null }

    Copy-Item $wimPath  (Join-Path $sourcesDir "install.wim")  -Force
    if (Test-Path $bootWim) { Copy-Item $bootWim (Join-Path $sourcesDir "boot.wim") -Force }

    # ---- TPM / Secure Boot / RAM bypass injection ----
    if ($BypassTPM) {
        Report 85 "Injecting TPM/Secure Boot bypass..."
        try {
            # Apply bypass via WIM mount
            & dism.exe /Mount-Image /ImageFile:"$wimPath" /Index:1 /MountDir:"$MountDir" 2>&1 | Out-Null

            # appraiserres.dll swap (makes setup skip hardware checks)
            $appraiserDest = Join-Path $MountDir "Windows\System32\appraiserres.dll"
            if (Test-Path $appraiserDest) {
                # Create blank placeholder — prevents hardware check from loading
                [System.IO.File]::WriteAllBytes($appraiserDest, [byte[]]@(77,90))  # MZ header stub
                Write-WTLog "TPM bypass: appraiserres.dll replaced"
            }

            # Unmount and commit
            & dism.exe /Unmount-Image /MountDir:"$MountDir" /Commit 2>&1 | Out-Null
            Report 87 "TPM bypass applied."
        } catch {
            Write-WTLog "TPM bypass failed: $_" "WARN"
            & dism.exe /Unmount-Image /MountDir:"$MountDir" /Discard 2>&1 | Out-Null
        }
    }

    # ---- Unattended XML injection ----
    if ($EnableUnattended) {
        Report 88 "Injecting autounattend.xml..."
        $unattendXml = @'
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
  <settings pass="windowsPE">
    <component name="Microsoft-Windows-International-Core-WinPE"
               processorArchitecture="amd64"
               publicKeyToken="31bf3856ad364e35"
               language="neutral" versionScope="nonSxS">
      <SetupUILanguage><UILanguage>en-US</UILanguage></SetupUILanguage>
      <InputLocale>0409:00000409</InputLocale>
      <UILanguage>en-US</UILanguage>
      <UserLocale>en-US</UserLocale>
    </component>
    <component name="Microsoft-Windows-Setup"
               processorArchitecture="amd64"
               publicKeyToken="31bf3856ad364e35"
               language="neutral" versionScope="nonSxS">
      <UserData>
        <AcceptEula>true</AcceptEula>
        <ProductKey><WillShowUI>OnError</WillShowUI></ProductKey>
      </UserData>
      <EnableFirewall>true</EnableFirewall>
    </component>
  </settings>
</unattend>
'@
        $unattendPath = Join-Path $ISOFilesDir "autounattend.xml"
        $unattendXml | Out-File -FilePath $unattendPath -Encoding UTF8
        Report 89 "autounattend.xml written."
    }

    # ---- Create ISO with oscdimg ----
    Report 90 "Creating bootable ISO with oscdimg..."
    $isoCreated = Invoke-Oscdimg -SourceDir $ISOFilesDir -OutputISO $isoOut -ProgressCallback $ProgressCallback

    if (-not $isoCreated) {
        throw "ISO creation failed. Verify Windows ADK / oscdimg is installed at: $env:ProgramFiles\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg"
    }

    Report 97 "ISO creation complete: $isoOut ($([math]::Round((Get-Item $isoOut).Length/1GB,2)) GB)"
    return $isoOut
}
