# Test script to check Success property access
Write-Host "Testing Success property access..." -ForegroundColor Cyan

# Test the function that returns results
function Test-Results {
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
        
        # Test calling function parameters
        Write-Host "Testing function call parameters..." -ForegroundColor Yellow
        $successCount = $results.Success
        $failCount = $results.Failed
        Write-Host "SuccessCount parameter: $successCount" -ForegroundColor Green
        Write-Host "FailCount parameter: $failCount" -ForegroundColor Green
        
    } catch {
        Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Line: $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Red
        Write-Host "Command: $($_.InvocationInfo.Line.Trim())" -ForegroundColor Red
        return $false
    }
    
    return $true
}

# Run the test
$testResult = Test-Results

if ($testResult) {
    Write-Host "Test completed successfully!" -ForegroundColor Green
} else {
    Write-Host "Test failed!" -ForegroundColor Red
}
