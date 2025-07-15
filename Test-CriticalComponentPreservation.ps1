<#
.SYNOPSIS
    Test script to verify critical component preservation in reinstall mode
.DESCRIPTION
    This script checks that critical Autodesk components like AdskIdentityManager
    are properly preserved during reinstall mode cleanup operations.
.OUTPUTS
    Reports on preservation status of critical components
#>

param(
    [switch]$TestPreservation,
    [switch]$CheckCurrentState,
    [switch]$All
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'

# Get script directory and import modules
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ModulesDir = Join-Path $ScriptDir "Modules"

Write-Host "=== CRITICAL COMPONENT PRESERVATION TEST ===" -ForegroundColor Cyan
Write-Host "Testing that AdskIdentityManager and other critical components are preserved in reinstall mode" -ForegroundColor Yellow
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

function Test-CriticalComponentsExist {
    Write-Host ""
    Write-Host "🔍 CHECKING CURRENT STATE OF CRITICAL COMPONENTS..." -ForegroundColor Green
    
    $config = Get-Config
    $criticalComponents = $config.CriticalSharedComponents
    
    $existingComponents = @{}
    
    foreach ($component in $criticalComponents) {
        $componentName = Split-Path $component -Leaf
        $exists = Test-Path $component
        $existingComponents[$componentName] = @{
            Path = $component
            Exists = $exists
        }
        
        $status = if ($exists) { "✓ EXISTS" } else { "✗ NOT FOUND" }
        $color = if ($exists) { "Green" } else { "Yellow" }
        Write-Host "  $status $componentName" -ForegroundColor $color
        Write-Host "    Path: $component" -ForegroundColor Gray
        
        if ($exists) {
            try {
                $items = Get-ChildItem $component -ErrorAction SilentlyContinue | Measure-Object
                Write-Host "    Contains: $($items.Count) items" -ForegroundColor Gray
            } catch {
                Write-Host "    Cannot enumerate contents" -ForegroundColor Gray
            }
        }
    }
    
    return $existingComponents
}

function Test-PreservationLogic {
    Write-Host ""
    Write-Host "🧪 TESTING PRESERVATION LOGIC..." -ForegroundColor Green
    
    # Initialize logging to capture function output
    try {
        Initialize-Logging
        Write-Host "✓ Logging initialized" -ForegroundColor Green
    } catch {
        Write-Host "⚠️  Could not initialize logging: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "Testing Clear-AutodeskLicensingComponents with PreserveLicensing = $true..." -ForegroundColor Cyan
    try {
        # This should preserve core licensing infrastructure
        Clear-AutodeskLicensingComponents -PreserveLicensing $true
        Write-Host "✓ Licensing cleanup completed in preservation mode" -ForegroundColor Green
    } catch {
        Write-Host "✗ Error in licensing preservation test: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "Testing Clear-AutodeskSharedComponents with PreserveComponents = $true..." -ForegroundColor Cyan
    try {
        # This should preserve critical shared components
        Clear-AutodeskSharedComponents -PreserveComponents $true
        Write-Host "✓ Shared components cleanup completed in preservation mode" -ForegroundColor Green
    } catch {
        Write-Host "✗ Error in shared components preservation test: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "Testing Clear-AutodeskSystemRemnants with PreserveComponents = $true..." -ForegroundColor Cyan
    try {
        # This should preserve critical components during system cleanup
        Clear-AutodeskSystemRemnants -PreserveComponents $true
        Write-Host "✓ System cleanup completed in preservation mode" -ForegroundColor Green
    } catch {
        Write-Host "✗ Error in system remnants preservation test: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Show-PreservationSummary {
    param($beforeState, $afterState)
    
    Write-Host ""
    Write-Host "=== PRESERVATION TEST SUMMARY ===" -ForegroundColor Cyan
    
    $preserved = 0
    $lost = 0
    $notPresent = 0
    
    foreach ($componentName in $beforeState.Keys) {
        $wasThere = $beforeState[$componentName].Exists
        $stillThere = $afterState[$componentName].Exists
        
        if (-not $wasThere) {
            Write-Host "  ⚪ $componentName - Not present initially" -ForegroundColor Gray
            $notPresent++
        } elseif ($wasThere -and $stillThere) {
            Write-Host "  ✅ $componentName - PRESERVED" -ForegroundColor Green
            $preserved++
        } elseif ($wasThere -and -not $stillThere) {
            Write-Host "  ❌ $componentName - LOST" -ForegroundColor Red
            $lost++
        }
    }
    
    Write-Host ""
    Write-Host "📊 Results:" -ForegroundColor Yellow
    Write-Host "  Components preserved: $preserved" -ForegroundColor Green
    Write-Host "  Components lost: $lost" -ForegroundColor $(if ($lost -eq 0) { 'Green' } else { 'Red' })
    Write-Host "  Not present initially: $notPresent" -ForegroundColor Gray
    
    if ($lost -eq 0 -and $preserved -gt 0) {
        Write-Host ""
        Write-Host "✅ PRESERVATION TEST PASSED" -ForegroundColor Green
        Write-Host "All existing critical components were preserved during reinstall mode cleanup" -ForegroundColor Green
    } elseif ($lost -gt 0) {
        Write-Host ""
        Write-Host "❌ PRESERVATION TEST FAILED" -ForegroundColor Red
        Write-Host "Some critical components were removed during reinstall mode cleanup" -ForegroundColor Red
    } else {
        Write-Host ""
        Write-Host "⚠️  PRESERVATION TEST INCONCLUSIVE" -ForegroundColor Yellow
        Write-Host "No critical components were present to test preservation" -ForegroundColor Yellow
    }
}

function Show-CriticalComponentsInfo {
    Write-Host ""
    Write-Host "ℹ️  ABOUT CRITICAL COMPONENTS..." -ForegroundColor Blue
    Write-Host ""
    Write-Host "AdskIdentityManager:" -ForegroundColor Yellow
    Write-Host "  • Handles Autodesk sign-in and licensing authentication" -ForegroundColor Gray
    Write-Host "  • Removing this breaks single sign-on functionality" -ForegroundColor Gray
    Write-Host "  • Should be preserved in reinstall scenarios" -ForegroundColor Gray
    Write-Host ""
    Write-Host "CLM (Component Licensing Manager):" -ForegroundColor Yellow
    Write-Host "  • Core licensing infrastructure" -ForegroundColor Gray
    Write-Host "  • Required for license validation" -ForegroundColor Gray
    Write-Host "  • Should be preserved to maintain licensing state" -ForegroundColor Gray
    Write-Host ""
    Write-Host "DLMFramework:" -ForegroundColor Yellow
    Write-Host "  • Desktop Licensing Manager framework" -ForegroundColor Gray
    Write-Host "  • Handles license activation and validation" -ForegroundColor Gray
    Write-Host "  • Critical for proper licensing function" -ForegroundColor Gray
    Write-Host ""
    Write-Host "AdLM (Autodesk License Manager):" -ForegroundColor Yellow
    Write-Host "  • Main licensing service components" -ForegroundColor Gray
    Write-Host "  • Manages license files and activation" -ForegroundColor Gray
    Write-Host "  • Essential for product licensing" -ForegroundColor Gray
}

# Main execution
try {
    if ($All -or $CheckCurrentState -or (-not $TestPreservation)) {
        $beforeState = Test-CriticalComponentsExist
        Show-CriticalComponentsInfo
    }
    
    if ($All -or $TestPreservation) {
        if (-not $beforeState) {
            $beforeState = Test-CriticalComponentsExist
        }
        
        Test-PreservationLogic
        
        Write-Host ""
        Write-Host "⏳ Waiting 2 seconds before checking preservation..." -ForegroundColor Yellow
        Start-Sleep -Seconds 2
        
        $afterState = Test-CriticalComponentsExist
        Show-PreservationSummary -beforeState $beforeState -afterState $afterState
    }
    
    Write-Host ""
    Write-Host "💡 RECOMMENDATIONS:" -ForegroundColor Blue
    Write-Host "• Use 'Reinstall preparation' mode to preserve critical components" -ForegroundColor Gray
    Write-Host "• Use 'Full uninstall' mode only when completely removing Autodesk" -ForegroundColor Gray
    Write-Host "• AdskIdentityManager is critical for licensing - preserve it for reinstalls" -ForegroundColor Gray
    Write-Host "• Test this script before running the uninstaller on production systems" -ForegroundColor Gray
    
} catch {
    Write-Host ""
    Write-Host "❌ TEST ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red
} finally {
    Write-Host ""
    Write-Host "Press any key to exit..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}
