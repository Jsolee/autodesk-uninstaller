#!/usr/bin/env powershell
<#
.SYNOPSIS
    Test script to specifically test the Success property access issue
#>

Write-Host "Testing Success property access..." -ForegroundColor Cyan

# Import required modules
$ModulesDir = ".\Modules"
$RequiredModules = @('Config.psm1', 'Logging.psm1', 'GUI.psm1')

foreach ($ModuleName in $RequiredModules) {
    $ModulePath = Join-Path $ModulesDir $ModuleName
    if (Test-Path $ModulePath) {
        try {
            Import-Module -Name $ModulePath -Force -ErrorAction Stop
            Write-Host "✓ Imported: $ModuleName" -ForegroundColor Green
        } catch {
            Write-Host "✗ Failed to import $ModuleName : $_" -ForegroundColor Red
            exit 1
        }
    }
}
}

# Test the function that returns results
function Test-InvokeUninstallationProcess {
    Write-Host "Testing function return value..." -ForegroundColor Yellow
    
    # Simulate the return from Invoke-UninstallationProcess
    $results = [PSCustomObject]@{
        Success = 5
        Failed = 1
    }
    
    Write-Host "Created results object:" -ForegroundColor Cyan
    Write-Host "  Type: $($results.GetType().FullName)" -ForegroundColor White
    Write-Host "  Success: $($results.Success)" -ForegroundColor White
    Write-Host "  Failed: $($results.Failed)" -ForegroundColor White
    
    # Test accessing the properties like Main.ps1 does
    try {
        Write-Host "Testing property access..." -ForegroundColor Yellow
        Write-Host "Successful: $($results.Success)" -ForegroundColor Green
        Write-Host "Failed: $($results.Failed)" -ForegroundColor Green
        
        # Test calling Show-SummaryDialog (but don't actually show it)
        Write-Host "Testing function call parameters..." -ForegroundColor Yellow
        $successCount = $results.Success
        $failCount = $results.Failed
        Write-Host "SuccessCount parameter: $successCount" -ForegroundColor Green
        Write-Host "FailCount parameter: $failCount" -ForegroundColor Green
        
    } catch {
        Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Line: $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Red
        Write-Host "Command: $($_.InvocationInfo.Line.Trim())" -ForegroundColor Red
    }
}

# Test the object creation and property access
Test-InvokeUninstallationProcess

Write-Host "Test completed successfully!" -ForegroundColor Green
