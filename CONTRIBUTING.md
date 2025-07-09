# Contributing to Autodesk Uninstaller

Thank you for your interest in contributing to the Autodesk Uninstaller project! This document provides guidelines for contributing to the project.

## Code of Conduct

Please be respectful and professional in all interactions. We welcome contributions from everyone, regardless of experience level.

## Getting Started

1. Fork the repository
2. Clone your fork to your local machine
3. Create a new branch for your feature or bug fix
4. Make your changes
5. Test your changes thoroughly
6. Submit a pull request

## Development Setup

### Prerequisites

- Windows PowerShell 5.1 or PowerShell Core 6.0+
- Administrative privileges (required for uninstalling software)
- Git for version control

### Local Development

1. Clone the repository:
   ```powershell
   git clone https://github.com/yourusername/autodesk-uninstaller.git
   cd autodesk-uninstaller
   ```

2. Test the modules:
   ```powershell
   .\Test-Modules-Fixed.ps1
   ```

3. Run the main script:
   ```powershell
   .\Main.ps1
   ```

## Project Structure

```
AutodeskUninstaller/
├── Main.ps1                    # Main entry point
├── AutodeskUninstaller.psm1    # Module wrapper
├── AutodeskUninstaller.psd1    # Module manifest
├── Modules/                    # Core modules
│   ├── Config.psm1            # Configuration and global variables
│   ├── Logging.psm1           # Logging functionality
│   ├── ProductDetection.psm1  # Product detection logic
│   ├── GUI.psm1               # GUI components
│   ├── ProgressWindow.psm1    # Progress bar functionality
│   └── UninstallOperations.psm1 # Uninstall operations
├── Test-Modules-Fixed.ps1     # Module testing script
├── SimpleTest.ps1             # Basic import testing
├── README.md                  # Project documentation
├── LICENSE                    # License file
├── CONTRIBUTING.md            # This file
└── .gitignore                 # Git ignore rules
```

## Coding Standards

### PowerShell Style Guide

1. **Function Naming**: Use approved PowerShell verbs (Get-, Set-, New-, Remove-, etc.)
2. **Parameter Naming**: Use PascalCase for parameters
3. **Variable Naming**: Use camelCase for variables
4. **Indentation**: Use 4 spaces, not tabs
5. **Comments**: Use inline comments for complex logic
6. **Error Handling**: Use try-catch blocks and Write-Error for error handling

### Example Function Structure

```powershell
function Get-AutodeskProduct {
    <#
    .SYNOPSIS
        Brief description of the function
    .DESCRIPTION
        Detailed description of what the function does
    .PARAMETER ProductName
        Description of the parameter
    .EXAMPLE
        Get-AutodeskProduct -ProductName "AutoCAD"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProductName
    )
    
    try {
        # Function logic here
        Write-Verbose "Processing product: $ProductName"
        # Return result
    }
    catch {
        Write-Error "Failed to get product: $($_.Exception.Message)"
        throw
    }
}
```

## Module Development Guidelines

### Adding New Modules

1. Create the module file in the `Modules/` directory
2. Follow the existing module structure
3. Export only public functions using `Export-ModuleMember -Function @('Function1', 'Function2')`
4. Add proper documentation and examples
5. Update the main module manifest if needed

### Modifying Existing Modules

1. Ensure backward compatibility
2. Update documentation and examples
3. Add/update unit tests
4. Test with the provided test scripts

## Testing

### Running Tests

```powershell
# Test all modules
.\Test-Modules-Fixed.ps1

# Simple import test
.\SimpleTest.ps1

# Run main application
.\Main.ps1
```

### Writing Tests

When adding new functionality:

1. Add test cases to the existing test scripts
2. Ensure your code handles edge cases
3. Test with different Autodesk product configurations
4. Verify error handling works correctly

## Pull Request Process

1. **Create a Branch**: Create a feature branch from `main`
2. **Make Changes**: Implement your changes following the coding standards
3. **Test Thoroughly**: Run all tests and verify functionality
4. **Document Changes**: Update README.md and inline documentation
5. **Submit PR**: Create a pull request with a clear description

### Pull Request Template

```markdown
## Description
Brief description of changes made

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Performance improvement
- [ ] Code refactoring

## Testing
- [ ] Ran Test-Modules-Fixed.ps1 successfully
- [ ] Tested with real Autodesk products
- [ ] Verified error handling

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] No breaking changes (or clearly documented)
```

## Reporting Issues

When reporting bugs or requesting features:

1. Use the GitHub issue tracker
2. Provide clear reproduction steps
3. Include system information (PowerShell version, Windows version)
4. Include relevant log files or error messages
5. Search existing issues before creating new ones

## Documentation

### Code Documentation

- Use PowerShell comment-based help for all functions
- Include examples in function documentation
- Document any complex algorithms or business logic
- Keep README.md updated with new features

### README Updates

When adding new features:
- Update the feature list
- Add new usage examples
- Update installation instructions if needed
- Document any new dependencies

## Security Considerations

- Never commit sensitive information (passwords, keys, etc.)
- Be careful with file paths and user input validation
- Test privilege escalation scenarios
- Consider impact on system security

## Performance Guidelines

- Minimize external command calls
- Use PowerShell native cmdlets when possible
- Implement proper error handling to prevent hanging
- Consider memory usage for large product lists

## Release Process

1. Version updates follow semantic versioning (MAJOR.MINOR.PATCH)
2. Update version in `AutodeskUninstaller.psd1`
3. Update CHANGELOG.md with new features and fixes
4. Test thoroughly before release
5. Tag releases in Git

## Getting Help

- Check existing issues and documentation first
- Ask questions in GitHub discussions
- Provide context and examples when asking for help
- Be patient and respectful

## License

By contributing to this project, you agree that your contributions will be licensed under the MIT License.

Thank you for contributing to the Autodesk Uninstaller project!
