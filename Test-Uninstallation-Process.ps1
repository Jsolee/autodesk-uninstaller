# Test script to simulate the Invoke-UninstallationProcess function
Write-Host "Testing Invoke-UninstallationProcess function..." -ForegroundColor Cyan

# Import required modules
$ModulesDir = ".\Modules"
$RequiredModules = @('Config.psm1', 'Logging.psm1', 'ProductDetection.psm1', 'ProgressWindow.psm1', 'UninstallOperations.psm1', 'GUI.psm1')

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

# Initialize logging
Initialize-Logging

# Set up test data to simulate selected products
Set-SelectedProducts -products @()
Set-UninstallMode -mode "Complete"

Write-Host "Testing Invoke-UninstallationProcess with no products..." -ForegroundColor Yellow

try {
    $results = Invoke-UninstallationProcess
    
    Write-Host "✓ Function completed successfully" -ForegroundColor Green
    Write-Host "  Results type: $($results.GetType().FullName)" -ForegroundColor White
    Write-Host "  Success property exists: $($results.PSObject.Properties.Name -contains 'Success')" -ForegroundColor White
    Write-Host "  Failed property exists: $($results.PSObject.Properties.Name -contains 'Failed')" -ForegroundColor White
    Write-Host "  Success value: $($results.Success)" -ForegroundColor White
    Write-Host "  Failed value: $($results.Failed)" -ForegroundColor White
    
} catch {
    Write-Host "✗ Error occurred: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "  Line: $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Red
    Write-Host "  Command: $($_.InvocationInfo.Line.Trim())" -ForegroundColor Red
    Write-Host "  Stack: $($_.ScriptStackTrace)" -ForegroundColor Red
}

Write-Host "Test completed." -ForegroundColor Green
