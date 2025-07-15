# Test script to simulate Main.ps1 execution flow
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Get the script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ModulesDir = Join-Path $ScriptDir "Modules"

Write-Host "Testing Main.ps1 execution flow..." -ForegroundColor Cyan

try {
    # Import all required modules
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
        Import-Module -Name $ModulePath -Force -ErrorAction Stop
        Write-Host "Successfully imported: $ModuleName" -ForegroundColor Green
    }

    # Initialize logging (should work now)
    Write-Host "Initializing logging..." -ForegroundColor Yellow
    Initialize-Logging
    Write-Host "Logging initialized successfully" -ForegroundColor Green

    # Test product detection with array conversion
    Write-Host "Testing product detection..." -ForegroundColor Yellow
    $products = @(Get-AutodeskProducts)
    Write-Host "Found $($products.Count) Autodesk products" -ForegroundColor Green

    # Test other functions that might use Count
    Write-Host "Testing configuration..." -ForegroundColor Yellow
    $config = Get-Config
    Write-Host "Configuration loaded successfully" -ForegroundColor Green

    Write-Host "All tests passed! Main.ps1 should work now." -ForegroundColor Cyan

} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Full error: $_" -ForegroundColor Red
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red
    exit 1
}
