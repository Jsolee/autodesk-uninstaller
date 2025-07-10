<#
.SYNOPSIS
    Uninstall operations module for Autodesk Uninstaller
.DESCRIPTION
    Handles uninstallation, service management, and cleanup operations
#>

<#
.SYNOPSIS
    Stops Autodesk services and processes
.DESCRIPTION
    Stops common Autodesk services and kills related processes
#>
function Stop-AutodeskServices {
    Write-ActionLog "Stopping Autodesk services and processes..."
    
    $config = Get-Config
    $services = $config.AutodeskServices
    $processes = $config.AutodeskProcesses
    
    # Stop common Autodesk services
    foreach ($service in $services) {
        try {
            Stop-Service $service -Force -ErrorAction SilentlyContinue
            Set-Service $service -StartupType Disabled -ErrorAction SilentlyContinue
            Write-ActionLog "Stopped service: $service"
        } catch { 
            Write-ActionLog "Could not stop service: $service"
        }
    }
    
    # Kill popup processes
    foreach ($proc in $processes) {
        try {
            Stop-Process -Name $proc -Force -ErrorAction SilentlyContinue
            Write-ActionLog "Killed process: $proc"
        } catch {
            Write-ActionLog "Could not kill process: $proc"
        }
    }
}

<#
.SYNOPSIS
    Uninstalls a specific Autodesk product
.DESCRIPTION
    Uninstalls a product using its uninstall string
.PARAMETER Product
    The product object containing uninstall information
.OUTPUTS
    Boolean indicating success or failure
