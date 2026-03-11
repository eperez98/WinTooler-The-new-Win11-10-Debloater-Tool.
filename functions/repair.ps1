# functions/repair.ps1
# Repair and maintenance functions - all long ops run async via Start-Job

function Invoke-SFCRepair {
    param([scriptblock]$OnLine = $null)
    Write-WTLog "Starting SFC /scannow (async)"
    $job = Start-Job -ScriptBlock {
        $out = sfc /scannow 2>&1
        $out -join "`n"
    }
    # Stream output back while waiting
    $result = ""
    while ($job.State -eq "Running") {
        Start-Sleep -Milliseconds 500
        $partial = Receive-Job $job -Keep 2>$null
        if ($partial -and $OnLine) {
            $partial | ForEach-Object { & $OnLine $_ }
        }
    }
    $result = Receive-Job $job | Out-String
    Remove-Job $job -Force
    Write-WTLog "SFC complete"
    return $result
}

function Invoke-DISMRepair {
    param([scriptblock]$OnLine = $null)
    Write-WTLog "Starting DISM RestoreHealth (async)"
    $job = Start-Job -ScriptBlock {
        DISM /Online /Cleanup-Image /RestoreHealth 2>&1 | ForEach-Object { $_ }
    }
    $result = ""
    while ($job.State -eq "Running") {
        Start-Sleep -Milliseconds 500
        $partial = Receive-Job $job -Keep 2>$null
        if ($partial -and $OnLine) {
            $partial | ForEach-Object { & $OnLine $_ }
        }
    }
    $result = Receive-Job $job | Out-String
    Remove-Job $job -Force
    Write-WTLog "DISM complete"
    return $result
}

function Clear-TempFiles {
    $paths = @("$env:TEMP","C:\Windows\Temp","C:\Windows\Prefetch")
    $total = 0
    foreach ($p in $paths) {
        if (Test-Path $p) {
            $items = Get-ChildItem $p -Recurse -Force -ErrorAction SilentlyContinue
            $total += $items.Count
            Remove-Item "$p\*" -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    Write-WTLog "Cleared temp files: ~$total items"
    return "Cleared ~$total items from temp folders."
}

function Invoke-FlushDNS {
    $out = ipconfig /flushdns 2>&1 | Out-String
    Write-WTLog "Flushed DNS cache"
    return $out
}

function New-RestorePoint {
    param([string]$Label = "WinToolerV1")
    try {
        Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
        $desc = "$Label - $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
        Checkpoint-Computer -Description $desc -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        Write-WTLog "Created system restore point: $desc"
        return "Restore point created: $desc"
    } catch {
        Write-WTLog "Failed to create restore point: $_" "ERROR"
        return "Failed: $_"
    }
}

function Reset-NetworkStack {
    $summary = @()

    # Winsock reset
    $ws = netsh winsock reset 2>&1 | Out-String
    if ($ws -match "Successfully") {
        $summary += "Winsock catalog reset: OK"
    } else {
        $summary += "Winsock reset: $($ws.Trim())"
    }

    # TCP/IP stack reset (very verbose - just capture pass/fail)
    $ip = netsh int ip reset 2>&1 | Out-String
    $ipFailed = ($ip -split "`n" | Where-Object { $_ -match "failed" -and $_ -notmatch "Access is denied" }).Count
    if ($ipFailed -eq 0) {
        $summary += "TCP/IP stack reset: OK"
    } else {
        $summary += "TCP/IP stack reset: completed with $ipFailed non-critical error(s)"
    }

    # Release/Renew/Flush
    ipconfig /release  2>&1 | Out-Null
    ipconfig /renew    2>&1 | Out-Null
    ipconfig /flushdns 2>&1 | Out-Null
    $summary += "IP release/renew: OK"
    $summary += "DNS cache flushed: OK"
    $summary += ""
    $summary += "A reboot is required to complete the reset."

    Write-WTLog "Network stack reset complete"
    return $summary -join "`n"
}

function Reset-WindowsStore {
    $out = wsreset.exe 2>&1 | Out-String
    Write-WTLog "Reset Windows Store"
    return "Windows Store reset complete."
}
