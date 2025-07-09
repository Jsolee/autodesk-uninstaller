# Git Setup Script for Autodesk Uninstaller

This script will help you set up Git and prepare your repository for GitHub.

## Prerequisites

1. Install Git for Windows from https://git-scm.com/download/win
2. Create a GitHub account at https://github.com
3. Have your project ready in the current directory

## Step 1: Initialize Git Repository

```powershell
# Navigate to your project directory
cd "c:\Users\joans\OneDrive - Bjarke Ingels Group\Desktop\AutodeskUninstaller"

# Initialize git repository
git init

# Add all files to staging
git add .

# Create initial commit
git commit -m "Initial commit: Modular Autodesk Uninstaller v1.0.0"
```

## Step 2: Configure Git (First Time Only)

```powershell
# Set your name and email (replace with your actual information)
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Optional: Set default branch name to main
git config --global init.defaultBranch main
```

## Step 3: Create GitHub Repository

1. Go to https://github.com
2. Click "New repository" or the "+" icon
3. Name your repository (e.g., "autodesk-uninstaller")
4. Add a description: "Modular PowerShell tool for uninstalling Autodesk products with backup functionality"
5. Choose Public or Private
6. **Don't** initialize with README, .gitignore, or license (we already have these)
7. Click "Create repository"

## Step 4: Connect Local Repository to GitHub

```powershell
# Add remote origin (replace with your actual repository URL)
git remote add origin https://github.com/yourusername/autodesk-uninstaller.git

# Rename current branch to main (if not already)
git branch -M main

# Push to GitHub
git push -u origin main
```

## Step 5: Verify Setup

```powershell
# Check remote configuration
git remote -v

# Check repository status
git status

# View commit history
git log --oneline
```

## Alternative: Using GitHub Desktop

1. Download GitHub Desktop from https://desktop.github.com/
2. Install and sign in with your GitHub account
3. Click "Add an Existing Repository from your Hard Drive"
4. Select your project folder
5. Click "Publish repository" to create it on GitHub

## Development Workflow

### Making Changes

```powershell
# Create a new branch for your feature
git checkout -b feature/new-feature-name

# Make your changes...

# Stage changes
git add .

# Commit changes
git commit -m "Add new feature: description of changes"

# Push branch to GitHub
git push origin feature/new-feature-name
```

### Creating Pull Requests

1. Go to your repository on GitHub
2. Click "Compare & pull request" for your branch
3. Fill out the pull request template
4. Click "Create pull request"

### Merging Changes

```powershell
# Switch to main branch
git checkout main

# Pull latest changes
git pull origin main

# Merge your feature branch
git merge feature/new-feature-name

# Push updated main branch
git push origin main

# Delete feature branch (optional)
git branch -d feature/new-feature-name
git push origin --delete feature/new-feature-name
```

## Useful Git Commands

```powershell
# View current status
git status

# View changes
git diff

# View commit history
git log --oneline

# Undo last commit (keep changes)
git reset --soft HEAD~1

# Undo last commit (discard changes)
git reset --hard HEAD~1

# Create and switch to new branch
git checkout -b branch-name

# Switch branches
git checkout branch-name

# List all branches
git branch -a

# Pull latest changes from remote
git pull

# Push changes to remote
git push

# Clone repository
git clone https://github.com/username/repository.git
```

## Troubleshooting

### Authentication Issues

If you encounter authentication issues:

1. **Personal Access Token**: GitHub requires personal access tokens for HTTPS authentication
   - Go to GitHub Settings → Developer settings → Personal access tokens
   - Generate a new token with appropriate permissions
   - Use the token as your password when prompted

2. **SSH Authentication**: Set up SSH keys for easier authentication
   ```powershell
   # Generate SSH key
   ssh-keygen -t ed25519 -C "your.email@example.com"
   
   # Add to GitHub: Settings → SSH and GPG keys → New SSH key
   ```

### Large File Issues

If you have large files (>100MB):
```powershell
# Install Git LFS
git lfs install

# Track large files
git lfs track "*.zip"
git lfs track "*.exe"

# Add .gitattributes to repository
git add .gitattributes
git commit -m "Add Git LFS tracking"
```

### Line Ending Issues

For Windows development:
```powershell
git config --global core.autocrlf true
```

## Security Considerations

1. **Never commit sensitive information**:
   - Passwords
   - API keys
   - Personal information
   - System paths with usernames

2. **Use .gitignore** to exclude:
   - Log files
   - Temporary files
   - Build artifacts
   - IDE configuration files

3. **Review changes before committing**:
   ```powershell
   git diff --cached
   ```

## Next Steps

1. Set up branch protection rules on GitHub
2. Configure automated testing (GitHub Actions)
3. Set up issue and pull request templates
4. Enable GitHub Pages for documentation
5. Configure automated releases

## Resources

- [Git Documentation](https://git-scm.com/doc)
- [GitHub Docs](https://docs.github.com/)
- [GitHub Flow](https://guides.github.com/introduction/flow/)
- [Conventional Commits](https://www.conventionalcommits.org/)

Happy coding!
