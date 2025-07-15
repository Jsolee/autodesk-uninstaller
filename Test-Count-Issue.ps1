# Test script to identify Count property issues
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Get the script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ModulesDir = Join-Path $ScriptDir "Modules"

# Import required modules
Import-Module "$ModulesDir\Config.psm1" -Force
Import-Module "$ModulesDir\Logging.psm1" -Force
Import-Module "$ModulesDir\ProductDetection.psm1" -Force
Import-Module "$ModulesDir\UninstallOperations.psm1" -Force

try {
    Write-Host "Testing Count property issues..." -ForegroundColor Cyan
    
    # Test 1: Product detection
    Write-Host "Test 1: Product detection" -ForegroundColor Yellow
    $products = @(Get-AutodeskProducts)
    Write-Host "Products found: $($products.Count)" -ForegroundColor Green
    
    # Test 2: Empty selected products (this is likely where the error occurs)
    Write-Host "Test 2: Testing with no selected products" -ForegroundColor Yellow
    # Don't set any selected products - this should cause Get-SelectedProducts to return null
    
    try {
        $selectedProducts = Get-SelectedProducts
        if ($selectedProducts) {
            Write-Host "Selected products count: $($selectedProducts.Count)" -ForegroundColor Green
        } else {
            Write-Host "No selected products (null)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Error in Get-SelectedProducts: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Test 3: Clear-ProductSpecificLicensing with null products (this likely causes the error)
    Write-Host "Test 3: Testing Clear-ProductSpecificLicensing with null products" -ForegroundColor Yellow
    try {
        Clear-ProductSpecificLicensing
        Write-Host "Clear-ProductSpecificLicensing completed successfully" -ForegroundColor Green
    } catch {
        Write-Host "Error in Clear-ProductSpecificLicensing: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Full error: $_" -ForegroundColor Red
    }
    
    # Test 4: Test array Count property access
    Write-Host "Test 4: Testing array Count property access" -ForegroundColor Yellow
    $emptyArray = @()
    $nullVar = $null
    
    Write-Host "Empty array count: $($emptyArray.Count)" -ForegroundColor Green
    
    try {
        Write-Host "Null variable count: $($nullVar.Count)" -ForegroundColor Green
    } catch {
        Write-Host "Error accessing Count on null: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host "All tests completed!" -ForegroundColor Cyan
    
} catch {
    Write-Host "Fatal error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Full error: $_" -ForegroundColor Red
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red
    exit 1
}