#>
function Uninstall-Product {
    param([PSCustomObject]$Product)
    
    Write-ActionLog "Uninstalling: $($Product.DisplayName)"
    $exitCode = $null
    
    try {
        if ($Product.UninstallString -match '^(.*?Installer\.exe)(.*)$') {
            # ODIS installer
            $exePath = $matches[1].Trim('"')
            $argList = $matches[2].Trim()
            if ($argList -notmatch '\b-i\s+uninstall\b') { 
                $argList = "-i uninstall $argList" 
            }
            if ($argList -notmatch '\b--silent\b') { 
                $argList += ' --silent' 
            }
            
            Write-ActionLog "Command: $exePath $argList"
            $proc = Start-Process $exePath $argList -WindowStyle Hidden -Wait -PassThru
            $exitCode = $proc.ExitCode
            
        } elseif ($Product.UninstallString -match '/[IX]\s*\{([^\}]+)\}') {
            # MSI installer
            $guid = $Matches[1]
            $logPath = Get-LogPath
            $argList = "/X `{$guid`} /qn /l*v `"$logPath\MSI_$($Product.DisplayName -replace '[^\w]','_').log`""
            
            Write-ActionLog "Command: msiexec.exe $argList"
            $proc = Start-Process msiexec.exe $argList -WindowStyle Hidden -Wait -PassThru
            $exitCode = $proc.ExitCode
            
        } else {
            Write-ActionLog "Unknown uninstall method for $($Product.DisplayName)"
            return $false
        }
        
        if ($exitCode -in 0, 1605, 3010) {
            Write-ActionLog "Successfully uninstalled: $($Product.DisplayName) (Exit code: $exitCode)"
            return $true
        } else {
            Write-ActionLog "Failed to uninstall: $($Product.DisplayName) (Exit code: $exitCode)"
            return $false
        }
        
    } catch {
        Write-ActionLog "Error uninstalling $($Product.DisplayName): $_"
        return $false
    }
}

<#
.SYNOPSIS
    Backs up add-ins for a specific product type
.DESCRIPTION
    Creates a backup of add-ins and plugins for reinstallation scenario
.PARAMETER ProductType
    The type of product to backup add-ins for
.OUTPUTS
    Array of backed up items
#>
function Backup-AddIns {
    param([string]$ProductType)
    
    Write-ActionLog "Backing up add-ins for $ProductType..."
    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $config = Get-Config
    $backupPath = "$($config.AddInsBackupRootPath)\$timestamp"
    Set-AddInsBackupPath -value $backupPath
    
    [void](New-Item -ItemType Directory -Path $backupPath -Force)
    
    $backedUpItems = @()
    $addInPaths = $config.AddInPaths
    
    # Get all user profiles
    $profiles = Get-UserProfiles
    
    foreach ($userProfile in $profiles) {
        $profilePath = $userProfile.ProfileImagePath
        $userName = Split-Path $profilePath -Leaf
        
        foreach ($location in @('AppData\Local', 'AppData\Roaming')) {
            $basePath = Join-Path $profilePath $location
            
            if ($addInPaths.ContainsKey($ProductType)) {
                foreach ($addInDef in $addInPaths[$ProductType]) {
                    $fullPath = Join-Path $basePath $addInDef.Path
                    
                    if (Test-Path $fullPath) {
                        $items = Get-ChildItem -Path $fullPath -Filter $addInDef.Pattern -Recurse -ErrorAction SilentlyContinue
                        
                        foreach ($item in $items) {
                            $relativePath = $item.FullName.Substring($profilePath.Length + 1)
                            $destPath = Join-Path $backupPath "$userName\$relativePath"
                            $destDir = Split-Path $destPath -Parent
                            
                            [void](New-Item -ItemType Directory -Path $destDir -Force -ErrorAction SilentlyContinue)
                            Copy-Item -Path $item.FullName -Destination $destPath -Force -ErrorAction SilentlyContinue
                            
                            $backedUpItems += @{
                                Source = $item.FullName
                                Destination = $destPath
                                User = $userName
                            }
                            
                            Write-ActionLog "Backed up: $($item.FullName) -> $destPath"
                        }
                    }
                }
            }
        }
    }
    
    Write-ActionLog "Backed up $($backedUpItems.Count) add-in items to: $backupPath"
    return $backedUpItems
}

<#
.SYNOPSIS
    Clears product data from the system
.DESCRIPTION
    Removes product files and user data with optional add-in preservation
.PARAMETER ProductType
    The type of product to clear data for
.PARAMETER PreserveAddIns
    Whether to preserve add-ins and plugins
#>
function Clear-ProductData {
    param(
        [string]$ProductType,
        [bool]$PreserveAddIns
    )
    
    Write-ActionLog "Clearing $ProductType data (PreserveAddIns: $PreserveAddIns)..."
    
    $config = Get-Config
    $productPaths = $config.ProductPaths
    
    # Clear product-specific paths
    if ($productPaths.ContainsKey($ProductType)) {
        foreach ($pathPattern in $productPaths[$ProductType]) {
            foreach ($path in Get-Item $pathPattern -ErrorAction SilentlyContinue) {
                Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
                Write-ActionLog "Removed: $path"
            }
        }
    }
    
    # Clear user data
    $profiles = Get-UserProfiles
    
    foreach ($userProfile in $profiles) {
        $profilePath = $userProfile.ProfileImagePath
        
        if (-not $PreserveAddIns) {
            # Full cleanup - remove everything
            Clear-AllAutodeskUserData -ProfilePath $profilePath
        } else {
            # Selective cleanup - preserve add-ins
            Clear-SelectiveAutodeskUserData -ProfilePath $profilePath
        }
        
        # Clean up Desktop Autodesk files
        Clear-DesktopAutodeskFiles -ProfilePath $profilePath
    }
    
    # Perform deep system cleanup to prevent reinstallation issues
    Clear-AutodeskSystemRemnants
}

<#
.SYNOPSIS
    Gets all user profiles from the registry
.DESCRIPTION
    Retrieves user profile information from the registry
.OUTPUTS
    Array of user profile objects
#>
function Get-UserProfiles {
    return Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*' | 
           Where-Object { $_.PSObject.Properties.Name -contains 'ProfileImagePath' -and $_.ProfileImagePath }
}

<#
.SYNOPSIS
    Clears all Autodesk user data
.DESCRIPTION
    Removes all Autodesk data from user profile directories
.PARAMETER ProfilePath
    The path to the user profile
#>
function Clear-AllAutodeskUserData {
    param([string]$ProfilePath)
    
    foreach ($appData in @('AppData\Local\Autodesk', 'AppData\Roaming\Autodesk')) {
        $fullPath = Join-Path $ProfilePath $appData
        if (Test-Path $fullPath) {
            Get-ChildItem $fullPath -Recurse -File | ForEach-Object {
                Write-ActionLog "Deleting: $($_.FullName)"
            }
            Remove-Item $fullPath -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

<#
.SYNOPSIS
    Selectively clears Autodesk user data
.DESCRIPTION
    Removes Autodesk data while preserving add-ins and plugins
.PARAMETER ProfilePath
    The path to the user profile
#>
function Clear-SelectiveAutodeskUserData {
    param([string]$ProfilePath)
    
    $config = Get-Config
    $preservePaths = $config.PreservePaths
    
    foreach ($appData in @('AppData\Local\Autodesk', 'AppData\Roaming\Autodesk')) {
        $basePath = Join-Path $ProfilePath $appData
        if (Test-Path $basePath) {
            Get-ChildItem $basePath -Recurse -File | ForEach-Object {
                $shouldPreserve = $false
                foreach ($pattern in $preservePaths) {
                    if ($_.FullName -like $pattern) {
                        $shouldPreserve = $true
                        break
                    }
                }
                
                if (-not $shouldPreserve) {
                    Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue
                    Write-ActionLog "Deleted: $($_.FullName)"
                } else {
                    Write-ActionLog "Preserved: $($_.FullName)"
                }
            }
        }
    }
}

<#
.SYNOPSIS
    Clears Autodesk system remnants that can cause reinstallation issues
.DESCRIPTION
    Performs deep cleanup of registry entries, system files, and services
#>
function Clear-AutodeskSystemRemnants {
    Write-ActionLog "Performing deep system cleanup to prevent reinstallation issues..."
    
    $config = Get-Config
    
    # Clean registry entries
    Clear-AutodeskRegistryEntries
    
    # Clean licensing components specifically
    Clear-AutodeskLicensingComponents
    
    # Clean system files
    Clear-AutodeskSystemFiles
    
    # Clean Windows Installer cache
    Clear-AutodeskInstallerCache
    
    # Reset Windows Installer database
    Reset-WindowsInstallerDatabase
}

<#
.SYNOPSIS
    Clears Autodesk licensing components that cause "License Manager not functioning" errors
.DESCRIPTION
    Removes ADLM, FLEXnet, and other licensing-related components completely
#>
function Clear-AutodeskLicensingComponents {
    Write-ActionLog "Performing comprehensive licensing cleanup..."
    
    # Stop all licensing-related processes
    $licensingProcesses = @('adlmint', 'adlmact', 'lmgrd', 'adskflex', 'FNPLicensingService')
    foreach ($proc in $licensingProcesses) {
        try {
            Stop-Process -Name $proc -Force -ErrorAction SilentlyContinue
            Write-ActionLog "Stopped licensing process: $proc"
        } catch {
            Write-ActionLog "Process not running or already stopped: $proc"
        }
    }
    
    # Remove licensing files and folders
    $config = Get-Config
    $licensingPaths = $config.LicensingCleanupPaths
    
    foreach ($path in $licensingPaths) {
        try {
            if (Test-Path $path) {
                # Special handling for system files
                if ($path -match 'System32|SysWOW64') {
                    Get-ChildItem $path -ErrorAction SilentlyContinue | Where-Object { 
                        $_.Name -like '*adlm*' -or $_.Name -like '*flexnet*' -or $_.Name -like '*autodesk*'
                    } | ForEach-Object {
                        Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue
                        Write-ActionLog "Removed licensing file: $($_.FullName)"
                    }
                } else {
                    Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
                    Write-ActionLog "Removed licensing path: $path"
                }
            }
        } catch {
            Write-ActionLog "Could not remove licensing path: $path - $($_.Exception.Message)"
        }
    }
    
    # Clean licensing registry entries
    Clear-LicensingRegistryEntries
    
    # Clean user-specific licensing data
    Clear-UserLicensingData
    
    # Reset licensing services
    Reset-LicensingServices
}

<#
.SYNOPSIS
    Clears licensing-specific registry entries
.DESCRIPTION
    Removes FLEXnet, ADLM, and Autodesk licensing registry keys
#>
function Clear-LicensingRegistryEntries {
    Write-ActionLog "Cleaning licensing registry entries..."
    
    $licensingRegPaths = @(
        'HKLM:\SOFTWARE\FLEXlm License Manager',
        'HKLM:\SOFTWARE\Wow6432Node\FLEXlm License Manager',
        'HKCU:\SOFTWARE\FLEXlm License Manager',
        'HKLM:\SOFTWARE\Autodesk\ADLM',
        'HKLM:\SOFTWARE\Wow6432Node\Autodesk\ADLM',
        'HKCU:\SOFTWARE\Autodesk\ADLM',
        'HKLM:\SOFTWARE\Macrovision',
        'HKLM:\SOFTWARE\Wow6432Node\Macrovision',
        'HKCU:\SOFTWARE\Macrovision'
    )
    
    foreach ($regPath in $licensingRegPaths) {
        try {
            if (Test-Path $regPath) {
                Remove-Item $regPath -Recurse -Force -ErrorAction SilentlyContinue
                Write-ActionLog "Removed licensing registry path: $regPath"
            }
        } catch {
            Write-ActionLog "Could not remove licensing registry path: $regPath - $($_.Exception.Message)"
        }
    }
}

<#
.SYNOPSIS
    Clears user-specific licensing data
.DESCRIPTION
    Removes licensing data from all user profiles
#>
function Clear-UserLicensingData {
    Write-ActionLog "Cleaning user licensing data..."
    
    $profiles = Get-UserProfiles
    
    foreach ($userProfile in $profiles) {
        $profilePath = $userProfile.ProfileImagePath
        
        $userLicensingPaths = @(
            'AppData\Local\Autodesk\ADLM',
            'AppData\Roaming\Autodesk\ADLM',
            'AppData\Local\FLEXnet',
            'AppData\Roaming\FLEXnet'
        )
        
        foreach ($licPath in $userLicensingPaths) {
            $fullPath = Join-Path $profilePath $licPath
            if (Test-Path $fullPath) {
                try {
                    Remove-Item $fullPath -Recurse -Force -ErrorAction SilentlyContinue
                    Write-ActionLog "Removed user licensing data: $fullPath"
                } catch {
                    Write-ActionLog "Could not remove user licensing data: $fullPath"
                }
            }
        }
    }
}

<#
.SYNOPSIS
    Resets licensing services to ensure clean state
.DESCRIPTION
    Removes and recreates licensing services if needed
#>
function Reset-LicensingServices {
    Write-ActionLog "Resetting licensing services..."
    
    $licensingServices = @(
        'AdskLicensingService',
        'FNPLicensingService', 
        'GenuineService',
        'AdAppMgrSvc'
    )
    
    foreach ($serviceName in $licensingServices) {
        try {
            # Stop the service
            Stop-Service $serviceName -Force -ErrorAction SilentlyContinue
            
            # Delete the service
            $deleteResult = & sc.exe delete $serviceName 2>&1
            Write-ActionLog "Service deletion result for $serviceName`: $deleteResult"
            
        } catch {
            Write-ActionLog "Could not reset service: $serviceName - $($_.Exception.Message)"
        }
    }
    
    # Clear service registry remnants
    $serviceRegPaths = @(
        'HKLM:\SYSTEM\CurrentControlSet\Services\AdskLicensingService',
        'HKLM:\SYSTEM\CurrentControlSet\Services\FNPLicensingService',
        'HKLM:\SYSTEM\CurrentControlSet\Services\GenuineService',
        'HKLM:\SYSTEM\CurrentControlSet\Services\AdAppMgrSvc'
    )
    
    foreach ($regPath in $serviceRegPaths) {
        try {
            if (Test-Path $regPath) {
                Remove-Item $regPath -Recurse -Force -ErrorAction SilentlyContinue
                Write-ActionLog "Removed service registry: $regPath"
            }
        } catch {
            Write-ActionLog "Could not remove service registry: $regPath"
        }
    }
}

