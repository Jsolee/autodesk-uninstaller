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
    }
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

# Export functions
Export-ModuleMember -Function @(
    'Stop-AutodeskServices',
    'Uninstall-Product',
    'Backup-AddIns',
    'Clear-ProductData'
)
