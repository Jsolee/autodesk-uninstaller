#!/usr/bin/env powershell
<#
.SYNOPSIS
    Test script to capture detailed errors from Main.ps1
#>

Write-Host "Testing Main.ps1 with detailed error capture..." -ForegroundColor Cyan

try {
    # Run Main.ps1 and capture all output
    $output = & powershell.exe -ExecutionPolicy Bypass -File ".\Main.ps1" -ErrorAction Continue 2>&1
    
    Write-Host "=== Output from Main.ps1 ===" -ForegroundColor Yellow
    $output | ForEach-Object {
        if ($_ -is [System.Management.Automation.ErrorRecord]) {
            Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "LINE: $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Red
            Write-Host "COMMAND: $($_.InvocationInfo.Line.Trim())" -ForegroundColor Red
            Write-Host "STACK: $($_.ScriptStackTrace)" -ForegroundColor DarkRed
            Write-Host "---" -ForegroundColor Red
        } else {
            Write-Host "$_" -ForegroundColor White
        }
    }
    
} catch {
    Write-Host "=== Caught Exception ===" -ForegroundColor Red
    Write-Host "Message: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Line: $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Red
    Write-Host "Command: $($_.InvocationInfo.Line)" -ForegroundColor Red
    Write-Host "Stack: $($_.ScriptStackTrace)" -ForegroundColor Red
}

Write-Host "Test completed." -ForegroundColor Green
