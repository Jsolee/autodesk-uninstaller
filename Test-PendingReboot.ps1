<#
.SYNOPSIS
    Test script to check for pending reboot conditions
.DESCRIPTION
    This script checks the same pending reboot conditions that the enhanced uninstaller checks.
    Run this before using the uninstaller to see if you have pending reboot issues.
.OUTPUTS
    Reports on all pending reboot conditions found
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'

Write-Host "=== PENDING REBOOT DETECTION TEST ===" -ForegroundColor Cyan
Write-Host "This script checks for the same pending reboot conditions that cause MSI failures." -ForegroundColor Yellow
Write-Host ""

$pendingReboot = $false
$reasons = @()

Write-Host "Checking Windows Update pending reboot..." -ForegroundColor Green
try {
    if (Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" -ErrorAction SilentlyContinue) {
        $pendingReboot = $true
        $reasons += "Windows Update requires reboot"
        Write-Host "  ✗ Windows Update reboot required" -ForegroundColor Red
    } else {
        Write-Host "  ✓ No Windows Update reboot pending" -ForegroundColor Green
    }
} catch {
    Write-Host "  ? Could not check Windows Update status" -ForegroundColor Yellow
}

Write-Host "Checking Component Based Servicing..." -ForegroundColor Green
try {
    if (Get-Item "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" -ErrorAction SilentlyContinue) {
        $pendingReboot = $true
        $reasons += "Component Based Servicing requires reboot"
        Write-Host "  ✗ Component Based Servicing reboot required" -ForegroundColor Red
    } else {
        Write-Host "  ✓ No Component Based Servicing reboot pending" -ForegroundColor Green
    }
} catch {
    Write-Host "  ? Could not check Component Based Servicing status" -ForegroundColor Yellow
}

Write-Host "Checking pending file rename operations..." -ForegroundColor Green
try {
    $pendingFileRename = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Name "PendingFileRenameOperations" -ErrorAction SilentlyContinue
    if ($pendingFileRename) {
        $pendingReboot = $true
        $reasons += "Pending file rename operations require reboot"
        Write-Host "  ✗ Pending file rename operations found" -ForegroundColor Red
        Write-Host "    Files waiting to be renamed/deleted:" -ForegroundColor Yellow
        $pendingFileRename.PendingFileRenameOperations | ForEach-Object {
            Write-Host "    - $_" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  ✓ No pending file rename operations" -ForegroundColor Green
    }
} catch {
    Write-Host "  ? Could not check pending file rename operations" -ForegroundColor Yellow
}

Write-Host "Checking computer name changes..." -ForegroundColor Green
try {
    $computerName = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ActiveComputerName" -ErrorAction SilentlyContinue
    $pendingComputerName = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName" -ErrorAction SilentlyContinue
    if ($computerName -and $pendingComputerName -and $computerName.ComputerName -ne $pendingComputerName.ComputerName) {
        $pendingReboot = $true
        $reasons += "Computer name change requires reboot"
        Write-Host "  ✗ Computer name change pending" -ForegroundColor Red
        Write-Host "    Current: $($computerName.ComputerName)" -ForegroundColor Yellow
        Write-Host "    Pending: $($pendingComputerName.ComputerName)" -ForegroundColor Yellow
    } else {
        Write-Host "  ✓ No computer name changes pending" -ForegroundColor Green
    }
} catch {
    Write-Host "  ? Could not check computer name status" -ForegroundColor Yellow
}

Write-Host "Checking SCCM status..." -ForegroundColor Green
try {
    if (Get-Service -Name CcmExec -ErrorAction SilentlyContinue) {
        try {
            $sccmClient = New-Object -ComObject Microsoft.SMS.TSEnvironment -ErrorAction SilentlyContinue
            if ($sccmClient -and $sccmClient.Value("_SMSTSInWinPE") -ne "false") {
                $pendingReboot = $true
                $reasons += "SCCM requires reboot"
                Write-Host "  ✗ SCCM reboot required" -ForegroundColor Red
            } else {
                Write-Host "  ✓ SCCM does not require reboot" -ForegroundColor Green
            }
        } catch {
            Write-Host "  ✓ SCCM present but no reboot requirement detected" -ForegroundColor Green
        }
    } else {
        Write-Host "  ✓ SCCM not installed" -ForegroundColor Green
    }
} catch {
    Write-Host "  ? Could not check SCCM status" -ForegroundColor Yellow
}

# Check for additional MSI-related pending operations
Write-Host "Checking MSI installer status..." -ForegroundColor Green
try {
    $msiExecProcesses = Get-Process -Name "msiexec" -ErrorAction SilentlyContinue
    if ($msiExecProcesses) {
        Write-Host "  ! MSI Installer processes currently running:" -ForegroundColor Yellow
        $msiExecProcesses | ForEach-Object {
            Write-Host "    - PID: $($_.Id), Start Time: $($_.StartTime)" -ForegroundColor Yellow
        }
        Write-Host "    Wait for these to complete before running uninstaller" -ForegroundColor Yellow
    } else {
        Write-Host "  ✓ No MSI installer processes running" -ForegroundColor Green
    }
} catch {
    Write-Host "  ? Could not check MSI installer status" -ForegroundColor Yellow
}

# Check Windows Installer service
Write-Host "Checking Windows Installer service..." -ForegroundColor Green
try {
    $msiService = Get-Service -Name "msiserver" -ErrorAction SilentlyContinue
    if ($msiService) {
        Write-Host "  ✓ Windows Installer service status: $($msiService.Status)" -ForegroundColor Green
        if ($msiService.Status -ne 'Running' -and $msiService.Status -ne 'Stopped') {
            Write-Host "    ! Service in unusual state - may need restart" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  ✗ Windows Installer service not found" -ForegroundColor Red
    }
} catch {
    Write-Host "  ? Could not check Windows Installer service" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== SUMMARY ===" -ForegroundColor Cyan

if ($pendingReboot) {
    Write-Host "❌ PENDING REBOOT DETECTED!" -ForegroundColor Red
    Write-Host "Reasons found:" -ForegroundColor Red
    foreach ($reason in $reasons) {
        Write-Host "  • $reason" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "RECOMMENDATION:" -ForegroundColor Yellow
    Write-Host "• Reboot your system now" -ForegroundColor Yellow
    Write-Host "• Wait for the system to fully start" -ForegroundColor Yellow
    Write-Host "• Then run the Autodesk Uninstaller" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Running the uninstaller with pending reboots may cause:" -ForegroundColor Red
    Write-Host "• MSI errors (like 'MsiSystemRebootPending = 1')" -ForegroundColor Red
    Write-Host "• Incomplete uninstalls" -ForegroundColor Red
    Write-Host "• Registry corruption" -ForegroundColor Red
    Write-Host "• Failed reinstallations" -ForegroundColor Red
} else {
    Write-Host "✅ NO PENDING REBOOT DETECTED" -ForegroundColor Green
    Write-Host "Your system is ready for the Autodesk Uninstaller" -ForegroundColor Green
}

Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
