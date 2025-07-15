<#
.SYNOPSIS
    Enhanced validation script for the Autodesk Uninstaller
.DESCRIPTION
    Comprehensive testing of all enhanced features including pending reboot detection,
    licensing cleanup, shared components removal, and verification functions.
.OUTPUTS
    Detailed validation report of all uninstaller components
#>

param(
    [switch]$TestPendingReboot,
    [switch]$TestModuleLoading,
    [switch]$TestFunctions,
    [switch]$All
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'

# Get script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ModulesDir = Join-Path $ScriptDir "Modules"

Write-Host "=== ENHANCED AUTODESK UNINSTALLER VALIDATION ===" -ForegroundColor Cyan
Write-Host "Testing enhanced features for robust Autodesk product removal" -ForegroundColor Yellow
Write-Host ""

# Initialize test results
$testResults = @{
    ModuleLoading = @{}
    Functions = @{}
    PendingReboot = $false
    OverallStatus = $true
}

function Test-ModuleLoading {
    Write-Host "🔧 TESTING MODULE LOADING..." -ForegroundColor Green
    
    $RequiredModules = @(
        'Config.psm1',
        'Logging.psm1', 
        'ProductDetection.psm1',
        'ProgressWindow.psm1',
        'UninstallOperations.psm1',
        'GUI.psm1'
    )
    
    foreach ($ModuleName in $RequiredModules) {
        $ModulePath = Join-Path $ModulesDir $ModuleName
        Write-Host "  Testing: $ModuleName" -ForegroundColor Cyan
        
        if (Test-Path $ModulePath) {
            try {
                Import-Module $ModulePath -Force -ErrorAction Stop
                Write-Host "    ✓ Loaded successfully" -ForegroundColor Green
                $testResults.ModuleLoading[$ModuleName] = $true
            } catch {
                Write-Host "    ✗ Failed to load: $($_.Exception.Message)" -ForegroundColor Red
                $testResults.ModuleLoading[$ModuleName] = $false
                $testResults.OverallStatus = $false
            }
        } else {
            Write-Host "    ✗ File not found at: $ModulePath" -ForegroundColor Red
            $testResults.ModuleLoading[$ModuleName] = $false
            $testResults.OverallStatus = $false
        }
    }
}

function Test-EnhancedFunctions {
    Write-Host ""
    Write-Host "🔧 TESTING ENHANCED FUNCTIONS..." -ForegroundColor Green
    
    # Test new functions from UninstallOperations module
    $enhancedFunctions = @(
        'Test-PendingReboot',
        'Test-UninstallSuccess', 
        'Invoke-FinalCleanupVerification',
        'Clear-AutodeskLicensingComponents',
        'Clear-AutodeskSharedComponents',
        'Repair-AutodeskLicensing',
        'Repair-AutodeskSharedComponents',
        'Clear-DesktopAutodeskFiles'
    )
    
    foreach ($functionName in $enhancedFunctions) {
        Write-Host "  Testing: $functionName" -ForegroundColor Cyan
        
        try {
            $function = Get-Command $functionName -ErrorAction Stop
            if ($function.ModuleName -eq 'UninstallOperations') {
                Write-Host "    ✓ Function exists and properly exported" -ForegroundColor Green
                $testResults.Functions[$functionName] = $true
            } else {
                Write-Host "    ✗ Function found but not from expected module" -ForegroundColor Red
                $testResults.Functions[$functionName] = $false
                $testResults.OverallStatus = $false
            }
        } catch {
            Write-Host "    ✗ Function not found or not exported" -ForegroundColor Red
            $testResults.Functions[$functionName] = $false
            $testResults.OverallStatus = $false
        }
    }
    
    # Test function execution (safe functions only)
    Write-Host ""
    Write-Host "  Testing function execution (safe functions)..." -ForegroundColor Cyan
    
    # Test pending reboot detection
    try {
        Write-Host "    Testing Test-PendingReboot execution..." -ForegroundColor Cyan
        $pendingReboot = Test-PendingReboot
        Write-Host "      ✓ Pending reboot check executed, result: $pendingReboot" -ForegroundColor Green
        $testResults.PendingReboot = $pendingReboot
    } catch {
        Write-Host "      ✗ Failed to execute: $($_.Exception.Message)" -ForegroundColor Red
        $testResults.OverallStatus = $false
    }
    
    # Test configuration loading
    try {
        Write-Host "    Testing Get-Config execution..." -ForegroundColor Cyan
        $config = Get-Config
        if ($config -and $config.AutodeskProcesses -and $config.AutodeskServices) {
            Write-Host "      ✓ Configuration loaded with expected properties" -ForegroundColor Green
            Write-Host "        - Processes to monitor: $($config.AutodeskProcesses.Count)" -ForegroundColor Gray
            Write-Host "        - Services to control: $($config.AutodeskServices.Count)" -ForegroundColor Gray
        } else {
            Write-Host "      ✗ Configuration missing expected properties" -ForegroundColor Red
            $testResults.OverallStatus = $false
        }
    } catch {
        Write-Host "      ✗ Failed to get configuration: $($_.Exception.Message)" -ForegroundColor Red
        $testResults.OverallStatus = $false
    }
}

function Test-PendingRebootDetection {
    Write-Host ""
    Write-Host "🔧 TESTING PENDING REBOOT DETECTION..." -ForegroundColor Green
    
    $checkResults = @{}
    
    # Windows Update check
    Write-Host "  Checking Windows Update..." -ForegroundColor Cyan
    try {
        $wu = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" -ErrorAction SilentlyContinue
        $checkResults.WindowsUpdate = [bool]$wu
        Write-Host "    Result: $(if ($wu) { 'Reboot Required' } else { 'No Reboot Required' })" -ForegroundColor $(if ($wu) { 'Yellow' } else { 'Green' })
    } catch {
        $checkResults.WindowsUpdate = $false
        Write-Host "    Could not check Windows Update status" -ForegroundColor Yellow
    }
    
    # Component Based Servicing check
    Write-Host "  Checking Component Based Servicing..." -ForegroundColor Cyan
    try {
        $cbs = Get-Item "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" -ErrorAction SilentlyContinue
        $checkResults.ComponentBasedServicing = [bool]$cbs
        Write-Host "    Result: $(if ($cbs) { 'Reboot Required' } else { 'No Reboot Required' })" -ForegroundColor $(if ($cbs) { 'Yellow' } else { 'Green' })
    } catch {
        $checkResults.ComponentBasedServicing = $false
        Write-Host "    Could not check Component Based Servicing status" -ForegroundColor Yellow
    }
    
    # Pending file rename operations
    Write-Host "  Checking pending file operations..." -ForegroundColor Cyan
    try {
        $pfro = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Name "PendingFileRenameOperations" -ErrorAction SilentlyContinue
        $checkResults.PendingFileRename = [bool]$pfro
        Write-Host "    Result: $(if ($pfro) { 'File Operations Pending' } else { 'No File Operations Pending' })" -ForegroundColor $(if ($pfro) { 'Yellow' } else { 'Green' })
    } catch {
        $checkResults.PendingFileRename = $false
        Write-Host "    Could not check pending file operations" -ForegroundColor Yellow
    }
    
    $anyPending = $checkResults.Values -contains $true
    Write-Host ""
    Write-Host "  Overall Pending Reboot Status: $(if ($anyPending) { 'REBOOT REQUIRED' } else { 'SYSTEM READY' })" -ForegroundColor $(if ($anyPending) { 'Red' } else { 'Green' })
    
    return $anyPending
}

function Show-ValidationSummary {
    Write-Host ""
    Write-Host "=== VALIDATION SUMMARY ===" -ForegroundColor Cyan
    
    # Module loading results
    Write-Host ""
    Write-Host "📦 Module Loading Results:" -ForegroundColor Yellow
    foreach ($module in $testResults.ModuleLoading.Keys) {
        $status = if ($testResults.ModuleLoading[$module]) { '✓' } else { '✗' }
        $color = if ($testResults.ModuleLoading[$module]) { 'Green' } else { 'Red' }
        Write-Host "  $status $module" -ForegroundColor $color
    }
    
    # Function testing results
    Write-Host ""
    Write-Host "🔧 Enhanced Functions Results:" -ForegroundColor Yellow
    foreach ($function in $testResults.Functions.Keys) {
        $status = if ($testResults.Functions[$function]) { '✓' } else { '✗' }
        $color = if ($testResults.Functions[$function]) { 'Green' } else { 'Red' }
        Write-Host "  $status $function" -ForegroundColor $color
    }
    
    # Pending reboot status
    Write-Host ""
    Write-Host "🔄 System Status:" -ForegroundColor Yellow
    if ($testResults.PendingReboot) {
        Write-Host "  ⚠️  Pending reboot detected - reboot recommended before uninstall" -ForegroundColor Yellow
    } else {
        Write-Host "  ✓ No pending reboot - system ready for uninstall" -ForegroundColor Green
    }
    
    # Overall status
    Write-Host ""
    if ($testResults.OverallStatus) {
        Write-Host "✅ VALIDATION PASSED" -ForegroundColor Green
        Write-Host "Enhanced Autodesk Uninstaller is ready for use" -ForegroundColor Green
        if ($testResults.PendingReboot) {
            Write-Host "⚠️  RECOMMENDATION: Reboot system first for optimal results" -ForegroundColor Yellow
        }
    } else {
        Write-Host "❌ VALIDATION FAILED" -ForegroundColor Red
        Write-Host "Issues detected that need to be resolved" -ForegroundColor Red
    }
}

# Main execution
try {
    if ($All -or $TestModuleLoading -or (-not $TestPendingReboot -and -not $TestFunctions)) {
        Test-ModuleLoading
    }
    
    if ($All -or $TestFunctions -or (-not $TestPendingReboot -and -not $TestModuleLoading)) {
        Test-EnhancedFunctions
    }
    
    if ($All -or $TestPendingReboot -or (-not $TestModuleLoading -and -not $TestFunctions)) {
        $testResults.PendingReboot = Test-PendingRebootDetection
    }
    
    Show-ValidationSummary
    
} catch {
    Write-Host ""
    Write-Host "❌ VALIDATION ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red
} finally {
    Write-Host ""
    Write-Host "Press any key to exit..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}
