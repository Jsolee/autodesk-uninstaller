# PowerShell Gallery Publication Script
# This script helps publish the module to PowerShell Gallery

param(
    [Parameter(Mandatory = $false)]
    [string]$NuGetApiKey,
    
    [Parameter(Mandatory = $false)]
    [switch]$WhatIf = $false
)

Write-Host "PowerShell Gallery Publication Script" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green

# Check if module manifest exists
$manifestPath = ".\AutodeskUninstaller.psd1"
if (-not (Test-Path $manifestPath)) {
    Write-Error "Module manifest not found at $manifestPath"
    exit 1
}

# Import and validate module manifest
Write-Host "Validating module manifest..." -ForegroundColor Yellow
try {
    $manifest = Test-ModuleManifest $manifestPath
    Write-Host "Module: $($manifest.Name)" -ForegroundColor White
    Write-Host "Version: $($manifest.Version)" -ForegroundColor White
    Write-Host "Author: $($manifest.Author)" -ForegroundColor White
    Write-Host "Description: $($manifest.Description)" -ForegroundColor White
} catch {
    Write-Error "Module manifest validation failed: $($_.Exception.Message)"
    exit 1
}

# Test module loading
Write-Host "Testing module loading..." -ForegroundColor Yellow
try {
    Import-Module $manifestPath -Force
    Write-Host "Module loaded successfully" -ForegroundColor Green
} catch {
    Write-Error "Module loading failed: $($_.Exception.Message)"
    exit 1
}

# Check PowerShell Gallery connection
Write-Host "Checking PowerShell Gallery connection..." -ForegroundColor Yellow
try {
    $gallery = Get-PSRepository -Name "PSGallery"
    if ($gallery.InstallationPolicy -ne "Trusted") {
        Write-Warning "PSGallery is not trusted. You may need to trust it:"
        Write-Host "Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted" -ForegroundColor Cyan
    }
} catch {
    Write-Error "Cannot connect to PowerShell Gallery"
    exit 1
}

# Check for API key
if (-not $NuGetApiKey) {
    Write-Host "PowerShell Gallery API Key not provided." -ForegroundColor Yellow
    Write-Host "To publish to PowerShell Gallery, you need an API key:" -ForegroundColor Cyan
    Write-Host "1. Go to https://www.powershellgallery.com/" -ForegroundColor White
    Write-Host "2. Sign in with your Microsoft account" -ForegroundColor White
    Write-Host "3. Go to Account → API Keys" -ForegroundColor White
    Write-Host "4. Create a new API key" -ForegroundColor White
    Write-Host "5. Run this script with -NuGetApiKey parameter" -ForegroundColor White
    
    $getKey = Read-Host "Do you want to enter the API key now? (y/n)"
    if ($getKey -eq 'y') {
        $NuGetApiKey = Read-Host "Enter your PowerShell Gallery API key" -AsSecureString
        $NuGetApiKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($NuGetApiKey))
    } else {
        Write-Host "Skipping publication. Use -NuGetApiKey parameter when ready." -ForegroundColor Yellow
        exit 0
    }
}

# Check if module already exists
Write-Host "Checking if module exists on PowerShell Gallery..." -ForegroundColor Yellow
try {
    $existingModule = Find-Module -Name $manifest.Name -ErrorAction SilentlyContinue
    if ($existingModule) {
        Write-Host "Module already exists on PowerShell Gallery:" -ForegroundColor Yellow
        Write-Host "Current version: $($existingModule.Version)" -ForegroundColor White
        Write-Host "New version: $($manifest.Version)" -ForegroundColor White
        
        if ($manifest.Version -le $existingModule.Version) {
            Write-Error "New version ($($manifest.Version)) must be greater than current version ($($existingModule.Version))"
            exit 1
        }
    } else {
        Write-Host "Module not found on PowerShell Gallery - this will be a new publication" -ForegroundColor Green
    }
} catch {
    Write-Warning "Could not check existing module: $($_.Exception.Message)"
}

# Prepare publication
Write-Host "Preparing for publication..." -ForegroundColor Yellow

# Create publication parameters
$publishParams = @{
    Path = "."
    NuGetApiKey = $NuGetApiKey
    Repository = "PSGallery"
    Verbose = $true
}

if ($WhatIf) {
    Write-Host "WhatIf mode - not actually publishing" -ForegroundColor Cyan
    Write-Host "Would publish with parameters:" -ForegroundColor Yellow
    $publishParams | Format-Table
    exit 0
}

# Final confirmation
Write-Host "`nReady to publish module to PowerShell Gallery!" -ForegroundColor Green
Write-Host "Module: $($manifest.Name)" -ForegroundColor White
Write-Host "Version: $($manifest.Version)" -ForegroundColor White
Write-Host "Repository: PSGallery" -ForegroundColor White

$confirm = Read-Host "Continue with publication? (y/n)"
if ($confirm -ne 'y') {
    Write-Host "Publication cancelled." -ForegroundColor Yellow
    exit 0
}

# Publish module
Write-Host "Publishing module to PowerShell Gallery..." -ForegroundColor Green
try {
    Publish-Module @publishParams
    Write-Host "Module published successfully!" -ForegroundColor Green
    Write-Host "It may take a few minutes to appear in search results." -ForegroundColor Yellow
} catch {
    Write-Error "Publication failed: $($_.Exception.Message)"
    exit 1
}

# Display success information
Write-Host "`nPublication completed successfully!" -ForegroundColor Green
Write-Host "Your module is now available on PowerShell Gallery:" -ForegroundColor Cyan
Write-Host "https://www.powershellgallery.com/packages/$($manifest.Name)" -ForegroundColor White
Write-Host "`nUsers can install it with:" -ForegroundColor Cyan
Write-Host "Install-Module -Name $($manifest.Name)" -ForegroundColor White
Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "1. Update project README with installation instructions" -ForegroundColor White
Write-Host "2. Create GitHub release with same version" -ForegroundColor White
Write-Host "3. Monitor download statistics and user feedback" -ForegroundColor White
Write-Host "4. Update CHANGELOG.md" -ForegroundColor White
