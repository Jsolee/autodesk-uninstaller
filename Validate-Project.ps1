# Project Validation Script
# This script validates the entire project is ready for GitHub collaboration

Write-Host "Autodesk Uninstaller Project Validation" -ForegroundColor Green
Write-Host "=======================================" -ForegroundColor Green

$ErrorCount = 0
$WarningCount = 0

function Test-FileExists {
    param([string]$Path, [string]$Description)
    if (Test-Path $Path) {
        Write-Host "✓ $Description found" -ForegroundColor Green
    } else {
        Write-Host "✗ $Description missing: $Path" -ForegroundColor Red
        $script:ErrorCount++
    }
}

function Test-ModuleFile {
    param([string]$Path, [string]$ModuleName)
    if (Test-Path $Path) {
        Write-Host "✓ Module $ModuleName found" -ForegroundColor Green
        
        # Check for Export-ModuleMember
        $content = Get-Content $Path -Raw
        if ($content -match 'Export-ModuleMember') {
            Write-Host "  ✓ Export-ModuleMember found" -ForegroundColor Green
        } else {
            Write-Host "  ⚠ Export-ModuleMember not found" -ForegroundColor Yellow
            $script:WarningCount++
        }
    } else {
        Write-Host "✗ Module $ModuleName missing: $Path" -ForegroundColor Red
        $script:ErrorCount++
    }
}

# Test required files
Write-Host "`nTesting Required Files:" -ForegroundColor Cyan
Test-FileExists ".\Main.ps1" "Main entry point"
Test-FileExists ".\README.md" "README file"
Test-FileExists ".\LICENSE" "License file"
Test-FileExists ".\CONTRIBUTING.md" "Contributing guidelines"
Test-FileExists ".\CHANGELOG.md" "Changelog"
Test-FileExists ".\.gitignore" "Git ignore file"
Test-FileExists ".\AutodeskUninstaller.psd1" "Module manifest"
Test-FileExists ".\AutodeskUninstaller.psm1" "Main module file"

# Test module files
Write-Host "`nTesting Module Files:" -ForegroundColor Cyan
Test-ModuleFile ".\Modules\Config.psm1" "Config"
Test-ModuleFile ".\Modules\Logging.psm1" "Logging"
Test-ModuleFile ".\Modules\ProductDetection.psm1" "ProductDetection"
Test-ModuleFile ".\Modules\GUI.psm1" "GUI"
Test-ModuleFile ".\Modules\ProgressWindow.psm1" "ProgressWindow"
Test-ModuleFile ".\Modules\UninstallOperations.psm1" "UninstallOperations"

# Test scripts
Write-Host "`nTesting Test Scripts:" -ForegroundColor Cyan
Test-FileExists ".\Test-Modules-Fixed.ps1" "Module test script"
Test-FileExists ".\SimpleTest.ps1" "Simple test script"

# Test utility scripts
Write-Host "`nTesting Utility Scripts:" -ForegroundColor Cyan
Test-FileExists ".\Prepare-Release.ps1" "Release preparation script"
Test-FileExists ".\Publish-Module.ps1" "Module publication script"
Test-FileExists ".\GIT_SETUP.md" "Git setup instructions"

# Test module manifest
Write-Host "`nTesting Module Manifest:" -ForegroundColor Cyan
try {
    $manifest = Test-ModuleManifest ".\AutodeskUninstaller.psd1"
    Write-Host "✓ Module manifest is valid" -ForegroundColor Green
    Write-Host "  Name: $($manifest.Name)" -ForegroundColor White
    Write-Host "  Version: $($manifest.Version)" -ForegroundColor White
    Write-Host "  Author: $($manifest.Author)" -ForegroundColor White
    Write-Host "  Description: $($manifest.Description)" -ForegroundColor White
} catch {
    Write-Host "✗ Module manifest validation failed: $($_.Exception.Message)" -ForegroundColor Red
    $ErrorCount++
}

# Test module loading
Write-Host "`nTesting Module Loading:" -ForegroundColor Cyan
try {
    if (Test-Path ".\Test-Modules-Fixed.ps1") {
        Write-Host "Running module test script..." -ForegroundColor Yellow
        $testOutput = & ".\Test-Modules-Fixed.ps1" 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Module tests passed" -ForegroundColor Green
        } else {
            Write-Host "✗ Module tests failed" -ForegroundColor Red
            Write-Host $testOutput -ForegroundColor Gray
            $ErrorCount++
        }
    } else {
        Write-Host "⚠ Module test script not found" -ForegroundColor Yellow
        $WarningCount++
    }
} catch {
    Write-Host "✗ Module testing failed: $($_.Exception.Message)" -ForegroundColor Red
    $ErrorCount++
}

