# Test script to run Main.ps1 as admin and capture specific errors
Write-Host "Testing Main.ps1 execution with error trapping..." -ForegroundColor Cyan

try {
    # Set error action to continue so we capture all errors
    $ErrorActionPreference = 'Continue'
    
    # Run a mock version of the problematic section
    Write-Host "Testing Invoke-UninstallationProcess return..." -ForegroundColor Yellow
    
    # Simulate what happens in Main.ps1
    function Mock-InvokeUninstallationProcess {
        return [PSCustomObject]@{
            Success = 3
            Failed = 0
        }
    }
    
    # Test the exact code from Main.ps1
    $results = Mock-InvokeUninstallationProcess
    
    Write-Host "Results type: $($results.GetType().FullName)"
    Write-Host "Results has Success property: $($results.PSObject.Properties.Name -contains 'Success')"
    Write-Host "Results has Failed property: $($results.PSObject.Properties.Name -contains 'Failed')"
    
    # Test the exact lines that might be causing the error
    Write-Host "=== Testing exact Main.ps1 code ===" -ForegroundColor Yellow
    Write-Host "Successful: $($results.Success)"
    Write-Host "Failed: $($results.Failed)"
    
    # Test function parameter passing
    Write-Host "Testing parameter passing..." -ForegroundColor Yellow
    function Mock-ShowSummaryDialog {
        param(
            [int]$SuccessCount,
            [int]$FailCount
        )
        Write-Host "Mock-ShowSummaryDialog called with SuccessCount=$SuccessCount, FailCount=$FailCount"
        return $true
    }
    
    Mock-ShowSummaryDialog -SuccessCount $results.Success -FailCount $results.Failed
    
    Write-Host "All tests passed!" -ForegroundColor Green
    
} catch {
    Write-Host "CAUGHT ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "ERROR LINE: $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Red
    Write-Host "ERROR COMMAND: $($_.InvocationInfo.Line.Trim())" -ForegroundColor Red
    Write-Host "STACK TRACE: $($_.ScriptStackTrace)" -ForegroundColor Red
}