<#
.SYNOPSIS
    Clears Autodesk registry entries that can interfere with reinstallation
.DESCRIPTION
    Removes registry keys and values related to Autodesk products
#>
function Clear-AutodeskRegistryEntries {
    Write-ActionLog "Cleaning Autodesk registry entries..."
    
    $config = Get-Config
    $registryPaths = $config.RegistryCleanupPaths
    
    foreach ($regPath in $registryPaths) {
        try {
            if (Test-Path $regPath) {
                # For service entries, stop and remove the service first
                if ($regPath -match 'Services\\(.+)$') {
                    $serviceName = $matches[1]
                    try {
                        Stop-Service $serviceName -Force -ErrorAction SilentlyContinue
                        sc.exe delete $serviceName | Out-Null
                        Write-ActionLog "Removed service: $serviceName"
                    } catch {
                        Write-ActionLog "Could not remove service: $serviceName"
                    }
                }
                
                Remove-Item $regPath -Recurse -Force -ErrorAction SilentlyContinue
                Write-ActionLog "Removed registry path: $regPath"
            }
        } catch {
            Write-ActionLog "Could not remove registry path: $regPath - $($_.Exception.Message)"
        }
    }
    
    # Clean SharedDLLs entries
    try {
        $sharedDllPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\SharedDLLs'
        if (Test-Path $sharedDllPath) {
            $sharedDlls = Get-ItemProperty $sharedDllPath -ErrorAction SilentlyContinue
            if ($sharedDlls) {
                $sharedDlls.PSObject.Properties | Where-Object { $_.Name -like '*autodesk*' -or $_.Name -like '*adlm*' } | ForEach-Object {
                    Remove-ItemProperty -Path $sharedDllPath -Name $_.Name -ErrorAction SilentlyContinue
                    Write-ActionLog "Removed SharedDLL entry: $($_.Name)"
                }
            }
        }
    } catch {
        Write-ActionLog "Could not clean SharedDLLs entries: $($_.Exception.Message)"
    }
}

