# Simple test for product detection
Write-Host "Testing simplified product detection..." -ForegroundColor Cyan

try {
    # Import modules directly
    Import-Module ".\Modules\Config.psm1" -Force
    Import-Module ".\Modules\Logging.psm1" -Force
    Import-Module ".\Modules\ProductDetection.psm1" -Force
    
    Write-Host "Modules imported successfully" -ForegroundColor Green
    
    # Initialize logging
    Initialize-Logging
    
    # Test product detection
    $products = Get-AutodeskProducts
    
    Write-Host "Found $($products.Count) main product groups:" -ForegroundColor Green
    
    foreach ($product in $products) {
        Write-Host "  - $($product.DisplayName)" -ForegroundColor White
        if ($product.ComponentCount) {
            Write-Host "    ($($product.ComponentCount) components)" -ForegroundColor Gray
        }
    }
    
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "Test completed." -ForegroundColor Green
