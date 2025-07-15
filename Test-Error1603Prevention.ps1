<#
.SYNOPSIS
    Test script specifically for error 1603 prevention
.DESCRIPTION
    This script tests all the conditions that commonly cause MSI error 1603 during Autodesk installations.
    Run this before attempting to reinstall Autodesk products to identify potential issues.
.OUTPUTS
    Detailed report on installation readiness and error 1603 prevention
#>

param(
    [switch]$FixIssues,
    [switch]$CheckOnly,
    [switch]$Detailed
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'

# Get script directory and import modules
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ModulesDir = Join-Path $ScriptDir "Modules"

Write-Host "=== ERROR 1603 PREVENTION TEST ===" -ForegroundColor Cyan
Write-Host "Testing system conditions that cause MSI installation failures" -ForegroundColor Yellow
Write-Host ""

# Import required modules
try {
    Import-Module (Join-Path $ModulesDir "Config.psm1") -Force
    Import-Module (Join-Path $ModulesDir "Logging.psm1") -Force
    Import-Module (Join-Path $ModulesDir "UninstallOperations.psm1") -Force
    Write-Host "✓ Successfully imported required modules" -ForegroundColor Green
} catch {
    Write-Host "✗ Failed to import modules: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

function Test-Error1603Conditions {
    Write-Host ""
    Write-Host "🔍 TESTING ERROR 1603 CONDITIONS..." -ForegroundColor Green
    
    $issues = @()
    $warnings = @()
    
    # Test 1: Pending Reboot (Most common cause)
    Write-Host ""
    Write-Host "1. Checking for pending reboot..." -ForegroundColor Cyan
    try {
        $pendingReboot = Test-PendingReboot
        if ($pendingReboot) {
            $issues += "CRITICAL: System has pending reboot - this WILL cause error 1603"
            Write-Host "   ❌ PENDING REBOOT DETECTED" -ForegroundColor Red
            Write-Host "   This is the #1 cause of error 1603" -ForegroundColor Red
        } else {
            Write-Host "   ✅ No pending reboot" -ForegroundColor Green
        }
    } catch {
        $warnings += "Could not check pending reboot status"
        Write-Host "   ⚠️  Could not check pending reboot" -ForegroundColor Yellow
    }
    
    # Test 2: Windows Installer Service
    Write-Host ""
    Write-Host "2. Checking Windows Installer service..." -ForegroundColor Cyan
    try {
        $msiService = Get-Service -Name "msiserver" -ErrorAction SilentlyContinue
        if ($msiService) {
            Write-Host "   Status: $($msiService.Status)" -ForegroundColor Gray
            if ($msiService.Status -eq 'Running') {
                Write-Host "   ✅ Windows Installer service is running" -ForegroundColor Green
            } elseif ($msiService.Status -eq 'Stopped') {
                Write-Host "   ✅ Windows Installer service is stopped (normal)" -ForegroundColor Green
            } else {
                $issues += "Windows Installer service in abnormal state: $($msiService.Status)"
                Write-Host "   ❌ Service in abnormal state" -ForegroundColor Red
            }
        } else {
            $issues += "Windows Installer service not found"
            Write-Host "   ❌ Windows Installer service not found" -ForegroundColor Red
        }
    } catch {
        $warnings += "Could not check Windows Installer service"
        Write-Host "   ⚠️  Could not check service status" -ForegroundColor Yellow
    }
    
    # Test 3: Running MSI Processes
    Write-Host ""
    Write-Host "3. Checking for running MSI processes..." -ForegroundColor Cyan
    try {
        $msiProcesses = Get-Process -Name "msiexec" -ErrorAction SilentlyContinue
        if ($msiProcesses) {
            $issues += "MSI installer processes currently running - will cause error 1603"
            Write-Host "   ❌ Found $($msiProcesses.Count) MSI processes running" -ForegroundColor Red
            foreach ($process in $msiProcesses) {
                Write-Host "     PID: $($process.Id), Start: $($process.StartTime)" -ForegroundColor Red
            }
        } else {
            Write-Host "   ✅ No MSI processes running" -ForegroundColor Green
        }
    } catch {
        $warnings += "Could not check MSI processes"
        Write-Host "   ⚠️  Could not check MSI processes" -ForegroundColor Yellow
    }
    
    # Test 4: Disk Space
    Write-Host ""
    Write-Host "4. Checking disk space..." -ForegroundColor Cyan
    try {
        $drives = @('C:', $env:TEMP.Substring(0,2))
        foreach ($drive in ($drives | Select-Object -Unique)) {
            $disk = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='$drive'" -ErrorAction SilentlyContinue
            if ($disk) {
                $freeGB = [math]::Round($disk.FreeSpace / 1GB, 1)
                $totalGB = [math]::Round($disk.Size / 1GB, 1)
                
                Write-Host "   Drive $drive`: $freeGB GB free of $totalGB GB" -ForegroundColor Gray
                
                if ($freeGB -lt 5) {
                    $issues += "Low disk space on $drive (${freeGB}GB) - may cause error 1603"
                    Write-Host "   ❌ Low disk space on $drive" -ForegroundColor Red
                } elseif ($freeGB -lt 10) {
                    $warnings += "Limited disk space on $drive (${freeGB}GB)"
                    Write-Host "   ⚠️  Limited disk space on $drive" -ForegroundColor Yellow
                } else {
                    Write-Host "   ✅ Sufficient space on $drive" -ForegroundColor Green
                }
            }
        }
    } catch {
        $warnings += "Could not check disk space"
        Write-Host "   ⚠️  Could not check disk space" -ForegroundColor Yellow
    }
    
    # Test 5: Administrator Privileges
    Write-Host ""
    Write-Host "5. Checking administrator privileges..." -ForegroundColor Cyan
    try {
        $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal $currentUser
        if ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            Write-Host "   ✅ Running as Administrator" -ForegroundColor Green
        } else {
            $issues += "Not running as Administrator - will cause error 1603"
            Write-Host "   ❌ Not running as Administrator" -ForegroundColor Red
        }
    } catch {
        $warnings += "Could not check administrator privileges"
        Write-Host "   ⚠️  Could not check privileges" -ForegroundColor Yellow
    }
    
    # Test 6: Registry Permissions
    Write-Host ""
    Write-Host "6. Checking registry permissions..." -ForegroundColor Cyan
    try {
        $testPaths = @(
            'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer',
            'HKLM:\SOFTWARE\Classes\Installer'
        )
        
        $regIssues = 0
        foreach ($testPath in $testPaths) {
            try {
                $null = New-Item -Path "$testPath\__TEST__" -Force -ErrorAction Stop
                Remove-Item -Path "$testPath\__TEST__" -Force -ErrorAction SilentlyContinue
                Write-Host "   ✅ $testPath - OK" -ForegroundColor Green
            } catch {
                $regIssues++
                Write-Host "   ❌ $testPath - Permission denied" -ForegroundColor Red
            }
        }
        
        if ($regIssues -gt 0) {
            $issues += "Registry permission problems - may cause error 1603"
        }
    } catch {
        $warnings += "Could not check registry permissions"
        Write-Host "   ⚠️  Could not check registry permissions" -ForegroundColor Yellow
    }
    
    # Test 7: Corrupted Installer Cache
    Write-Host ""
    Write-Host "7. Checking for corrupted installer cache..." -ForegroundColor Cyan
    try {
        $installerCache = "$env:WINDIR\Installer"
        if (Test-Path $installerCache) {
            $autodeskCache = Get-ChildItem $installerCache -Filter "*autodesk*" -ErrorAction SilentlyContinue
            $adlmCache = Get-ChildItem $installerCache -Filter "*adlm*" -ErrorAction SilentlyContinue
            
            $totalCache = $autodeskCache.Count + $adlmCache.Count
            
            if ($totalCache -gt 0) {
                $warnings += "Found $totalCache Autodesk files in installer cache"
                Write-Host "   ⚠️  Found $totalCache Autodesk cache files" -ForegroundColor Yellow
            } else {
                Write-Host "   ✅ No Autodesk installer cache files" -ForegroundColor Green
            }
        } else {
            Write-Host "   ✅ No installer cache directory" -ForegroundColor Green
        }
    } catch {
        $warnings += "Could not check installer cache"
        Write-Host "   ⚠️  Could not check installer cache" -ForegroundColor Yellow
    }
    
    # Test 8: Conflicting Processes
    Write-Host ""
    Write-Host "8. Checking for conflicting Autodesk processes..." -ForegroundColor Cyan
    try {
        $config = Get-Config
        $runningProcesses = @()
        
        foreach ($processName in $config.AutodeskProcesses) {
            $processes = Get-Process -Name $processName -ErrorAction SilentlyContinue
            if ($processes) {
                $runningProcesses += $processes
                Write-Host "   ❌ Found running process: $processName" -ForegroundColor Red
            }
        }
        
        if ($runningProcesses.Count -gt 0) {
            $issues += "Autodesk processes still running - will cause error 1603"
        } else {
            Write-Host "   ✅ No conflicting Autodesk processes" -ForegroundColor Green
        }
    } catch {
        $warnings += "Could not check Autodesk processes"
        Write-Host "   ⚠️  Could not check processes" -ForegroundColor Yellow
    }
    
    return @{
        Issues = $issues
        Warnings = $warnings
    }
}

function Show-Error1603Summary {
    param($testResults)
    
    Write-Host ""
    Write-Host "=== ERROR 1603 PREVENTION SUMMARY ===" -ForegroundColor Cyan
    
    $criticalIssues = $testResults.Issues.Count
    $warnings = $testResults.Warnings.Count
    
    if ($criticalIssues -eq 0 -and $warnings -eq 0) {
        Write-Host ""
        Write-Host "✅ EXCELLENT - NO ISSUES DETECTED" -ForegroundColor Green
        Write-Host "Your system is ready for Autodesk installation" -ForegroundColor Green
        Write-Host "Error 1603 is very unlikely to occur" -ForegroundColor Green
        
    } elseif ($criticalIssues -eq 0) {
        Write-Host ""
        Write-Host "⚠️  GOOD - MINOR WARNINGS ONLY" -ForegroundColor Yellow
        Write-Host "Installation should succeed but monitor for issues" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Warnings found:" -ForegroundColor Yellow
        foreach ($warning in $testResults.Warnings) {
            Write-Host "  • $warning" -ForegroundColor Yellow
        }
        
    } else {
        Write-Host ""
        Write-Host "❌ CRITICAL ISSUES DETECTED" -ForegroundColor Red
        Write-Host "Installation will likely fail with error 1603" -ForegroundColor Red
        Write-Host ""
        Write-Host "Critical issues:" -ForegroundColor Red
        foreach ($issue in $testResults.Issues) {
            Write-Host "  • $issue" -ForegroundColor Red
        }
        
        if ($warnings -gt 0) {
            Write-Host ""
            Write-Host "Additional warnings:" -ForegroundColor Yellow
            foreach ($warning in $testResults.Warnings) {
                Write-Host "  • $warning" -ForegroundColor Yellow
            }
        }
    }
    
    Write-Host ""
    Write-Host "💡 RECOMMENDATIONS:" -ForegroundColor Blue
    
    if ($criticalIssues -eq 0) {
        Write-Host "• You can proceed with Autodesk installation" -ForegroundColor Gray
        Write-Host "• Install as Administrator" -ForegroundColor Gray
        Write-Host "• Ensure stable internet connection" -ForegroundColor Gray
        Write-Host "• Temporarily disable antivirus during installation" -ForegroundColor Gray
    } else {
        Write-Host "• DO NOT attempt installation until issues are resolved" -ForegroundColor Gray
        Write-Host "• Address critical issues first (especially pending reboot)" -ForegroundColor Gray
        Write-Host "• Run the enhanced uninstaller if not already done" -ForegroundColor Gray
        Write-Host "• Reboot system and test again" -ForegroundColor Gray
    }
}

# Main execution
try {
    if ($CheckOnly -or (-not $FixIssues)) {
        $testResults = Test-Error1603Conditions
        Show-Error1603Summary -testResults $testResults
        
        if ($Detailed) {
            Write-Host ""
            Write-Host "ℹ️  ABOUT ERROR 1603:" -ForegroundColor Blue
            Write-Host "Error 1603 is a fatal MSI installation error meaning:" -ForegroundColor Gray
            Write-Host "• A fatal error occurred during installation" -ForegroundColor Gray
            Write-Host "• Most commonly caused by pending system reboot" -ForegroundColor Gray
            Write-Host "• Can be caused by insufficient permissions" -ForegroundColor Gray
            Write-Host "• Registry corruption or locked files" -ForegroundColor Gray
            Write-Host "• Conflicting processes or services" -ForegroundColor Gray
        }
    }
    
    if ($FixIssues) {
        Write-Host ""
        Write-Host "🔧 ATTEMPTING TO FIX ERROR 1603 ISSUES..." -ForegroundColor Green
        
        # Initialize logging
        try {
            Initialize-Logging
            Write-Host "✓ Logging initialized" -ForegroundColor Green
        } catch {
            Write-Host "⚠️  Could not initialize logging" -ForegroundColor Yellow
        }
        
        # Fix Windows Installer issues
        Write-Host ""
        Write-Host "Fixing Windows Installer issues..." -ForegroundColor Cyan
        Fix-WindowsInstallerIssues
        
        # Clear installation rollback files
        Write-Host ""
        Write-Host "Clearing installation rollback files..." -ForegroundColor Cyan
        Clear-InstallationRollbackFiles
        
        # Fix registry permissions
        Write-Host ""
        Write-Host "Fixing registry permissions..." -ForegroundColor Cyan
        Fix-RegistryPermissions
        
        Write-Host ""
        Write-Host "✅ FIXES COMPLETED" -ForegroundColor Green
        Write-Host "Run this script again with -CheckOnly to verify fixes" -ForegroundColor Green
    }
    
} catch {
    Write-Host ""
    Write-Host "❌ ERROR: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    Write-Host ""
    Write-Host "Press any key to exit..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}
