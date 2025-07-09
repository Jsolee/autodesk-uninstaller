# Simple module test
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ModulesDir = Join-Path $ScriptDir "Modules"

Write-Host "Script Dir: $ScriptDir"
Write-Host "Modules Dir: $ModulesDir"

if (Test-Path $ModulesDir) {
    Write-Host "Modules directory exists" -ForegroundColor Green
    
    # Test Config module first
    $ConfigPath = Join-Path $ModulesDir "Config.psm1"
    if (Test-Path $ConfigPath) {
        Import-Module $ConfigPath -Force
        if (Get-Command "Get-Config" -ErrorAction SilentlyContinue) {
            Write-Host "Config module loaded successfully" -ForegroundColor Green
        } else {
            Write-Host "Config module failed to load functions" -ForegroundColor Red
        }
    } else {
        Write-Host "Config.psm1 not found" -ForegroundColor Red
    }
} else {
    Write-Host "Modules directory not found" -ForegroundColor Red
}
