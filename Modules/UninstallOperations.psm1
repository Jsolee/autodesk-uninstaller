<#
.SYNOPSIS
    Optimized uninstall operations module for Autodesk Uninstaller
.DESCRIPTION
    Handles uninstallation, service management, and cleanup operations
    with improved performance and reinstallation safety
#>

# Import required types for process handling
Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    public class Win32 {
        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern bool TerminateProcess(IntPtr hProcess, uint uExitCode);
    }
"@

<#
.SYNOPSIS
    Stops Autodesk services and processes efficiently
.DESCRIPTION
    Stops services and kills processes in parallel for better performance
#>
function Stop-AutodeskServices {
    Write-ActionLog "Stopping Autodesk services and processes..."
    
    $config = Get-Config
    
    # Stop services sequentially (PowerShell 5.1 compatible)
    foreach ($serviceName in $config.AutodeskServices) {
        try {
            $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
            if ($service -and $service.Status -eq 'Running') {
                Stop-Service -Name $serviceName -Force -NoWait -ErrorAction SilentlyContinue
            }
        } catch { }
    }
    
    # Wait a moment for services to stop
    Start-Sleep -Milliseconds 500
    
    # Kill processes more efficiently
    $runningProcesses = Get-Process -ErrorAction SilentlyContinue | 
        Where-Object { $config.AutodeskProcesses -contains $_.ProcessName }
    
    foreach ($proc in $runningProcesses) {
        try {
            # Use TerminateProcess for faster termination without popups
            [Win32]::TerminateProcess($proc.Handle, 0) | Out-Null
            Write-ActionLog "Terminated process: $($proc.ProcessName)"
        } catch {
            # Fallback to Stop-Process if TerminateProcess fails
            try {
                Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
            } catch { }
        }
    }
    
    # Disable services to prevent restart
    $config.AutodeskServices | ForEach-Object {
        try {
            Set-Service -Name $_ -StartupType Disabled -ErrorAction SilentlyContinue
        } catch { }
    }
}

<#
.SYNOPSIS
    Uninstalls a specific Autodesk product silently
.DESCRIPTION
    Uninstalls a product using optimized methods to prevent popups
.PARAMETER Product
    The product object containing uninstall information
.OUTPUTS
    Boolean indicating success or failure
