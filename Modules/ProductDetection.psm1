<#
.SYNOPSIS
    Optimized product detection module for Autodesk Uninstaller
.DESCRIPTION
    Handles fast detection and categorization of Autodesk products
#>

<#
.SYNOPSIS
    Detects all Autodesk products installed on the system efficiently
.DESCRIPTION
    Scans the Windows registry for Autodesk products using optimized queries
.OUTPUTS
    Array of PSCustomObject containing product information
#>
function Get-AutodeskProducts {
    Write-ActionLog "Scanning for Autodesk products..."
    
    $config = Get-Config
    $hives = $config.RegistryHives
    
    # Define critical components that should never be uninstalled
    $criticalComponents = @(
        'Autodesk Identity Manager',
        'Generative Design for Revit',
        'Personal Accelerator for Revit'
    )
    
    # Use hashtable for faster lookups and grouping
    $productGroups = @{}
    
    # Scan registry sequentially (PowerShell 5.1 compatible)
    $products = foreach ($hive in $hives) {
        Get-ChildItem -Path $hive -ErrorAction SilentlyContinue | ForEach-Object {
            $key = $_
            $props = Get-ItemProperty -Path $key.PSPath -ErrorAction SilentlyContinue
            
            if (-not $props) { return }
            
            # Quick check for Autodesk publisher
            if ($props.Publisher -ne 'Autodesk') { return }
            
            # Must have display name
            if (-not $props.DisplayName) { return }
            
            # Skip critical components that should never be uninstalled
            if ($criticalComponents -contains $props.DisplayName) {
                Write-ActionLog "Skipping critical component: $($props.DisplayName)"
                return
            }
            
            # Skip updates, patches, and components
            if ($props.DisplayName -match 'Update|Patch|Hotfix|Fix|Service Pack|Component|Runtime|Framework|Library|Redistributable') { 
                return 
            }
            
            # Skip language packs
            if ($props.DisplayName -match 'Language Pack|LP |MUI') { return }
            
            # Get uninstall string
            $uninstallString = $props.QuietUninstallString
            if (-not $uninstallString -and $props.UninstallString) {
                $uninstallString = $props.UninstallString
            }
            
            # Skip PowerShell uninstallers
            if ($uninstallString -match '\.ps1(\s|$)') { return            }
            
            # Skip if no valid uninstall method
            if (-not $uninstallString) { return }
            
            # Determine main product group
            $mainProduct = Get-MainProductName -DisplayName $props.DisplayName
            
            # Create product object
            $productObj = [PSCustomObject]@{
                DisplayName = $props.DisplayName
                DisplayVersion = if ($props.DisplayVersion) { $props.DisplayVersion } else { '' }
                ProductType = Get-ProductType -DisplayName $props.DisplayName
                UninstallString = $uninstallString
                RegistryPath = $key.PSPath
                InstallDate = if ($props.InstallDate) { $props.InstallDate } else { '' }
                EstimatedSize = if ($props.EstimatedSize) { $props.EstimatedSize } else { 0 }
                ProductCode = if ($key.PSChildName -match '^\{[A-F0-9\-]+\}$') { $key.PSChildName } else { '' }
                MainProduct = $mainProduct
            }
            
            # Group products by main product name
            if (-not $productGroups.ContainsKey($mainProduct)) {
                $productGroups[$mainProduct] = @()
            }
            $productGroups[$mainProduct] += $productObj
            
            return $productObj
        }
    }
    
    # Create simplified main product groups for user selection
    $mainProducts = @()
    foreach ($mainProductName in $productGroups.Keys) {
        $components = $productGroups[$mainProductName]
        $mainComponent = $components | Where-Object { $_.DisplayName -like "*$mainProductName*" -and $_.DisplayName -notlike "*Add-in*" -and $_.DisplayName -notlike "*Plugin*" } | Select-Object -First 1
        
        if (-not $mainComponent) {
            $mainComponent = $components | Select-Object -First 1
        }
        
        # Create a main product entry that represents all components
        $mainProducts += [PSCustomObject]@{
            DisplayName = $mainProductName
            DisplayVersion = $mainComponent.DisplayVersion
            ProductType = $mainComponent.ProductType
            Components = $components
            ComponentCount = $components.Count
        }
    }
    
    $productCount = $mainProducts.Count
    Write-ActionLog "Found $productCount main Autodesk product group(s)"
    
    # Log the components for each main product
    foreach ($product in $mainProducts) {
        Write-ActionLog "  $($product.DisplayName): $($product.ComponentCount) components"
    }
    
    return $mainProducts | Sort-Object DisplayName
}

<#
.SYNOPSIS
    Determines the main product name from a component display name
.DESCRIPTION
    Groups related components under a main product name
.PARAMETER DisplayName
    The display name of the component
.OUTPUTS
    String representing the main product name
