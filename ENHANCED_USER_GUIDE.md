# Enhanced Autodesk Uninstaller - User Guide

## 🚀 What's New

The Autodesk Uninstaller has been significantly enhanced to address common #### 2. "Access Denied" Errors
- **Cause**: Not running as Administrator
- **Solution**: Right-click PowerShell → "Run as Administrator"

#### 3. MSI Installer Still Running
- **Cause**: Another installer is active
- **Solution**: Wait for other installations to complete, or restart system

#### 4. Some Products Still Listed
- **Cause**: Registry entries without actual files
- **Solution**: This is normal - the enhanced uninstaller handles this

#### 5. Licensing Issues After Reinstall
- **Cause**: Used "Full Uninstall" mode when should have used "Reinstall Preparation"
- **Solution**: 
  - Use Autodesk's licensing repair tools
  - Or run uninstaller again in "Reinstall Preparation" mode
  - Re-download and install licensing components

#### 6. "AdskIdentityManager not found" Errorllation issues, particularly the "License Manager is not functioning", "Missing schema folder", and MSI pending reboot errors.

## 🔧 Key Enhancements

### 1. **Pending Reboot Detection**
- **Issue Addressed**: MSI error "MsiSystemRebootPending = 1"
- **Solution**: Automatically detects if system reboot is required before uninstall
- **Benefit**: Prevents failed uninstalls and registry corruption

### 2. **Comprehensive Licensing Cleanup**
- **Issue Addressed**: "License Manager is not functioning" errors
- **Solution**: Complete removal of ADLM, FLEXnet, and licensing components
- **Benefit**: Clean slate for license activation after reinstall

### 3. **Shared Components Removal**
- **Issue Addressed**: "Missing schema folder" and startup errors
- **Solution**: Removes all Autodesk shared folders, schemas, and templates
- **Benefit**: Prevents conflicts between old and new installations

### 4. **System Maintenance**
- **Issue Addressed**: Corrupted system files and registry entries
- **Solution**: Runs SFC, DISM, and clears Windows Update cache
- **Benefit**: Ensures clean system state for reinstallation

### 5. **Verification & Repair**
- **Issue Addressed**: Incomplete uninstalls and missing components
- **Solution**: Verifies removal success and repairs essential components
- **Benefit**: Maximizes chances of successful reinstallation

## 📋 Before You Start

### Step 1: Check for Pending Reboot
Run the pending reboot test script first:
```powershell
powershell.exe -ExecutionPolicy Bypass -File .\Test-PendingReboot.ps1
```

**If pending reboot detected:**
1. Save your work
2. Reboot your system
3. Wait for complete startup
4. Then proceed with uninstaller

### Step 2: Test for Error 1603 Prevention
Check for all conditions that cause installation failures:
```powershell
powershell.exe -ExecutionPolicy Bypass -File .\Test-Error1603Prevention.ps1 -CheckOnly
```

**If issues detected:**
1. Fix them with: `.\Test-Error1603Prevention.ps1 -FixIssues`
2. Reboot if recommended
3. Test again before proceeding

### Step 3: Validate the Enhanced Uninstaller
Run the validation script to ensure all enhancements are working:
```powershell
powershell.exe -ExecutionPolicy Bypass -File .\Validate-Enhanced-Project.ps1 -All
```

## 🎯 Running the Enhanced Uninstaller

### Choosing the Right Mode

**CRITICAL: Choose the correct uninstall mode to avoid licensing issues!**

#### 🔄 Reinstall Preparation Mode (Recommended for most users)
- **Use when**: Planning to reinstall Autodesk products
- **Preserves**: 
  - ✅ AdskIdentityManager (critical for licensing)
  - ✅ Core licensing infrastructure (CLM, DLMFramework, AdLM)
  - ✅ User add-ins and settings
  - ✅ Shared component structure
- **Cleans**: 
  - ✅ Product-specific files and corrupted data
  - ✅ Cache and temporary licensing files
  - ✅ Problematic schemas and materials
  - ✅ Registry entries causing conflicts

#### 🗑️ Full Uninstall Mode (Use with caution)
- **Use when**: Permanently removing all Autodesk software
- **Removes**: 
  - ❌ ALL licensing components (including AdskIdentityManager)
  - ❌ ALL shared components
  - ❌ ALL user settings and add-ins
  - ❌ ALL system integration
- **Warning**: You'll need to completely re-setup licensing after reinstall

### Method 1: GUI Interface (Recommended)
```powershell
powershell.exe -ExecutionPolicy Bypass -File .\Main.ps1
```

