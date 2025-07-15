# Test script for simplified product detection
Write-Host "Testing simplified product detection..." -ForegroundColor Cyan

# Import required modules
$ModulesDir = ".\Modules"
$RequiredModules = @('Config.psm1', 'Logging.psm1', 'ProductDetection.psm1')

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

Write-Host "Testing product detection with grouping..." -ForegroundColor Yellow

try {
    $products = Get-AutodeskProducts
    
    Write-Host "✓ Product detection completed" -ForegroundColor Green
    Write-Host "  Found $($products.Count) main product groups" -ForegroundColor White
    
    foreach ($product in $products) {
        Write-Host "  - $($product.DisplayName)" -ForegroundColor White
        if ($product.ComponentCount) {
            Write-Host "    Components: $($product.ComponentCount)" -ForegroundColor Gray
            if ($product.Components) {
                $product.Components | ForEach-Object {
                    Write-Host "      + $($_.DisplayName)" -ForegroundColor DarkGray
                }
            }
        }
    }
    
} catch {
    Write-Host "✗ Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "  Line: $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Red
    Write-Host "  Stack: $($_.ScriptStackTrace)" -ForegroundColor Red
}

Write-Host "Test completed." -ForegroundColor Green