<#
.SYNOPSIS
    Clears Autodesk system files that can interfere with reinstallation
.DESCRIPTION
    Removes system-level Autodesk files and libraries
#>
function Clear-AutodeskSystemFiles {
    Write-ActionLog "Cleaning Autodesk system files..."
    
    $config = Get-Config
    $systemPaths = $config.SystemCleanupPaths
    
    foreach ($pathPattern in $systemPaths) {
        try {
            if ($pathPattern -match '\*') {
                # Handle wildcards
                $items = Get-Item $pathPattern -ErrorAction SilentlyContinue
                foreach ($item in $items) {
                    if ($item.Name -like '*autodesk*' -or $item.Name -like '*adlm*') {
                        Remove-Item $item.FullName -Recurse -Force -ErrorAction SilentlyContinue
                        Write-ActionLog "Removed system file/folder: $($item.FullName)"
                    }
                }
            } else {
                if (Test-Path $pathPattern) {
                    Remove-Item $pathPattern -Recurse -Force -ErrorAction SilentlyContinue
                    Write-ActionLog "Removed system path: $pathPattern"
                }
            }
        } catch {
            Write-ActionLog "Could not remove system path: $pathPattern - $($_.Exception.Message)"
        }
    }
}

<#
.SYNOPSIS
    Clears Autodesk entries from Windows Installer cache