#>
function Get-MainProductName {
    param([string]$DisplayName)
    
    # Define main product patterns
    switch -Regex ($DisplayName) {
        'Revit 20\d{2}' { 
            if ($DisplayName -match 'Revit (20\d{2})') {
                return "Revit $($matches[1])"
            }
            return 'Revit'
        }
        'AutoCAD 20\d{2}(?!.*Civil)' { 
            if ($DisplayName -match 'AutoCAD (20\d{2})') {
                return "AutoCAD $($matches[1])"
            }
            return 'AutoCAD'
        }
        'Civil 3D 20\d{2}' { 
            if ($DisplayName -match 'Civil 3D (20\d{2})') {
                return "Civil 3D $($matches[1])"
            }
            return 'Civil 3D'
        }
        'Inventor 20\d{2}' { 
            if ($DisplayName -match 'Inventor (20\d{2})') {
                return "Inventor $($matches[1])"
            }
            return 'Inventor'
        }
        '3ds Max 20\d{2}' { 
            if ($DisplayName -match '3ds Max (20\d{2})') {
                return "3ds Max $($matches[1])"
            }
            return '3ds Max'
        }
        'Maya 20\d{2}' { 
            if ($DisplayName -match 'Maya (20\d{2})') {
                return "Maya $($matches[1])"
            }
            return 'Maya'
        }
        'Fusion 360' { return 'Fusion 360' }
        'Navisworks' { 
            if ($DisplayName -match 'Navisworks.*20\d{2}') {
                return "Navisworks $($matches[1])"
            }
            return 'Navisworks'
        }
        'Robot Structural Analysis' { return 'Robot Structural Analysis' }
        'Advance Steel' { return 'Advance Steel' }
        'Desktop Connector' { return 'Desktop Connector' }
        default { 
            # For other products, try to extract year and base name
            if ($DisplayName -match '^(.+?)\s+(20\d{2})') {
                return "$($matches[1]) $($matches[2])"
            } else {
                return $DisplayName
            }
        }
    }
}

<#
.SYNOPSIS
    Categorizes a product based on its display name
.DESCRIPTION
    Determines the product type category with improved matching
.PARAMETER DisplayName
    The display name of the product
.OUTPUTS
    String representing the product type category
#>
function Get-ProductType {
    param([string]$DisplayName)
    
    # Use switch for better performance
    switch -Regex ($DisplayName) {
        'Revit' { return 'Revit' }
        'AutoCAD(?!.*Civil)' { return 'AutoCAD' }  # AutoCAD but not Civil 3D
        'Civil 3D|C3D' { return 'Civil3D' }
        '3ds Max|3dsMax' { return '3dsMax' }
        'Maya' { return 'Maya' }
        'Inventor' { return 'Inventor' }
        'Desktop Connector' { return 'DesktopConnector' }
        'Navisworks' { return 'Navisworks' }
        'Fusion' { return 'Fusion' }
        'Vault' { return 'Vault' }
        'BIM 360|BIM360' { return 'BIM360' }
        'Advance Steel' { return 'AdvanceSteel' }
        'Robot Structural' { return 'Robot' }
        'FormIt' { return 'FormIt' }
        'InfraWorks' { return 'InfraWorks' }
        'ReCap' { return 'ReCap' }
        'Mudbox' { return 'Mudbox' }
        'MotionBuilder' { return 'MotionBuilder' }
        'Arnold' { return 'Arnold' }
        'SketchBook' { return 'SketchBook' }
        'Dynamo' { return 'Dynamo' }
        'Material Library' { return 'MaterialLibrary' }
        'Content' { return 'Content' }
        default { return 'Other' }
    }
}

<#
.SYNOPSIS
    Gets product installation dependencies
.DESCRIPTION
    Determines if a product depends on others for proper uninstall order
.PARAMETER Product
    The product to check dependencies for
.OUTPUTS
    Integer representing dependency level (lower = uninstall first)
#>
function Get-ProductDependencyLevel {
    param([PSCustomObject]$Product)
    
    # Products that should be uninstalled first (lower number = higher priority)
    switch -Wildcard ($Product.DisplayName) {
        # Add-ins and plugins - uninstall first
        "*Add-in*" { return 1 }
        "*Plugin*" { return 1 }
        "*Extension*" { return 1 }
        "*Tools for*" { return 1 }
        
        # Content and libraries
        "*Content*" { return 2 }
        "*Library*" { return 2 }
        "*Templates*" { return 2 }
        
        # Supporting applications
        "Desktop Connector" { return 3 }
        "*Vault*" { return 3 }
        "*BIM 360*" { return 3 }
        
        # Secondary products
        "*Dynamo*" { return 4 }
        "*FormIt*" { return 4 }
        "*ReCap*" { return 4 }
        
        # Main products
        default { return 5 }
    }
}

<#
.SYNOPSIS
    Estimates uninstallation time for a product
.DESCRIPTION
    Provides time estimate based on product type and size
.PARAMETER Product
    The product to estimate time for
.OUTPUTS
    Integer representing estimated seconds
#>
function Get-UninstallTimeEstimate {
    param([PSCustomObject]$Product)
    
    # Base time on product type
    $baseTime = switch ($Product.ProductType) {
        'Revit' { 120 }
        'AutoCAD' { 90 }
        'Civil3D' { 120 }
        '3dsMax' { 100 }
        'Maya' { 100 }
        'Inventor' { 110 }
        'DesktopConnector' { 30 }
        default { 60 }
    }
    
    # Adjust based on size (if available)
    if ($Product.EstimatedSize -gt 0) {
        # Size is in KB, add 1 second per 100MB
        $sizeAdjustment = [Math]::Round($Product.EstimatedSize / 102400)
        $baseTime += $sizeAdjustment
    }
    
    return $baseTime
}

# Export functions
Export-ModuleMember -Function @(
    'Get-AutodeskProducts',
    'Get-ProductType',
    'Get-ProductDependencyLevel',
    'Get-UninstallTimeEstimate'
)