<div align="center">
  <img src="icon.png" alt="Autodesk Uninstaller Icon" width="128" height="128">
  
  # Enhanced Autodesk Uninstaller
  
  [![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue.svg)](https://docs.microsoft.com/en-us/powershell/)
  [![Platform](https://img.shields.io/badge/platform-Windows-lightgrey.svg)](https://www.microsoft.com/en-us/windows)
  [![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
  [![Status](https://img.shields.io/badge/status-Enhanced-brightgreen.svg)]()
  
  **A powerful, optimized PowerShell-based GUI application for uninstalling Autodesk products with simplified selection and critical component preservation.**
  
  🎯 **Simplified UX** • 🛡️ **License Protection** • ⚡ **Optimized Performance** • 🔧 **Error Prevention**
</div>

## 🚀 What's New in Enhanced Version

### Major Enhancements

- **🎯 Simplified Product Selection**: Instead of overwhelming component lists, select main products like "Revit 2025" or "AutoCAD 2024"
- **🛡️ Critical Component Preservation**: Automatically protects licensing components (AdskIdentityManager, CLM, DLMFramework) to prevent license errors
- **⚡ Optimized Performance**: Smart dependency ordering, parallel processing, and reduced command popup windows
- **🔧 Error Prevention**: Enhanced PowerShell 5.1 compatibility, pending reboot detection, and MSI error prevention
- **📊 Product Grouping**: Main products display with component counts for better organization

### Key Features

- **Modern GUI Interface**: Clean, simplified interface showing main products instead of individual components
- **Smart Uninstall Modes**: 
  - **Reinstall Preparation** (Recommended): Preserves licensing and shared components
  - **Full Uninstall**: Complete removal when permanently removing Autodesk
- **Critical Component Protection**: Prevents removal of AdskIdentityManager, Generative Design, and Personal Accelerator
- **Enhanced Error Handling**: PowerShell 5.1 compatibility fixes and comprehensive error prevention
- **Optimized Performance**: High process priority, smart cleanup order, and minimal UI interruptions
- **Comprehensive Logging**: Detailed operation tracking with advanced debugging capabilities

## 🏗️ Enhanced Architecture

The application is built with a modular, optimized architecture designed for reliability and performance:

### Core Modules

- **Config.psm1**: Enhanced configuration with critical component protection lists
- **Logging.psm1**: Advanced logging with debug capabilities and action tracking
- **ProductDetection.psm1**: **🆕 Intelligent product grouping** - Groups components under main products (e.g., "Revit 2025" with 8 components)
- **GUI.psm1**: **🆕 Simplified interface** - Shows main products with component counts instead of overwhelming lists
- **ProgressWindow.psm1**: Enhanced progress tracking with detailed status updates
- **UninstallOperations.psm1**: **🆕 Critical component filtering** - Automatically preserves licensing components

### Entry Points

- **Main.ps1**: **🆕 Optimized orchestration** - Enhanced with performance optimizations and error prevention
- **AutodeskUninstaller_GUI_Enhanced.ps1**: Legacy entry point for compatibility

### 🆕 Enhanced Components

- **Test-CriticalComponentPreservation.ps1**: Validates protection of licensing components
- **Test-Error1603Prevention.ps1**: Prevents common MSI installation errors
- **Test-PendingReboot.ps1**: Detects system reboot requirements
- **Validate-Enhanced-Project.ps1**: Comprehensive project validation
- **CRITICAL_COMPONENT_PRESERVATION.md**: Detailed documentation of licensing protection
- **ENHANCED_USER_GUIDE.md**: Complete guide for the enhanced features

## 📁 Enhanced File Structure

```
AutodeskUninstaller/
├── Main.ps1                                    # 🆕 Optimized main entry point
├── AutodeskUninstaller.psd1                    # Module manifest
├── AutodeskUninstaller.psm1                    # Module entry point
├── AutodeskUninstaller_GUI_Enhanced.ps1        # Legacy entry point
├── icon.png                                    # Project icon
├── README.md                                   # This enhanced documentation
├── ENHANCED_USER_GUIDE.md                      # 🆕 Complete user guide
├── CRITICAL_COMPONENT_PRESERVATION.md          # 🆕 Licensing protection details
├── GITHUB_READINESS.md                         # 🆕 Project setup documentation
├── CHANGELOG.md                                # 🆕 Version history
├── CONTRIBUTING.md                             # 🆕 Contribution guidelines
└── Modules/
    ├── Config.psm1                             # 🆕 Enhanced configuration
    ├── Logging.psm1                            # 🆕 Advanced logging
    ├── ProductDetection.psm1                   # 🆕 Intelligent product grouping
    ├── GUI.psm1                                # 🆕 Simplified interface
    ├── ProgressWindow.psm1                     # Enhanced progress display
    └── UninstallOperations.psm1                # 🆕 Critical component protection
└── Testing/
    ├── Test-CriticalComponentPreservation.ps1  # 🆕 Licensing protection tests
    ├── Test-Error1603Prevention.ps1            # 🆕 MSI error prevention
    ├── Test-PendingReboot.ps1                  # 🆕 Reboot detection
    ├── Test-Main-Flow.ps1                      # 🆕 Main workflow testing
    ├── Validate-Enhanced-Project.ps1           # 🆕 Project validation
    └── [Additional test files...]               # 🆕 Comprehensive test suite
```

## 🚀 Quick Start

### Prerequisites Check

Before running the enhanced uninstaller, check your system:

```powershell
# Check for pending reboot (prevents MSI errors)
.\Test-PendingReboot.ps1

# Validate all enhancements are working
.\Validate-Enhanced-Project.ps1 -All

# Check for MSI error conditions
.\Test-Error1603Prevention.ps1 -CheckOnly
```

### Running the Enhanced Uninstaller

1. **Run as Administrator** (Required for system modifications)
2. **Choose your preferred method**:

#### Method 1: Optimized Main Script (Recommended)
```powershell
powershell.exe -ExecutionPolicy Bypass -File .\Main.ps1
```

#### Method 2: Enhanced GUI Version
```powershell
powershell.exe -ExecutionPolicy Bypass -File .\AutodeskUninstaller_GUI_Enhanced.ps1
```

### 🎯 Enhanced User Experience

#### Simplified Product Selection
- ✅ **Before**: Overwhelming list of 50+ individual components
- ✅ **Now**: Clean list of main products (e.g., "Revit 2025 (8 components)")

#### Smart Uninstall Modes

**🔄 Reinstall Preparation Mode** (Recommended)
- **Use when**: Planning to reinstall or upgrade Autodesk products
- **Preserves**: 
  - ✅ AdskIdentityManager (critical for licensing)
  - ✅ Core licensing infrastructure (CLM, DLMFramework, AdLM)
  - ✅ Generative Design for Revit
  - ✅ Personal Accelerator for Revit
  - ✅ User add-ins and settings
- **Result**: No license errors during reinstallation

**🗑️ Full Uninstall Mode** (Use with caution)
- **Use when**: Permanently removing all Autodesk software
- **Removes**: Everything including licensing components
- **Warning**: Will require complete license setup after reinstall

### 🎯 Enhanced Product Support

The enhanced uninstaller now intelligently groups products for simplified selection:

#### Main Product Groups
- **Revit 2025** (8 components) - Architecture, MEP, Structural tools
- **Revit 2024** (6 components) - Previous version components
- **AutoCAD 2025** (5 components) - CAD application and tools
- **AutoCAD 2024** (4 components) - Previous version
- **Desktop Connector** (3 components) - Cloud connectivity tools
- **3ds Max 2025** (7 components) - 3D modeling and animation
- **Maya 2025** (6 components) - Animation and VFX tools
- **Inventor 2025** (5 components) - Mechanical design tools
- **Civil 3D 2025** (4 components) - Civil engineering tools
- **Navisworks** (3 components) - Project review tools

#### 🛡️ Protected Components (Always Preserved in Reinstall Mode)
- **AdskIdentityManager** - Critical for licensing
- **Generative Design for Revit** - Advanced design tools
- **Personal Accelerator for Revit** - Performance optimization
- **CLM/DLMFramework/AdLM** - Core licensing infrastructure

#### Example Product Selection
```
✅ Revit 2025 (8 components)
    ├── Autodesk Revit 2025
    ├── Revit Content Libraries
    ├── Structural Analysis Toolkit
    └── [5 more components...]

✅ AutoCAD 2024 (4 components)
    ├── AutoCAD 2024
    ├── AutoCAD Raster Design
    └── [2 more components...]

🛡️ Protected: AdskIdentityManager (Preserved for licensing)
```

## 📊 Enhanced Logging & Monitoring

The enhanced uninstaller provides comprehensive logging and monitoring:

### Log Locations
- **Action Log**: `C:\Temp\AutodeskUninstaller\action_log_YYYYMMDD_HHMMSS.txt`
- **Debug Log**: Detailed operation tracking with component-level information
- **MSI Logs**: Individual uninstaller logs for each component
- **Validation Logs**: Pre/post uninstall system state verification

### 🆕 Enhanced Logging Features
- **Component Grouping Tracking**: Logs how products are grouped and selected
- **Critical Component Protection**: Detailed logs of what was preserved vs removed
- **Performance Metrics**: Timing information for optimization analysis
- **Error Prevention**: Logs of potential issues detected and resolved
- **PowerShell Compatibility**: Special logging for PowerShell 5.1 specific handling

### Sample Enhanced Log Output
```
2025-07-15 14:13:57 - === Enhanced Autodesk Uninstaller Started ===
2025-07-15 14:13:57 - PowerShell Version: 5.1.19041.4648
2025-07-15 14:13:58 - Found 6 main product groups from 23 individual products
2025-07-15 14:13:59 - Selected products: 2 main groups (14 total components)
2025-07-15 14:14:00 - Mode: Reinstall Preparation (Critical components will be preserved)
2025-07-15 14:14:01 - Protected components: AdskIdentityManager, CLM, DLMFramework
2025-07-15 14:14:15 - Uninstallation completed: 12 successful, 0 failed
2025-07-15 14:14:16 - Critical components preserved: 3/3 ✅
```

## ⚙️ Enhanced Configuration & Customization

### 🆕 Critical Component Protection

The enhanced configuration includes specialized protection lists:

```powershell
# Critical components preserved in reinstall mode
$CriticalSharedComponents = @(
    'AdskIdentityManager',      # Critical for licensing
    'CLM',                      # Component Licensing Manager  
    'DLMFramework',             # Desktop Licensing Manager
    'AdLM',                     # Autodesk License Manager
    'Generative Design',        # Advanced design tools
    'Personal Accelerator'      # Performance optimization
)
```

### 🆕 Product Grouping Configuration

Products are automatically grouped by the enhanced detection system:

```powershell
# Example of how products are grouped
$MainProducts = @{
    'Revit 2025' = @{
        Components = @('Revit 2025', 'Revit Content', 'Structural Analysis', ...)
        ComponentCount = 8
        ProductType = 'Revit'
    }
    'AutoCAD 2024' = @{
        Components = @('AutoCAD 2024', 'Raster Design', ...)
        ComponentCount = 4
        ProductType = 'AutoCAD'
    }
}
```

### Enhanced Customization Options

#### Adding New Product Groups
1. Update `Get-MainProductName` function in `ProductDetection.psm1`
2. Add grouping logic for new product patterns
3. Configure protection rules if needed

#### Modifying Critical Component Protection
1. Edit `$CriticalSharedComponents` array in `Config.psm1`
2. Update protection logic in `UninstallOperations.psm1`
3. Test with `Test-CriticalComponentPreservation.ps1`

## 🔧 Enhanced Error Handling & Prevention

### 🆕 Proactive Error Prevention

The enhanced uninstaller includes multiple layers of error prevention:

#### PowerShell 5.1 Compatibility Fixes
- **Array Handling**: Fixed "Count property cannot be found" errors
- **Parameter Sets**: Resolved "Parameter set cannot be resolved" issues  
- **Object Pipeline**: Fixed PowerShell array wrapping issues
- **Property Access**: Enhanced property validation and access

#### MSI Error Prevention
- **Pending Reboot Detection**: Prevents "MsiSystemRebootPending = 1" errors
- **Process Conflict Detection**: Identifies blocking processes before uninstall
- **Registry Lock Detection**: Checks for registry access issues
- **System File Validation**: Runs SFC/DISM checks when needed

#### Smart Dependency Handling
- **Uninstall Order Optimization**: Removes add-ins before main products
- **Component Dependency Mapping**: Respects Autodesk internal dependencies
- **Critical Component Protection**: Prevents breaking licensing infrastructure

### Enhanced Error Messages

#### Before Enhancement
```
Error: Cannot bind parameter 'Products'. Parameter set cannot be resolved.
```

#### After Enhancement  
```
🔍 Enhanced Error Detection:
• Detected PowerShell 5.1 compatibility issue
• Applied array conversion fix
• Successfully processed 14 products
• ✅ Operation completed successfully
```

### 🛡️ Safety Features

- **Validation Before Action**: Pre-flight checks prevent destructive operations
- **Rollback Capability**: Critical component restoration if issues detected
- **User Confirmation**: Clear warnings about what each mode will do
- **Detailed Logging**: Every operation tracked for troubleshooting

## 🖥️ Enhanced System Requirements

### Minimum Requirements
- **PowerShell 5.1 or later** (✅ Enhanced 5.1 compatibility)
- **Administrator privileges** (Required for system modifications)
- **Windows 10/11 or Windows Server 2016+** (Tested on latest versions)
- **.NET Framework 4.5 or later** (For GUI components)

### 🆕 Recommended for Best Performance
- **PowerShell 5.1.19041+** (Latest security updates)
- **8GB+ RAM** (For handling large product installations)
- **SSD Storage** (Faster temporary file operations)
- **Stable Internet** (For downloading validation tools if needed)

### 🔧 Enhanced System Validation

Pre-flight system checks now include:
```powershell
# Comprehensive system validation
.\Validate-Enhanced-Project.ps1 -All

# Individual checks available:
.\Test-PendingReboot.ps1           # Check reboot requirements
.\Test-Error1603Prevention.ps1     # MSI error prevention
.\Test-Main-Flow.ps1              # Core functionality test
```

## 🛡️ Enhanced Safety Features

### 🆕 Critical Component Protection
- **Automatic Detection**: Identifies licensing components during scan
- **Mode-Aware Protection**: Preserves components based on selected uninstall mode
- **Real-time Validation**: Confirms protection during uninstall process
- **Post-Uninstall Verification**: Validates critical components remain intact

### 🆕 Smart User Guidance
- **Clear Mode Selection**: Visual indicators of what each mode preserves/removes
- **Component Count Display**: Shows grouped products with component counts
- **Protection Warnings**: Clear alerts about licensing component preservation
- **Confirmation Dialogs**: Detailed summaries before destructive operations

### Enhanced Backup & Recovery
- **Selective Backup**: Intelligent add-in preservation in reinstall mode
- **Licensing Backup**: Automatic backup of license files and settings
- **Registry Snapshots**: Critical registry states preserved
- **Recovery Documentation**: Clear instructions for manual recovery if needed

### 🔍 Pre-Operation Validation
- **System State Check**: Validates system readiness before uninstall
- **Component Integrity**: Verifies Autodesk installation integrity
- **Dependency Analysis**: Maps component relationships before removal
- **Exit Strategy**: Clear rollback procedures if issues detected

## 👥 Enhanced Development & Contribution

### 🆕 Enhanced Development Environment

#### Project Validation
```powershell
# Validate entire enhanced project
.\Validate-Enhanced-Project.ps1 -All

# Specific validation checks
.\Validate-Enhanced-Project.ps1 -ModuleStructure    # Check module architecture
.\Validate-Enhanced-Project.ps1 -CriticalComponents # Verify protection logic
.\Validate-Enhanced-Project.ps1 -ProductGrouping    # Test grouping algorithms
```

#### Testing Framework
The enhanced uninstaller includes a comprehensive testing suite:

```powershell
# Core functionality tests
.\Test-Main-Flow.ps1                        # End-to-end workflow
.\Test-Product-Detection.ps1                # Product grouping logic
.\Test-Critical-Component-Preservation.ps1  # Licensing protection

# Error prevention tests  
.\Test-Error1603Prevention.ps1              # MSI error conditions
.\Test-PendingReboot.ps1                    # System state validation
.\Test-PowerShell-Compatibility.ps1         # PowerShell 5.1 fixes
```

### 🆕 Adding New Features

#### Product Grouping Enhancement
1. **Update Detection Logic**: Modify `Get-MainProductName` in `ProductDetection.psm1`
2. **Add Grouping Rules**: Extend product pattern matching
3. **Test Integration**: Use `Test-Product-Detection.ps1` to validate
4. **Update Documentation**: Modify this README and user guide

#### Critical Component Protection
1. **Identify Components**: Research Autodesk licensing dependencies
2. **Update Protection Lists**: Add to `$CriticalSharedComponents` in `Config.psm1`
3. **Enhance Filtering**: Modify protection logic in `UninstallOperations.psm1`
4. **Validate Protection**: Test with `Test-CriticalComponentPreservation.ps1`

### 🔧 Enhanced Code Standards

- **PowerShell 5.1 Compatibility**: Ensure all code works with legacy PowerShell
- **Error Prevention First**: Design with error prevention as primary goal
- **User Experience Focus**: Prioritize simplified, clear user interactions
- **Comprehensive Logging**: Every operation must be tracked and validated
- **Modular Design**: Keep enhancements in separate, testable modules

## 🔧 Enhanced Troubleshooting

### 🆕 Common Issues & Solutions

#### 1. **"Results object missing Success property"**
- **Cause**: PowerShell 5.1 array wrapping behavior
- **Solution**: ✅ **Fixed in enhanced version** - Automatic array unwrapping
- **Prevention**: Enhanced object validation and type checking

#### 2. **"Count property cannot be found"**  
- **Cause**: PowerShell 5.1 compatibility with newer syntax
- **Solution**: ✅ **Fixed in enhanced version** - Added `@()` array conversion
- **Prevention**: Comprehensive PowerShell 5.1 compatibility layer

#### 3. **"License Manager not functioning" after reinstall**
- **Cause**: AdskIdentityManager was removed during uninstall
- **Solution**: ✅ **Prevented in enhanced version** - Critical component protection
- **Recovery**: Use "Reinstall Preparation" mode for future uninstalls

#### 4. **MSI Error 1603 during installation**
- **Cause**: Pending reboot, process conflicts, or registry locks
- **Solution**: ✅ **Enhanced prevention** - Run `.\Test-Error1603Prevention.ps1`
- **Prevention**: Automatic pre-flight checks before uninstall

#### 5. **Overwhelming product selection interface**
- **Cause**: Too many individual components listed
- **Solution**: ✅ **Enhanced in new version** - Simplified product grouping
- **Benefit**: Select "Revit 2025" instead of 8 individual components

### 🛠️ Enhanced Diagnostic Tools

#### Quick System Check
```powershell
# Comprehensive system validation
.\Validate-Enhanced-Project.ps1 -Quick

# Check for common issues
.\Test-Error1603Prevention.ps1 -CheckOnly
.\Test-PendingReboot.ps1
```

#### Detailed Troubleshooting
```powershell
# Full system analysis
.\Validate-Enhanced-Project.ps1 -All -Verbose

# Component-specific testing
.\Test-CriticalComponentPreservation.ps1 -CheckCurrentState
.\Test-Main-Flow.ps1 -Debug
```

### 📞 Enhanced Support Information

#### Log Analysis Priority
1. **Action Log**: Primary troubleshooting source
2. **Debug Output**: Component-level operation details  
3. **Validation Results**: Pre/post operation system state
4. **MSI Logs**: Individual component uninstall details

#### Support Checklist
- ✅ Run enhanced validation tools
- ✅ Check PowerShell version compatibility
- ✅ Verify administrator privileges
- ✅ Review critical component protection status
- ✅ Analyze comprehensive logs

## 📄 License & Support

This enhanced project is provided under the MIT License for educational and utility purposes. 

### Enhanced Support Resources

- 📖 **[ENHANCED_USER_GUIDE.md](ENHANCED_USER_GUIDE.md)**: Comprehensive usage guide
- 🛡️ **[CRITICAL_COMPONENT_PRESERVATION.md](CRITICAL_COMPONENT_PRESERVATION.md)**: Licensing protection details
- 📋 **[CHANGELOG.md](CHANGELOG.md)**: Version history and updates
- 🤝 **[CONTRIBUTING.md](CONTRIBUTING.md)**: Contribution guidelines
- 🚀 **[GITHUB_READINESS.md](GITHUB_READINESS.md)**: Project setup information

### Getting Help

For issues or questions:
1. **Check Enhanced Logs**: Review comprehensive logs in `C:\Temp\AutodeskUninstaller\`
2. **Run Validation Tools**: Use `.\Validate-Enhanced-Project.ps1 -All`
3. **Review Documentation**: Check the enhanced user guide and troubleshooting sections
4. **Test System State**: Run diagnostic tools to identify specific issues

## 📈 Enhanced Version History

### v2.0.0 - Enhanced Release (Current)
- **🎯 Simplified Product Selection**: Main products instead of individual components
- **🛡️ Critical Component Protection**: Prevents licensing errors during reinstall
- **⚡ Optimized Performance**: Smart dependency ordering and parallel processing
- **🔧 Error Prevention**: PowerShell 5.1 compatibility and MSI error prevention
- **📊 Enhanced Monitoring**: Comprehensive logging and validation tools
- **🧪 Testing Framework**: Complete test suite for validation and debugging

### v1.0.0 - Initial Modular Release
- Converted monolithic script to modular architecture
- Improved maintainability and extensibility
- Enhanced error handling and logging

---

<div align="center">
  
**🚀 Enhanced Autodesk Uninstaller - Simplified, Safe, and Optimized**

*Making Autodesk product management effortless while protecting your licensing infrastructure*

</div>
