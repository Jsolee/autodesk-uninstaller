<#
.SYNOPSIS
    Product detection module for Autodesk Uninstaller
.DESCRIPTION
    Handles detection and categorization of Autodesk products installed on the system
#>

<#
.SYNOPSIS
    Detects all Autodesk products installed on the system
.DESCRIPTION
    Scans the Windows registry for Autodesk products and categorizes them
.OUTPUTS
    Array of PSCustomObject containing product information
#>
function Get-AutodeskProducts {
    Write-ActionLog "Scanning for Autodesk products..."
    
    $config = Get-Config
    $hives = $config.RegistryHives
    
    $products = @()
    foreach ($hive in $hives) {
        foreach ($key in Get-ChildItem -Path $hive -ErrorAction SilentlyContinue) {
            $props = Get-ItemProperty -Path $key.PSPath -ErrorAction SilentlyContinue
            if (-not $props) { continue }
            
            $publisher = $null
            if ($props.PSObject.Properties.Name -contains 'Publisher') {
                $publisher = $props.Publisher
            }
            
            if ($publisher -ne 'Autodesk') { continue }
            
            $displayName = $null
            if ($props.PSObject.Properties.Name -contains 'DisplayName') {
                $displayName = $props.DisplayName
            }
            
            if (-not $displayName) { continue }
            
            # Skip updates and patches
            if ($displayName -match 'Update|Patch|Hotfix|Fix|Service Pack') { continue }
            
            $displayVersion = ''
            if ($props.PSObject.Properties.Name -contains 'DisplayVersion') {
                $displayVersion = $props.DisplayVersion
            }
            
            $uninstallString = $null
            if ($props.PSObject.Properties.Name -contains 'QuietUninstallString') {
                $uninstallString = $props.QuietUninstallString
            } elseif ($props.PSObject.Properties.Name -contains 'UninstallString') {
                $uninstallString = $props.UninstallString
            }
            
            # Skip PowerShell uninstallers
            if ($uninstallString -match '\.ps1(\s|$)') { continue }
            
            # Categorize product
            $productType = Get-ProductType -DisplayName $displayName
            
            $products += [PSCustomObject]@{
                DisplayName = $displayName
                DisplayVersion = $displayVersion
                ProductType = $productType
                UninstallString = $uninstallString
                RegistryPath = $key.PSPath
            }
        }
    }
    
    Write-ActionLog "Found $($products.Count) Autodesk product(s)"
    return $products | Sort-Object ProductType, DisplayName
}

<#
.SYNOPSIS
    Categorizes a product based on its display name
.DESCRIPTION
    Determines the product type category based on the display name
.PARAMETER DisplayName
    The display name of the product
.OUTPUTS
    String representing the product type category
#>
function Get-ProductType {
    param([string]$DisplayName)
    
    $productType = 'Other'
    if ($DisplayName -match 'Revit') { $productType = 'Revit' }
    elseif ($DisplayName -match 'AutoCAD') { $productType = 'AutoCAD' }
    elseif ($DisplayName -match '3ds Max') { $productType = '3dsMax' }
    elseif ($DisplayName -match 'Maya') { $productType = 'Maya' }
    elseif ($DisplayName -match 'Inventor') { $productType = 'Inventor' }
    elseif ($DisplayName -match 'Desktop Connector') { $productType = 'DesktopConnector' }
    elseif ($DisplayName -match 'Navisworks') { $productType = 'Navisworks' }
    elseif ($DisplayName -match 'Civil 3D') { $productType = 'Civil3D' }
    elseif ($DisplayName -match 'Fusion') { $productType = 'Fusion' }
    
    return $productType
}

# Export functions
Export-ModuleMember -Function @(
    'Get-AutodeskProducts',
    'Get-ProductType'
)
