# AutodeskUninstaller Root Module
# This module serves as the entry point for the Autodesk Uninstaller

# Get the module root path
$ModuleRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

# Import all nested modules
$NestedModules = @(
    'Config.psm1',
    'Logging.psm1',
    'ProductDetection.psm1',
    'GUI.psm1',
    'ProgressWindow.psm1',
    'UninstallOperations.psm1'
)

foreach ($Module in $NestedModules) {
    $ModulePath = Join-Path $ModuleRoot "Modules\$Module"
    if (Test-Path $ModulePath) {
        Import-Module $ModulePath -Force
    }
}

# Export no functions - this module is for internal use only
Export-ModuleMember -Function @()
