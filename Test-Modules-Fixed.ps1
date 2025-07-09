# Test script to verify module loading
# Run this to test if all modules load correctly

Write-Host "Testing Autodesk Uninstaller module loading..." -ForegroundColor Cyan

# Get the script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ModulesDir = Join-Path $ScriptDir "Modules"

Write-Host "Script Directory: $ScriptDir" -ForegroundColor Yellow
Write-Host "Modules Directory: $ModulesDir" -ForegroundColor Yellow

# Check if modules directory exists
if (-not (Test-Path $ModulesDir)) {
    Write-Error "FAIL: Modules directory not found at: $ModulesDir"
    exit 1
} else {
    Write-Host "OK: Modules directory found" -ForegroundColor Green
}

# List all .psm1 files in modules directory
$ModuleFiles = Get-ChildItem -Path $ModulesDir -Filter "*.psm1" -ErrorAction SilentlyContinue
Write-Host "Found $($ModuleFiles.Count) module files:" -ForegroundColor Yellow
foreach ($file in $ModuleFiles) {
    Write-Host "  - $($file.Name)" -ForegroundColor White
}

# Test importing each module
$RequiredModules = @(
    'Config.psm1',
    'Logging.psm1', 
    'ProductDetection.psm1',
    'ProgressWindow.psm1',
    'UninstallOperations.psm1',
    'GUI.psm1'
)

Write-Host "`nTesting module imports..." -ForegroundColor Cyan

foreach ($ModuleName in $RequiredModules) {
    $ModulePath = Join-Path $ModulesDir $ModuleName
    Write-Host "Testing: $ModuleName" -ForegroundColor Yellow
    
    if (Test-Path $ModulePath) {
        try {
            Import-Module -Name $ModulePath -Force -ErrorAction Stop
            Write-Host "  OK: Successfully imported $ModuleName" -ForegroundColor Green
        } catch {
            Write-Host "  ERROR: Failed to import $ModuleName : $_" -ForegroundColor Red
        }
    } else {
        Write-Host "  ERROR: Module not found at $ModulePath" -ForegroundColor Red
    }
}

# Test if critical functions are available
Write-Host "`nTesting critical functions..." -ForegroundColor Cyan
$CriticalFunctions = @(
    'Get-Config',
    'Initialize-Logging',
    'Get-AutodeskProducts',
    'Show-ProductSelectionGUI',
    'Show-ProgressWindow',
    'Stop-AutodeskServices'
)

foreach ($FunctionName in $CriticalFunctions) {
    if (Get-Command $FunctionName -ErrorAction SilentlyContinue) {
        Write-Host "  OK: Function $FunctionName is available" -ForegroundColor Green
    } else {
        Write-Host "  ERROR: Function $FunctionName NOT FOUND" -ForegroundColor Red
    }
}

Write-Host "`nModule loading test complete!" -ForegroundColor Cyan
Write-Host "If all tests passed, you can run Main.ps1" -ForegroundColor White
