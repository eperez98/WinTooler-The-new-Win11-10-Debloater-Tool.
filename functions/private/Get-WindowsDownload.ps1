<#
.SYNOPSIS
    WinTooler V0.7.1 beta - Build 5040
    Private helper: Download Windows 11 ESD from Microsoft using Fido-style API

.DESCRIPTION
    Queries Microsoft's download portals to obtain a signed, direct ESD URL
    for Windows 11. Falls back to the Fido PowerShell script method if the
    direct API approach fails.
#>
# Write-WTLog stub for background job context (main session function not available)
if (-not (Get-Command Write-WTLog -ErrorAction SilentlyContinue)) {
    function Write-WTLog {
        param([string]$Message, [string]$Level = "INFO")
        $prefix = if ($Level -eq "WARN") { "WARN" } elseif ($Level -eq "ERROR") { "ERR " } else { "LOG " }
        Write-Output "LOGINFO:[$prefix] $Message"
    }
}


function Get-WindowsDownload {
    [CmdletBinding()]
    param(
        [string] $Version       = "Windows 11 23H2",
        [string] $Language      = "English (United States)",
        [string] $Architecture  = "x64",
        [string] $OutputPath    = "$env:TEMP\Win11_x64.esd",
        [scriptblock] $ProgressCallback = $null
    )

    function Report {
        param([int]$Pct, [string]$Msg)
        if ($ProgressCallback) { & $ProgressCallback $Pct $Msg }
        else { Write-Host "  [$Pct%] $Msg" -ForegroundColor DarkCyan }
        Write-WTLog "ISO-DL: $Msg"
    }

    # ---- Method 1: Fido.ps1 (community script, Microsoft-sourced URLs) ----
    Report 5 "Attempting download via Fido method..."

    $fidoUrl  = "https://raw.githubusercontent.com/pbatard/Fido/master/Fido.ps1"
    $fidoPath = Join-Path $env:TEMP "Fido.ps1"

    try {
        Report 6 "Downloading Fido helper script..."
        (New-Object Net.WebClient).DownloadFile($fidoUrl, $fidoPath)

        if (Test-Path $fidoPath) {
            Report 8 "Fido downloaded. Resolving Windows 11 URL..."

            # Build version / language code mappings
            $releaseMap = @{
                "Windows 11 23H2" = "23H2"
                "Windows 11 22H2" = "22H2"
                "Windows 11 24H2" = "24H2"
            }
            $releaseId = $releaseMap[$Version]
            if (-not $releaseId) { $releaseId = "23H2" }

            # Run Fido to get the download URL (non-interactive mode)
            $fidoResult = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $fidoPath `
                -Win 11 -Rel $releaseId -Ed "Windows 11 Home/Pro" `
                -Lang $Language -Arch $Architecture -GetUrl 2>&1

            $downloadUrl = $fidoResult | Where-Object { $_ -match "^https://" } | Select-Object -First 1

            if ($downloadUrl) {
                Report 10 "Download URL resolved. Starting download (~5-6 GB)..."
                $wc = New-Object Net.WebClient
                $wc.Headers.Add("User-Agent", "WinTooler/5035 (Windows NT)")

                # Progress handler
                $wc.add_DownloadProgressChanged({
                    $pct = [int]($_.ProgressPercentage * 0.50) + 10  # Maps 0-100 → 10-60
                    if ($ProgressCallback) { & $ProgressCallback $pct "Downloading ESD: $($_.ProgressPercentage)% ($([math]::Round($_.BytesReceived/1MB))/$([math]::Round($_.TotalBytesToReceive/1MB)) MB)" }
                })

                $wc.DownloadFile($downloadUrl.Trim(), $OutputPath)
                Report 62 "ESD download complete."
                return $OutputPath
            }
        }
    } catch {
        Write-WTLog "Fido method failed: $_" "WARN"
        Report 10 "Fido method failed, trying direct UUP dump fallback..."
    }

    # ---- Method 2: UUP Dump API (alternative, builds from UUP files) ----
    Report 12 "Attempting UUP Dump fallback..."
    try {
        $uupApiUrl = "https://api.uupdump.net/listid.php?search=Windows+11+${Version}&sortByDate=1"
        $uupData   = Invoke-RestMethod -Uri $uupApiUrl -Headers @{"User-Agent"="WinTooler/5035"} -ErrorAction Stop

        if ($uupData.response.builds) {
            $build = $uupData.response.builds.PSObject.Properties |
                     Select-Object -First 1 -ExpandProperty Value

            if ($build.uuid) {
                Report 15 "Found build UUID: $($build.uuid). Generating download package..."

                # UUP conversion script download
                $convUrl  = "https://uupdump.net/get.php?id=$($build.uuid)&pack=en-us&edition=professional&autodl=2"
                $convPath = Join-Path $env:TEMP "uup_download.zip"
                (New-Object Net.WebClient).DownloadFile($convUrl, $convPath)

                # Extract and run
                $convDir  = Join-Path $env:TEMP "uup_convert"
                Expand-Archive -Path $convPath -DestinationPath $convDir -Force

                $convertScript = Get-ChildItem -Path $convDir -Filter "convert-UUP.cmd" | Select-Object -First 1
                if ($convertScript) {
                    Report 20 "Running UUP conversion (this may take 15-30 minutes)..."
                    $proc = Start-Process -FilePath "cmd.exe" `
                        -ArgumentList "/c `"$($convertScript.FullName)`"" `
                        -WorkingDirectory $convDir -Wait -PassThru -NoNewWindow
                    if ($proc.ExitCode -eq 0) {
                        $isoResult = Get-ChildItem -Path $convDir -Filter "*.iso" | Select-Object -First 1
                        if ($isoResult) {
                            Copy-Item $isoResult.FullName -Destination $OutputPath -Force
                            Report 62 "UUP conversion complete."
                            return $OutputPath
                        }
                    }
                }
            }
        }
    } catch {
        Write-WTLog "UUP Dump fallback failed: $_" "WARN"
    }

    # ---- Method 3: Media Creation Tool automation ----
    Report 30 "Falling back to Media Creation Tool..."
    try {
        $mctUrl  = "https://go.microsoft.com/fwlink/?LinkId=2265055"   # Win11 MCT
        $mctPath = Join-Path $env:TEMP "MediaCreationTool.exe"
        Report 32 "Downloading Media Creation Tool (~10 MB)..."
        (New-Object Net.WebClient).DownloadFile($mctUrl, $mctPath)

        if (Test-Path $mctPath) {
            # MCT /Quiet /MediaType ISO /MediaPath OutputPath  (documented flags)
            $outIso = Join-Path $OutputPath "Windows11.iso"
            Report 35 "Running Media Creation Tool (interactive window will appear)..."
            $proc = Start-Process -FilePath $mctPath `
                -ArgumentList "/Quiet /MediaType ISO /MediaPath `"$OutputPath`"" `
                -Wait -PassThru
            if ($proc.ExitCode -eq 0 -and (Test-Path $outIso)) {
                Report 62 "Media Creation Tool completed."
                return $outIso
            } else {
                throw "Media Creation Tool exited with code $($proc.ExitCode)"
            }
        }
    } catch {
        Write-WTLog "MCT fallback failed: $_" "ERROR"
        throw "All download methods failed. Please download Windows 11 ISO manually from https://microsoft.com/software-download/windows11`n`nError: $_"
    }
}
