# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial modular architecture release
- Comprehensive module structure with proper separation of concerns
- GUI module with Windows Forms interface
- Product detection module with registry scanning
- Uninstall operations module with backup functionality
- Progress window module for operation tracking
- Logging module with comprehensive logging capabilities
- Configuration module with centralized settings
- Test scripts for module validation
- Complete documentation and contribution guidelines

### Changed
- Refactored monolithic script into modular architecture
- Improved error handling and logging throughout
- Enhanced user interface with better progress tracking
- Optimized product detection algorithms

### Fixed
- Module import dependencies and circular reference issues
- PowerShell function visibility across modules
- Error handling in module loading and testing

## [1.0.0] - 2024-01-XX

### Added
- Initial release of modular Autodesk Uninstaller
- Support for Revit, AutoCAD, 3ds Max, and Desktop Connector
- GUI interface with product selection
- Backup functionality for add-ins and customizations
- Comprehensive logging system
- Registry cleanup operations
- Process and service management
- File system cleanup with preservation of user customizations

### Features
- **Modular Architecture**: Clean separation of concerns across multiple modules
- **GUI Interface**: User-friendly Windows Forms interface
- **Product Detection**: Automatic detection of installed Autodesk products
- **Backup System**: Preservation of user customizations and add-ins
- **Logging**: Comprehensive logging with timestamps and action tracking
- **Progress Tracking**: Real-time progress updates during operations
- **Error Handling**: Robust error handling and recovery mechanisms
- **Testing**: Comprehensive test suite for module validation

### Technical Details
- **PowerShell Version**: Compatible with PowerShell 5.1 and PowerShell Core 6.0+
- **Windows Compatibility**: Windows 10 and Windows 11 support
- **Architecture**: Modular design with 6 core modules
- **Testing**: Automated test scripts for module validation
- **Documentation**: Complete README, contributing guidelines, and inline documentation
