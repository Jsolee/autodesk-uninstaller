# Simple test for the Success property issue
Write-Host "Testing Success property..." -ForegroundColor Cyan

try {
    # Import Main.ps1 functions
    . ".\Main.ps1" 2>$null
    Write-Host "Main.ps1 sourced successfully" -ForegroundColor Green
} catch {
    Write-Host "Error sourcing Main.ps1: $_" -ForegroundColor Red
}

Write-Host "Test completed." -ForegroundColor Green