#>
function Uninstall-Product {
    param([PSCustomObject]$Product)
    
    # Define critical components that should never be uninstalled
    $criticalComponents = @(
        'Autodesk Identity Manager',
        'Generative Design for Revit',
        'Personal Accelerator for Revit'
    )
    
    # Skip critical components
    if ($criticalComponents -contains $Product.DisplayName) {
        Write-ActionLog "Skipping critical component: $($Product.DisplayName)"
        return $true
    }
    
    Write-ActionLog "Uninstalling: $($Product.DisplayName)"
    $exitCode = $null
    
    try {
        # Create a custom environment to suppress popups
        $env:SEE_MASK_NOZONECHECKS = 1
        $env:__COMPAT_LAYER = "RunAsInvoker"
        
        if ($Product.UninstallString -match '^(.*?Installer\.exe)(.*)$') {
            # ODIS installer
            $exePath = $matches[1].Trim('"')
            $argList = $matches[2].Trim()
            
            # Ensure silent uninstall
            if ($argList -notmatch '\b-i\s+uninstall\b') { 
                $argList = "-i uninstall $argList" 
            }
            if ($argList -notmatch '\b--silent\b') { 
                $argList += ' --silent' 
            }
            # Add no-prompt flag if supported
            if ($argList -notmatch '\b--no-prompt\b') {
                $argList += ' --no-prompt'
            }
            
            # Use Start-Process with specific window settings
            $processInfo = New-Object System.Diagnostics.ProcessStartInfo
            $processInfo.FileName = $exePath
            $processInfo.Arguments = $argList
            $processInfo.UseShellExecute = $false
            $processInfo.CreateNoWindow = $true
            $processInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
            $processInfo.RedirectStandardOutput = $true
            $processInfo.RedirectStandardError = $true
            
            $process = [System.Diagnostics.Process]::Start($processInfo)
            $process.WaitForExit()
            $exitCode = $process.ExitCode
            
        } elseif ($Product.UninstallString -match '/[IX]\s*\{([^\}]+)\}') {
            # MSI installer - use optimized parameters
            $guid = $Matches[1]
            $logPath = Get-LogPath
            
            # Use REBOOT=ReallySuppress to prevent restart prompts
            $argList = "/X{$guid} /qn REBOOT=ReallySuppress /norestart /l*v `"$logPath\MSI_$($Product.DisplayName -replace '[^\w]','_').log`""
            
            # Run msiexec with suppressed UI
            $processInfo = New-Object System.Diagnostics.ProcessStartInfo
            $processInfo.FileName = "msiexec.exe"
            $processInfo.Arguments = $argList
            $processInfo.UseShellExecute = $false
            $processInfo.CreateNoWindow = $true
            $processInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
            
            $process = [System.Diagnostics.Process]::Start($processInfo)
            $process.WaitForExit()
            $exitCode = $process.ExitCode
            
        } else {
            Write-ActionLog "Unknown uninstall method for $($Product.DisplayName)"
            return $false
        }
        
        # Success codes: 0 (success), 1605 (product not installed), 3010 (success, restart required)
        if ($exitCode -in @(0, 1605, 3010)) {
            Write-ActionLog "Successfully uninstalled: $($Product.DisplayName) (Exit code: $exitCode)"
            
            # Clean up registry entry immediately to prevent reinstall issues
            if ($Product.RegistryPath) {
                Remove-Item -Path $Product.RegistryPath -Force -ErrorAction SilentlyContinue
            }
            
            return $true
        } else {
            Write-ActionLog "Failed to uninstall: $($Product.DisplayName) (Exit code: $exitCode)"
            return $false
        }
        
    } catch {
        Write-ActionLog "Error uninstalling $($Product.DisplayName): $_"
        return $false
    } finally {
        # Restore environment
        Remove-Item Env:\SEE_MASK_NOZONECHECKS -ErrorAction SilentlyContinue
        Remove-Item Env:\__COMPAT_LAYER -ErrorAction SilentlyContinue
    }
}

<#
.SYNOPSIS
    Performs targeted cleanup to prevent reinstallation issues
.DESCRIPTION
    Cleans only necessary components in the correct order
#>
function Clear-AutodeskSystemRemnants {
    Write-ActionLog "Performing targeted system cleanup..."
    
    # Order is critical: Registry first, then files, then services
    
    # 1. Clean installation registry entries only
    Clear-InstallationRegistryEntries
    
    # 2. Clean orphaned installer files
    Clear-OrphanedInstallerFiles
    
    # 3. Clean only non-shared licensing components
    Clear-ProductSpecificLicensing
    
    # 4. Reset Windows Installer cache for Autodesk products only
    Clear-AutodeskInstallerCache
}

<#
.SYNOPSIS
    Cleans only installation-specific registry entries
.DESCRIPTION
    Removes registry entries that block reinstallation without affecting shared components
#>
function Clear-InstallationRegistryEntries {
    Write-ActionLog "Cleaning installation registry entries..."
    
    # Target only uninstall and product-specific keys
    $installRegPaths = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
        'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
    )
    
    foreach ($path in $installRegPaths) {
        if (Test-Path $path) {
            Get-ChildItem $path -ErrorAction SilentlyContinue | ForEach-Object {
                $props = Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue
                if ($props.Publisher -eq 'Autodesk' -and $props.DisplayName) {
                    # Only remove if it's a main product, not a shared component
                    if ($props.DisplayName -notmatch 'Shared|Runtime|Framework|Redistributable|Library') {
                        Remove-Item $_.PSPath -Force -ErrorAction SilentlyContinue
                        Write-ActionLog "Removed registry: $($props.DisplayName)"
                    }
                }
            }
        }
    }
    
    # Clean product-specific keys only
    $productRegPaths = @(
        'HKLM:\SOFTWARE\Autodesk\UPI2',
        'HKLM:\SOFTWARE\Wow6432Node\Autodesk\UPI2'
    )
    
    foreach ($regPath in $productRegPaths) {
        if (Test-Path $regPath) {
            Remove-Item $regPath -Recurse -Force -ErrorAction SilentlyContinue
            Write-ActionLog "Removed registry path: $regPath"
        }
    }
}

<#
.SYNOPSIS
    Cleans orphaned installer files efficiently
.DESCRIPTION
    Removes only installer files that are no longer needed
#>
function Clear-OrphanedInstallerFiles {
    Write-ActionLog "Cleaning orphaned installer files..."
    
    # Clean temp installer files
    $tempPaths = @(
        "$env:TEMP\Autodesk*",
        "$env:TEMP\*adsk*",
        "$env:LOCALAPPDATA\Temp\Autodesk*"
    )
    
    foreach ($tempPath in $tempPaths) {
        Get-Item $tempPath -ErrorAction SilentlyContinue | 
            Where-Object { $_.LastWriteTime -lt (Get-Date).AddHours(-1) } |
            Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    # Clean download cache
    $cachePath = "$env:LOCALAPPDATA\Autodesk\webdeploy\production"
    if (Test-Path $cachePath) {
        Remove-Item $cachePath -Recurse -Force -ErrorAction SilentlyContinue
        Write-ActionLog "Cleared Autodesk download cache"
    }
}

<#
.SYNOPSIS
    Cleans product-specific licensing without affecting shared components
.DESCRIPTION
    Removes only product-specific licensing files
#>
function Clear-ProductSpecificLicensing {
    Write-ActionLog "Cleaning product-specific licensing..."
    
    # Only clean product-specific licensing files, not shared FLEXnet
    $selectedProducts = Get-SelectedProducts
    
    # Check if we have selected products
    if (-not $selectedProducts -or $selectedProducts.Count -eq 0) {
        Write-ActionLog "No products selected for licensing cleanup"
        return
    }
    
    foreach ($product in $selectedProducts) {
        if (-not $product -or -not $product.DisplayName) { continue }
        
        $productName = $product.DisplayName -replace '[^\w]', ''
        
        # Product-specific licensing paths
        $licensePaths = @(
            "$env:LOCALAPPDATA\Autodesk\Adlm\$productName*",
            "$env:ALLUSERSPROFILE\Autodesk\Adlm\$productName*",
            "$env:APPDATA\Autodesk\Adlm\$productName*"
        )
        
        foreach ($path in $licensePaths) {
            Get-Item $path -ErrorAction SilentlyContinue |
                Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

<#
.SYNOPSIS
    Optimized Autodesk installer cache cleanup
.DESCRIPTION
    Cleans only Autodesk-related MSI files from installer cache
#>
function Clear-AutodeskInstallerCache {
    Write-ActionLog "Cleaning Autodesk installer cache..."
    
    # Get Autodesk product codes from registry first
    $productCodes = @()
    $uninstallPaths = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    
    foreach ($path in $uninstallPaths) {
        $autodeskProducts = @(Get-ItemProperty $path -ErrorAction SilentlyContinue | 
            Where-Object { $_.Publisher -eq 'Autodesk' })
        
        foreach ($product in $autodeskProducts) {
            if ($product.PSChildName -match '^\{[A-F0-9\-]+\}$') {
                $productCodes += $product.PSChildName
            }
        }
    }
    
    # Clean only MSI files for these product codes
    if ($productCodes -and $productCodes.Count -gt 0) {
        $msiPath = "$env:WINDIR\Installer"
        Get-ChildItem "$msiPath\*.msi" -ErrorAction SilentlyContinue | ForEach-Object {
            try {
                # Quick check if this MSI is for an Autodesk product
                $msiDb = New-Object -ComObject WindowsInstaller.Installer
                $db = $msiDb.OpenDatabase($_.FullName, 0)
                $view = $db.OpenView("SELECT Value FROM Property WHERE Property='ProductCode'")
                $view.Execute()
                $record = $view.Fetch()
                if ($record -and $productCodes -contains $record.StringData(1)) {
                    Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue
                    Write-ActionLog "Removed MSI cache: $($_.Name)"
                }
                [System.Runtime.Interopservices.Marshal]::ReleaseComObject($db) | Out-Null
                [System.Runtime.Interopservices.Marshal]::ReleaseComObject($msiDb) | Out-Null
            } catch {
                # Skip files we can't process
            }
        }
    }
}

<#
.SYNOPSIS
    Backs up add-ins with improved performance
.DESCRIPTION
    Creates selective backups of add-ins using robocopy for speed
#>
function Backup-AddIns {
    param([string]$ProductType)
    
    Write-ActionLog "Backing up add-ins for $ProductType..."
    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $config = Get-Config
    $backupPath = "$($config.AddInsBackupRootPath)\$timestamp"
    Set-AddInsBackupPath -value $backupPath
    
    [void](New-Item -ItemType Directory -Path $backupPath -Force)
    
    $addInPaths = $config.AddInPaths
    $backedUpCount = 0
    
    if ($addInPaths.ContainsKey($ProductType)) {
        # Get all user profiles
        $profiles = Get-UserProfiles
        
        foreach ($userProfile in $profiles) {
            $profilePath = $userProfile.ProfileImagePath
            $userName = Split-Path $profilePath -Leaf
            
            foreach ($location in @('AppData\Local', 'AppData\Roaming')) {
                foreach ($addInDef in $addInPaths[$ProductType]) {
                    $sourcePath = Join-Path $profilePath "$location$($addInDef.Path)"
                    
                    if (Test-Path $sourcePath) {
                        $destPath = Join-Path $backupPath "$userName\$location$($addInDef.Path)"
                        $destDir = Split-Path $destPath -Parent
                        [void](New-Item -ItemType Directory -Path $destDir -Force)
                        
                        # Use robocopy for faster copying with pattern matching
                        $robocopyArgs = @(
                            $sourcePath,
                            $destPath,
                            $addInDef.Pattern,
                            '/E',           # Copy subdirectories
                            '/XJ',          # Exclude junctions
                            '/R:1',         # Retry once
                            '/W:1',         # Wait 1 second between retries
                            '/NP',          # No progress
                            '/NS', '/NC', '/NFL', '/NDL'  # Minimal output
                        )
                        
                        $result = & robocopy @robocopyArgs 2>$null
                        if ($LASTEXITCODE -le 7) {  # Robocopy success codes
                            $backedUpCount++
                            Write-ActionLog "Backed up add-ins from: $sourcePath"
                        }
                    }
                }
            }
        }
    }
    
    Write-ActionLog "Backed up $backedUpCount add-in locations to: $backupPath"
    return $backedUpCount
}

<#
.SYNOPSIS
    Clears product data with improved selective deletion
.DESCRIPTION
    Removes product files while preserving shared components
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
            Get-Item $pathPattern -ErrorAction SilentlyContinue | ForEach-Object {
                # Check if this is a shared component directory
                $isShared = $false
                $sharedPatterns = @('Shared', 'Common Files', 'System', 'Framework')
                foreach ($pattern in $sharedPatterns) {
                    if ($_.FullName -match $pattern) {
                        $isShared = $true
                        break
                    }
                }
                
                if (-not $isShared) {
                    Remove-Item $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
                    Write-ActionLog "Removed: $($_.FullName)"
                } else {
                    Write-ActionLog "Preserved shared component: $($_.FullName)"
                }
            }
        }
    }
    
    # Clear user data with improved performance
    Clear-UserProductData -ProductType $ProductType -PreserveAddIns $PreserveAddIns
}

<#
.SYNOPSIS
    Clears user-specific product data efficiently
.DESCRIPTION
    Removes user data with parallel processing for better performance
#>
function Clear-UserProductData {
    param(
        [string]$ProductType,
        [bool]$PreserveAddIns
    )
    
    $profiles = Get-UserProfiles
    $config = Get-Config
    
    # Process profiles sequentially (PowerShell 5.1 compatible)
    foreach ($profile in $profiles) {
        $profilePath = $profile.ProfileImagePath
        
        foreach ($appData in @('AppData\Local\Autodesk', 'AppData\Roaming\Autodesk')) {
            $basePath = Join-Path $profilePath $appData
            
            if (Test-Path $basePath) {
                if (-not $PreserveAddIns) {
                    # Fast deletion of entire directory
                    Remove-Item $basePath -Recurse -Force -ErrorAction SilentlyContinue
                } else {
                    # Selective deletion preserving add-ins
                    Get-ChildItem $basePath -Recurse -File | ForEach-Object {
                        $shouldPreserve = $false
                        foreach ($pattern in $config.PreservePaths) {
                            if ($_.FullName -like $pattern) {
                                $shouldPreserve = $true
                                break
                            }
                        }
                        if (-not $shouldPreserve) {
                            Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue
                        }
                    }
                    
                    # Clean empty directories
                    Get-ChildItem $basePath -Recurse -Directory -ErrorAction SilentlyContinue | 
                        Sort-Object -Property FullName -Descending |
                        Where-Object { 
                            $children = Get-ChildItem $_.FullName -Force -ErrorAction SilentlyContinue
                            (-not $children) -or ($children.Count -eq 0)
                        } |
                        Remove-Item -Force -ErrorAction SilentlyContinue
                }
            }
        }
        
        # Clean desktop shortcuts
        $desktopPath = Join-Path $profilePath "Desktop"
        if (Test-Path $desktopPath) {
            Get-ChildItem $desktopPath -Filter "*Autodesk*" -ErrorAction SilentlyContinue |
                Remove-Item -Force -ErrorAction SilentlyContinue
        }
    }
}

<#
.SYNOPSIS
    Gets user profiles excluding system accounts
.DESCRIPTION
    Retrieves user profiles more efficiently
#>
function Get-UserProfiles {
    return Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*' | 
           Where-Object { 
               $_.PSObject.Properties.Name -contains 'ProfileImagePath' -and 
               $_.ProfileImagePath -and
               $_.ProfileImagePath -notmatch 'systemprofile|LocalService|NetworkService' -and
               (Test-Path $_.ProfileImagePath)
           }
}

# Export functions
Export-ModuleMember -Function @(
    'Stop-AutodeskServices',
    'Uninstall-Product',
    'Backup-AddIns',
    'Clear-ProductData',
    'Clear-AutodeskSystemRemnants',
    'Get-UserProfiles'
)