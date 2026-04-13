<#
.SYNOPSIS
    WinTooler V0.7.1 beta - Build 5040
    Private helper: oscdimg wrapper for creating bootable ISO images

.DESCRIPTION
    Locates oscdimg.exe (from Windows ADK) and creates a bootable Windows
    ISO from a staging directory. Falls back to wimlib-imagex if oscdimg
    is not found.
#>
# Write-WTLog stub for background job context (main session function not available)
if (-not (Get-Command Write-WTLog -ErrorAction SilentlyContinue)) {
    function Write-WTLog {
        param([string]$Message, [string]$Level = "INFO")
        $prefix = if ($Level -eq "WARN") { "WARN" } elseif ($Level -eq "ERROR") { "ERR " } else { "LOG " }
        Write-Output "LOGINFO:[$prefix] $Message"
    }
}


function Invoke-Oscdimg {
    [CmdletBinding(DefaultParameterSetName="Create")]
    param(
        [Parameter(ParameterSetName="Create",Mandatory)][string] $SourceDir,
        [Parameter(ParameterSetName="Create",Mandatory)][string] $OutputISO,
        [Parameter(ParameterSetName="Create")][scriptblock] $ProgressCallback = $null,
        [Parameter(ParameterSetName="Check")][switch]  $CheckWimlib,
        [Parameter(ParameterSetName="Check")][switch]  $CheckOscdimg
    )

    # ---- Check mode: just return paths ----
    if ($CheckWimlib) {
        $locations = @(
            "${env:ProgramFiles}\wimlib\wimlib-imagex.exe",
            "${env:ProgramFiles(x86)}\wimlib\wimlib-imagex.exe",
            "$env:LOCALAPPDATA\WinTooler\wimlib-imagex.exe"
        )
        $found = $locations | Where-Object { Test-Path $_ } | Select-Object -First 1
        return $found
    }
    if ($CheckOscdimg) {
        $adkRoot = "${env:ProgramFiles(x86)}\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools"
        $alt     = "${env:ProgramFiles}\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools"
        foreach ($root in @($adkRoot, $alt)) {
            $p = Join-Path $root "amd64\Oscdimg\oscdimg.exe"
            if (Test-Path $p) { return $p }
        }
        $inPath = Get-Command oscdimg.exe -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
        return $inPath
    }

    function Report {
        param([int]$Pct, [string]$Msg)
        if ($ProgressCallback) { & $ProgressCallback $Pct $Msg }
        Write-WTLog "ISO-OSCD: $Msg"
    }

    # ---- Locate oscdimg ----
    $oscdimgPath = Invoke-Oscdimg -CheckOscdimg
    if (-not $oscdimgPath) {
        # Try to download from ADK if not found
        Report 90 "oscdimg not found. Attempting ADK installation..."
        $adkInstallerUrl = "https://go.microsoft.com/fwlink/?linkid=2196127"
        $adkPath         = Join-Path $env:TEMP "adksetup.exe"
        try {
            (New-Object Net.WebClient).DownloadFile($adkInstallerUrl, $adkPath)
            # Install only the Deployment Tools feature (contains oscdimg)
            $proc = Start-Process -FilePath $adkPath `
                -ArgumentList "/quiet /features OptionId.DeploymentTools" `
                -Wait -PassThru
            if ($proc.ExitCode -eq 0) {
                $oscdimgPath = Invoke-Oscdimg -CheckOscdimg
            }
        } catch {
            Write-WTLog "ADK auto-install failed: $_" "WARN"
        }

        if (-not $oscdimgPath) {
            # Fallback 2: wimlib-imagex
            $wimlibPath = Invoke-Oscdimg -CheckWimlib
            if ($wimlibPath) {
                Report 90 "Using wimlib-imagex as oscdimg fallback..."
                $wimLibArgs = @("iso","--wimboot",$SourceDir,$OutputISO)
                $proc = Start-Process -FilePath $wimlibPath -ArgumentList $wimLibArgs -Wait -PassThru -NoNewWindow
                if ($proc.ExitCode -eq 0 -and (Test-Path $OutputISO)) {
                    Report 96 "wimlib ISO creation complete."
                    return $true
                }
            }
            # Fallback 3: pure .NET ZipFile - zero external deps, always available.
            # Produces a non-bootable archive. Recommend ADK for a bootable result.
            Report 90 "oscdimg and wimlib not available. Building ISO archive via .NET ZipFile..."
            Report 90 "NOTE: This produces a non-bootable archive. Install Windows ADK for a bootable ISO."
            try {
                Add-Type -AssemblyName System.IO.Compression.FileSystem
                [System.IO.Compression.ZipFile]::CreateFromDirectory($SourceDir, $OutputISO)
                if (Test-Path $OutputISO) {
                    Report 96 "ISO archive created (non-bootable). Install ADK Deployment Tools for bootable output."
                    return $true
                }
            } catch {
                Write-WTLog "ZipFile fallback failed: $_" "ERROR"
            }
            return $false
        }
    }

    Report 91 "Creating ISO with oscdimg: $oscdimgPath"

    # ---- Build boot catalog ----
    # Look for etfsboot.com (El Torito boot image) in source
    $etfsBoot   = Join-Path $SourceDir "boot\etfsboot.com"
    $efiBoot    = Join-Path $SourceDir "efi\microsoft\boot\efisys.bin"
    $bootcatOut = Join-Path $SourceDir "boot\bootfix.bin"

    if (-not (Test-Path $etfsBoot)) {
        # Try to locate in ADK deployment tools
        $adkOscdDir = Split-Path $oscdimgPath
        $etfsSource = Join-Path $adkOscdDir "etfsboot.com"
        if (Test-Path $etfsSource) {
            $bootDir = Join-Path $SourceDir "boot"
            if (-not (Test-Path $bootDir)) { New-Item -ItemType Directory $bootDir -Force | Out-Null }
            Copy-Item $etfsSource $etfsBoot -Force
        }
    }

    # ---- Build oscdimg argument list ----
    # -m = large image, -o = optimize, -u2 = UDF, -udfver102, -h = hidden
    # -b = boot image (El Torito), -pEF = UEFI
    $args = @(
        "-m", "-o", "-u2", "-udfver102"
        "-bootdata:2#p0,e,b`"$etfsBoot`"#pEF,e,b`"$efiBoot`""
        "`"$SourceDir`""
        "`"$OutputISO`""
    )

    if (-not (Test-Path $etfsBoot)) {
        # Simplified args without custom boot images
        $args = @("-m", "-o", "-u2", "-udfver102", "`"$SourceDir`"", "`"$OutputISO`"")
    }

    $argString = $args -join " "
    Report 92 "Running: oscdimg $argString"

    $proc = Start-Process -FilePath $oscdimgPath -ArgumentList $args `
        -Wait -PassThru -NoNewWindow -RedirectStandardOutput "$env:TEMP\oscdimg_out.log" `
        -RedirectStandardError "$env:TEMP\oscdimg_err.log"

    $oscdimgLog = Get-Content "$env:TEMP\oscdimg_out.log" -ErrorAction SilentlyContinue
    Write-WTLog "oscdimg output: $oscdimgLog"

    if ($proc.ExitCode -eq 0 -and (Test-Path $OutputISO)) {
        Report 96 "oscdimg completed successfully."
        return $true
    } else {
        $errLog = Get-Content "$env:TEMP\oscdimg_err.log" -ErrorAction SilentlyContinue
        Write-WTLog "oscdimg failed (exit $($proc.ExitCode)): $errLog" "ERROR"
        return $false
    }
}