# Test README content
Write-Host "`nTesting README Content:" -ForegroundColor Cyan
if (Test-Path ".\README.md") {
    $readme = Get-Content ".\README.md" -Raw
    
    $requiredSections = @(
        "# Autodesk Uninstaller",
        "## Features",
        "## Installation",
        "## Usage",
        "## Architecture",
        "## Contributing"
    )
    
    foreach ($section in $requiredSections) {
        if ($readme -match [regex]::Escape($section)) {
            Write-Host "✓ README section found: $section" -ForegroundColor Green
        } else {
            Write-Host "⚠ README section missing: $section" -ForegroundColor Yellow
            $WarningCount++
        }
    }
}

# Test for sensitive information
Write-Host "`nTesting for Sensitive Information:" -ForegroundColor Cyan
$sensitivePatterns = @(
    @{ Pattern = "password\s*="; Description = "Hardcoded passwords" },
    @{ Pattern = "api[_-]?key\s*="; Description = "API keys" },
    @{ Pattern = "secret\s*="; Description = "Secrets" },
    @{ Pattern = "C:\\Users\\[^\\]+\\"; Description = "Hardcoded user paths" }
)

$allFiles = Get-ChildItem -Path "." -Recurse -File | Where-Object { $_.Extension -match '\.(ps1|psm1|psd1|md)$' }
$sensitiveFound = $false

foreach ($file in $allFiles) {
    $content = Get-Content $file.FullName -Raw
    foreach ($pattern in $sensitivePatterns) {
        if ($content -match $pattern.Pattern) {
            Write-Host "⚠ Potential sensitive information in $($file.Name): $($pattern.Description)" -ForegroundColor Yellow
            $WarningCount++
            $sensitiveFound = $true
        }
    }
}

if (-not $sensitiveFound) {
    Write-Host "✓ No obvious sensitive information found" -ForegroundColor Green
}

# Test git readiness
Write-Host "`nTesting Git Readiness:" -ForegroundColor Cyan
try {
    if (Test-Path ".\.git") {
        Write-Host "✓ Git repository initialized" -ForegroundColor Green
        
        # Check for uncommitted changes
        $gitStatus = git status --porcelain
        if ($gitStatus) {
            Write-Host "⚠ Uncommitted changes found:" -ForegroundColor Yellow
            $gitStatus | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
            $WarningCount++
        } else {
            Write-Host "✓ No uncommitted changes" -ForegroundColor Green
        }
        
        # Check for remote
        $remotes = git remote -v
        if ($remotes) {
            Write-Host "✓ Git remotes configured" -ForegroundColor Green
        } else {
            Write-Host "⚠ No git remotes configured" -ForegroundColor Yellow
            $WarningCount++
        }
    } else {
        Write-Host "⚠ Git repository not initialized" -ForegroundColor Yellow
        Write-Host "  Run 'git init' to initialize repository" -ForegroundColor Gray
        $WarningCount++
    }
} catch {
    Write-Host "⚠ Git not available" -ForegroundColor Yellow
    $WarningCount++
}

# Test PowerShell version compatibility
Write-Host "`nTesting PowerShell Compatibility:" -ForegroundColor Cyan
Write-Host "Current PowerShell version: $($PSVersionTable.PSVersion)" -ForegroundColor White
if ($PSVersionTable.PSVersion.Major -ge 5) {
    Write-Host "✓ PowerShell version compatible" -ForegroundColor Green
} else {
    Write-Host "⚠ PowerShell version may not be compatible" -ForegroundColor Yellow
    $WarningCount++
}

# Summary
Write-Host "`nValidation Summary:" -ForegroundColor Cyan
Write-Host "=================" -ForegroundColor Cyan
Write-Host "Errors: $ErrorCount" -ForegroundColor $(if ($ErrorCount -eq 0) { "Green" } else { "Red" })
Write-Host "Warnings: $WarningCount" -ForegroundColor $(if ($WarningCount -eq 0) { "Green" } else { "Yellow" })

if ($ErrorCount -eq 0) {
    Write-Host "`n✅ Project is ready for GitHub collaboration!" -ForegroundColor Green
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. Initialize git repository (if not done): git init" -ForegroundColor White
    Write-Host "2. Add all files: git add ." -ForegroundColor White
    Write-Host "3. Create initial commit: git commit -m 'Initial commit'" -ForegroundColor White
    Write-Host "4. Create GitHub repository and push" -ForegroundColor White
    Write-Host "5. See GIT_SETUP.md for detailed instructions" -ForegroundColor White
} else {
    Write-Host "`n❌ Project has errors that need to be fixed before GitHub collaboration" -ForegroundColor Red
    Write-Host "Please fix the errors above and run validation again" -ForegroundColor Yellow
}

if ($WarningCount -gt 0) {
    Write-Host "`n⚠️  There are warnings that should be addressed:" -ForegroundColor Yellow
    Write-Host "While not blocking, these warnings should be reviewed and fixed if possible" -ForegroundColor Gray
}

# Return appropriate exit code
if ($ErrorCount -eq 0) {
    exit 0
} else {
    exit 1
}