.DESCRIPTION
    Removes cached MSI files and installer database entries
#>
function Clear-AutodeskInstallerCache {
    Write-ActionLog "Cleaning Windows Installer cache..."
    
    try {
        # Clean MSI cache
        $msiCachePath = "$env:WINDIR\Installer"
        if (Test-Path $msiCachePath) {
            Get-ChildItem $msiCachePath -Filter "*.msi" | ForEach-Object {
                try {
                    $msiInfo = & msiexec /qn /l* "$env:TEMP\msi_check.log" /i $_.FullName REINSTALLMODE=vomus REINSTALL=ALL 2>$null
                    $logContent = Get-Content "$env:TEMP\msi_check.log" -ErrorAction SilentlyContinue
                    if ($logContent -join ' ' -match 'autodesk|adlm') {
                        Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue
                        Write-ActionLog "Removed MSI cache file: $($_.Name)"
                    }
                    Remove-Item "$env:TEMP\msi_check.log" -ErrorAction SilentlyContinue
                } catch {
                    # Skip files we can't process
                }
            }
        }
    } catch {
        Write-ActionLog "Could not clean MSI cache: $($_.Exception.Message)"
    }
}

<#
.SYNOPSIS
    Resets Windows Installer database to clear any corruption
.DESCRIPTION
    Restarts Windows Installer service and clears temporary files
