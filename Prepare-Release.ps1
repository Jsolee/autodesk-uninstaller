# Release Preparation Script
# This script helps prepare the project for a new release

param(
    [Parameter(Mandatory = $true)]
    [string]$Version,
    
    [Parameter(Mandatory = $false)]
    [string]$ReleaseNotes = "See CHANGELOG.md for details"
)

Write-Host "Preparing release version $Version..." -ForegroundColor Green

# Update version in module manifest
$manifestPath = ".\AutodeskUninstaller.psd1"
if (Test-Path $manifestPath) {
    Write-Host "Updating module manifest version..." -ForegroundColor Yellow
    
    $manifest = Get-Content $manifestPath -Raw
    $manifest = $manifest -replace "ModuleVersion\s*=\s*'[\d\.]+'", "ModuleVersion = '$Version'"
    $manifest | Out-File $manifestPath -Encoding UTF8
    
    Write-Host "Module manifest updated to version $Version" -ForegroundColor Green
} else {
    Write-Warning "Module manifest not found at $manifestPath"
}

# Test modules before release
Write-Host "Testing modules..." -ForegroundColor Yellow
if (Test-Path ".\Test-Modules-Fixed.ps1") {
    try {
        & ".\Test-Modules-Fixed.ps1"
        Write-Host "Module tests passed!" -ForegroundColor Green
    } catch {
        Write-Error "Module tests failed! Please fix issues before releasing."
        exit 1
    }
} else {
    Write-Warning "Test script not found. Please run tests manually."
}

# Check for uncommitted changes
Write-Host "Checking for uncommitted changes..." -ForegroundColor Yellow
try {
    $gitStatus = git status --porcelain
    if ($gitStatus) {
        Write-Warning "There are uncommitted changes:"
        git status
        $commit = Read-Host "Do you want to commit these changes? (y/n)"
        if ($commit -eq 'y') {
            git add .
            git commit -m "Prepare release v$Version"
        }
    }
} catch {
    Write-Warning "Git not available or not in a git repository"
}

# Create release tag
Write-Host "Creating release tag..." -ForegroundColor Yellow
try {
    git tag -a "v$Version" -m "Release version $Version - $ReleaseNotes"
    Write-Host "Created tag v$Version" -ForegroundColor Green
} catch {
    Write-Warning "Failed to create git tag"
}

# Display next steps
Write-Host "`nRelease preparation complete!" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Push changes: git push origin main" -ForegroundColor White
Write-Host "2. Push tags: git push origin --tags" -ForegroundColor White
Write-Host "3. Create release on GitHub with tag v$Version" -ForegroundColor White
Write-Host "4. Update CHANGELOG.md with release date" -ForegroundColor White
Write-Host "5. Consider publishing to PowerShell Gallery" -ForegroundColor White

# Display current version info
Write-Host "`nVersion Information:" -ForegroundColor Cyan
Write-Host "Version: $Version" -ForegroundColor White
Write-Host "Release Notes: $ReleaseNotes" -ForegroundColor White
Write-Host "Tag: v$Version" -ForegroundColor White
