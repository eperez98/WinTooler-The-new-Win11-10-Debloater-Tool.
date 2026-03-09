# functions/updates.ps1
# Windows Update management functions for WinToolerV1

function Install-PSWindowsUpdate {
    if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
        Write-WTLog "Installing PSWindowsUpdate module..."
        Install-PackageProvider -Name NuGet -Force -Scope CurrentUser -ErrorAction SilentlyContinue | Out-Null
        Install-Module -Name PSWindowsUpdate -Force -Scope CurrentUser -ErrorAction Stop
        Write-WTLog "PSWindowsUpdate installed"
    }
    Import-Module PSWindowsUpdate -ErrorAction SilentlyContinue
}

function Get-PendingUpdates {
    try {
        Install-PSWindowsUpdate
        return Get-WindowsUpdate -AcceptAll -ErrorAction Stop
    } catch {
        Write-WTLog "Failed to get updates: $_" "ERROR"
        return $null
    }
}

function Start-WindowsUpdates {
    try {
        Install-PSWindowsUpdate
        $result = Get-WindowsUpdate -AcceptAll -Install -AutoReboot:$false 2>&1 | Out-String
        Write-WTLog "Updates applied"
        return $result
    } catch {
        Write-WTLog "Update failed: $_" "ERROR"
        return "Error: $_"
    }
}

function Suspend-WindowsUpdates {
    param([int]$Days = 7)
    $path   = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
    if (-not (Test-Path $path)) { New-Item $path -Force | Out-Null }
    $paused = (Get-Date).AddDays($Days).ToString("yyyy-MM-dd")
    Set-ItemProperty $path -Name "PauseQualityUpdatesStartTime" -Value $paused -Type String -Force
    Set-ItemProperty $path -Name "PauseFeatureUpdatesStartTime" -Value $paused -Type String -Force
    Write-WTLog "Paused Windows Updates until $paused"
    return "Updates paused until $paused"
}

function Resume-WindowsUpdates {
    $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
    Remove-ItemProperty $path -Name "PauseQualityUpdatesStartTime" -ErrorAction SilentlyContinue
    Remove-ItemProperty $path -Name "PauseFeatureUpdatesStartTime" -ErrorAction SilentlyContinue
    Write-WTLog "Resumed Windows Updates"
    return "Windows Update resumed."
}