### Method 2: Direct Script
```powershell
powershell.exe -ExecutionPolicy Bypass -File .\AutodeskUninstaller_GUI_Enhanced.ps1
```

## ⚠️ Important Notes

### During Uninstall Process:
1. **Pending Reboot Warning**: If detected, you'll be warned and can choose to continue or exit
2. **Progress Tracking**: Enhanced progress window shows detailed cleanup steps
3. **Verification**: System automatically verifies removal success
4. **Final Cleanup**: Kills lingering processes and clears temporary files

### After Uninstall:
- **Wait 2-3 minutes** before reinstalling Autodesk products
- **Run Windows Update** and reboot if recommended
- **Check the log file** for any warnings or errors

## 📊 Understanding the Results

### Success Indicators:
- ✅ **Verification: PASSED** - All products successfully removed
- ✅ **Final Cleanup: COMPLETED** - System fully cleaned
- ✅ **No Pending Reboot** - System ready for reinstall

### Warning Indicators:
- ⚠️ **Pending Reboot Detected** - Reboot recommended before reinstall
- ⚠️ **Verification: FAILED** - Some products may need manual removal
- ⚠️ **Final Cleanup: PARTIAL** - Some cleanup operations incomplete

### Action Required:
- ❌ **Multiple Failures** - Contact support with log file
- 🔄 **Reboot Required** - System restart needed before proceeding

## 🔍 Troubleshooting

### Common Issues:

#### 1. Error 1603 During Installation
- **Cause**: Most commonly pending reboot, insufficient permissions, or system conflicts
- **Solution**: 
  - Run `.\Test-Error1603Prevention.ps1 -CheckOnly` to identify causes
  - Fix issues with `.\Test-Error1603Prevention.ps1 -FixIssues`
  - Reboot system if pending reboot detected
  - Run uninstaller again in appropriate mode

#### 2. "Access Denied" Errors
- **Cause**: Not running as Administrator
- **Solution**: Right-click PowerShell → "Run as Administrator"

#### 2. MSI Installer Still Running
- **Cause**: Another installer is active
- **Solution**: Wait for other installations to complete, or restart system

#### 3. Some Products Still Listed
- **Cause**: Registry entries without actual files
- **Solution**: This is normal - the enhanced uninstaller handles this

#### 4. Licensing Issues After Reinstall
- **Cause**: Used "Full Uninstall" mode when should have used "Reinstall Preparation"
- **Solution**: 
  - Use Autodesk's licensing repair tools
  - Or run uninstaller again in "Reinstall Preparation" mode
  - Re-download and install licensing components

#### 5. "AdskIdentityManager not found" Error
- **Cause**: Critical licensing component removed in Full Uninstall mode
- **Solution**: 
  - Download latest Autodesk Desktop App
  - Install it first to restore licensing infrastructure
  - Then install your desired Autodesk products

## 📁 Log Files

Enhanced logging provides detailed information:
- **Location**: Same directory as uninstaller
- **Format**: Timestamped entries with action details
- **Use**: Troubleshooting and verification of cleanup steps

## 🎯 Best Practices

### Before Uninstalling:
1. ✅ Close all Autodesk applications
2. ✅ Run pending reboot check
3. ✅ Backup important project files
4. ✅ Validate enhanced uninstaller

### During Uninstall:
1. ✅ Monitor progress window for status
2. ✅ Don't interrupt the process
3. ✅ Address any warnings immediately

### After Uninstall:
1. ✅ Review the summary dialog
2. ✅ Follow any recommendations
3. ✅ Wait before reinstalling
4. ✅ Check log file for issues

## 🔄 Reinstallation Tips

### For Optimal Results:
1. **Wait 2-3 minutes** after uninstall completion
2. **Run Windows Update** and install any pending updates
3. **Reboot the system** if recommended
4. **Disable antivirus temporarily** during Autodesk installation
5. **Install as Administrator** with stable internet connection
6. **Activate licenses immediately** after installation

### If Issues Persist:
1. Run the uninstaller again in "Full Uninstall" mode
2. Check Windows Event Viewer for system errors
3. Use Windows System File Checker: `sfc /scannow`
4. Contact Autodesk support with uninstaller log file

## 📞 Support

If you encounter issues with the enhanced uninstaller:
1. Check the generated log file for error details
2. Run the validation script to identify specific problems
3. Ensure you're running as Administrator
4. Verify system meets Autodesk requirements

The enhanced uninstaller addresses the most common causes of Autodesk installation failures and should significantly improve your reinstallation success rate.