#>
function Reset-WindowsInstallerDatabase {
    Write-ActionLog "Resetting Windows Installer database..."
    
    try {
        # Stop Windows Installer service
        Stop-Service "msiserver" -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        
        # Clear Windows Installer temp files
        $tempPaths = @(
            "$env:TEMP\*.msi",
            "$env:TEMP\*.msp",
            "$env:TEMP\*.mst",
            "$env:WINDIR\Temp\*.msi",
            "$env:WINDIR\Temp\*.msp",
            "$env:WINDIR\Temp\*.mst"
        )
        
        foreach ($tempPath in $tempPaths) {
            Get-Item $tempPath -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
        }
        
        # Restart Windows Installer service
        Start-Service "msiserver" -ErrorAction SilentlyContinue
        Write-ActionLog "Windows Installer service reset completed"
        
    } catch {
        Write-ActionLog "Could not reset Windows Installer database: $($_.Exception.Message)"
    }
}

<#
.SYNOPSIS
    Clears Autodesk-related files from Desktop
.DESCRIPTION
    Removes Autodesk shortcuts, installers, and related files from the Desktop
.PARAMETER ProfilePath
    The path to the user profile
#>
function Clear-DesktopAutodeskFiles {
    param([string]$ProfilePath)
    
    $desktopPath = Join-Path $ProfilePath "Desktop"
    if (Test-Path $desktopPath) {
        Write-ActionLog "Checking Desktop for Autodesk files: $desktopPath"
        
        # Autodesk-related file patterns to look for
        $autodeskPatterns = @(
            '*Autodesk*',
            '*Revit*',
            '*AutoCAD*',
            '*3ds Max*',
            '*Maya*',
            '*Inventor*',
            '*Navisworks*',
            '*Civil 3D*',
            '*Fusion*',
            '*Desktop Connector*'
        )
        
        foreach ($pattern in $autodeskPatterns) {
            $matchingFiles = Get-ChildItem $desktopPath -Name $pattern -ErrorAction SilentlyContinue
            foreach ($file in $matchingFiles) {
                $fullPath = Join-Path $desktopPath $file
                try {
                    if (Test-Path $fullPath) {
                        Remove-Item $fullPath -Recurse -Force -ErrorAction Stop
                        Write-ActionLog "Removed from Desktop: $fullPath"
                    }
                } catch {
                    Write-ActionLog "Could not remove from Desktop: $fullPath - $($_.Exception.Message)"
                }
            }
        }
    }
}

