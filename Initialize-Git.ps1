# Quick Git Setup Script
# This script initializes the git repository and prepares it for GitHub

Write-Host "Autodesk Uninstaller - Git Setup" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Green

# Check if git is available
try {
    $gitVersion = git --version
    Write-Host "Git found: $gitVersion" -ForegroundColor Green
} catch {
    Write-Host "Git not found. Please install Git from https://git-scm.com/" -ForegroundColor Red
    exit 1
}

# Check if already a git repository
if (Test-Path ".\.git") {
    Write-Host "Git repository already exists" -ForegroundColor Yellow
    $status = git status --porcelain
    if ($status) {
        Write-Host "Uncommitted changes found:" -ForegroundColor Yellow
        git status
    } else {
        Write-Host "Repository is clean" -ForegroundColor Green
    }
} else {
    Write-Host "Initializing git repository..." -ForegroundColor Yellow
    git init
    Write-Host "Git repository initialized" -ForegroundColor Green
}

# Add all files
Write-Host "Adding all files to git..." -ForegroundColor Yellow
git add .
Write-Host "Files added to staging area" -ForegroundColor Green

# Show status
Write-Host "Git status:" -ForegroundColor Cyan
git status

# Create initial commit
$commitMessage = "Initial commit: Modular Autodesk Uninstaller v1.0.0

Features:
- Modular architecture with 6 core modules
- GUI interface with Windows Forms
- Comprehensive product detection
- Backup functionality for user customizations
- Robust error handling and logging
- Test scripts for validation
- Complete documentation and contribution guidelines"

Write-Host "Creating initial commit..." -ForegroundColor Yellow
git commit -m $commitMessage
Write-Host "Initial commit created" -ForegroundColor Green

# Set default branch to main
Write-Host "Setting main branch..." -ForegroundColor Yellow
git branch -M main
Write-Host "Main branch set" -ForegroundColor Green

# Display next steps
Write-Host "`nGit setup complete!" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Create a new repository on GitHub" -ForegroundColor White
Write-Host "2. Run these commands to push to GitHub:" -ForegroundColor White
Write-Host "   git remote add origin https://github.com/yourusername/autodesk-uninstaller.git" -ForegroundColor Gray
Write-Host "   git push -u origin main" -ForegroundColor Gray
Write-Host "3. See GIT_SETUP.md for detailed instructions" -ForegroundColor White

# Display repository information
Write-Host "`nRepository Information:" -ForegroundColor Cyan
Write-Host "Branch: $(git branch --show-current)" -ForegroundColor White
Write-Host "Commits: $(git rev-list --count HEAD)" -ForegroundColor White
Write-Host "Files tracked: $(git ls-files | Measure-Object | Select-Object -ExpandProperty Count)" -ForegroundColor White