<#
.SYNOPSIS
    Runs system maintenance to resolve potential installation issues
.DESCRIPTION
    Executes system commands to repair registry and file system issues
#>
function Invoke-SystemMaintenance {
    Write-ActionLog "Running system maintenance to resolve installation issues..."
    
    try {
        # Run System File Checker to repair any corrupted system files
        Write-ActionLog "Running System File Checker..."
        $sfcResult = & sfc /scannow 2>&1
        Write-ActionLog "SFC completed: $($sfcResult -join ' ')"
        
        # Run DISM to repair Windows image
        Write-ActionLog "Running DISM health check..."
        $dismResult = & dism /online /cleanup-image /restorehealth 2>&1
        Write-ActionLog "DISM completed: $($dismResult -join ' ')"
        
        # Clear Windows Update cache that might interfere
        Write-ActionLog "Clearing Windows Update cache..."
        Stop-Service "wuauserv" -Force -ErrorAction SilentlyContinue
        Remove-Item "$env:WINDIR\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
        Start-Service "wuauserv" -ErrorAction SilentlyContinue
        
        # Repair licensing components
        Repair-AutodeskLicensing
        
        Write-ActionLog "System maintenance completed"
        
    } catch {
        Write-ActionLog "System maintenance encountered issues: $($_.Exception.Message)"
    }
}

<#
.SYNOPSIS
    Repairs Autodesk licensing components to prevent "License Manager not functioning" errors
.DESCRIPTION
    Attempts to repair or reinstall licensing components using Windows built-in tools
#>
function Repair-AutodeskLicensing {
    Write-ActionLog "Attempting to repair Autodesk licensing components..."
    
    try {
        # Re-register licensing DLLs that might be needed
        $licensingDlls = @(
            "$env:WINDIR\System32\msvcr*.dll",
            "$env:WINDIR\System32\msvcp*.dll",
            "$env:WINDIR\SysWOW64\msvcr*.dll",
            "$env:WINDIR\SysWOW64\msvcp*.dll"
        )
        
        foreach ($dllPattern in $licensingDlls) {
            Get-Item $dllPattern -ErrorAction SilentlyContinue | ForEach-Object {
                try {
                    & regsvr32 /s $_.FullName
                    Write-ActionLog "Re-registered DLL: $($_.Name)"
                } catch {
                    Write-ActionLog "Could not register DLL: $($_.Name)"
                }
            }
        }
        
        # Reset Windows licensing and activation services
        Write-ActionLog "Resetting Windows licensing services..."
        $windowsLicensingServices = @('sppsvc', 'wlidsvc', 'LicenseManager')
        foreach ($service in $windowsLicensingServices) {
            try {
                Restart-Service $service -Force -ErrorAction SilentlyContinue
                Write-ActionLog "Restarted service: $service"
            } catch {
                Write-ActionLog "Could not restart service: $service"
            }
        }
        
        # Clear licensing cache directories
        Write-ActionLog "Clearing licensing cache..."
        $cachePaths = @(
            "$env:ALLUSERSPROFILE\Autodesk\ADLM\*",
            "$env:LOCALAPPDATA\Autodesk\ADLM\*",
            "$env:TEMP\*adlm*",
            "$env:TEMP\*flexnet*"
        )
        
        foreach ($cachePath in $cachePaths) {
            Get-Item $cachePath -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        }
        
        Write-ActionLog "Licensing repair completed"
        
    } catch {
        Write-ActionLog "Licensing repair encountered issues: $($_.Exception.Message)"
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Stop-AutodeskServices',
    'Uninstall-Product',
    'Backup-AddIns',
    'Clear-ProductData',
    'Clear-AutodeskSystemRemnants',
    'Clear-AutodeskLicensingComponents',
    'Invoke-SystemMaintenance',
    'Repair-AutodeskLicensing'
)
