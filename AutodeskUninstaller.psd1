@{
    RootModule = 'AutodeskUninstaller.psm1'
    ModuleVersion = '1.0.0'
    GUID = '12345678-1234-1234-1234-123456789012'
    Author = 'AutodeskUninstaller'
    CompanyName = 'Unknown'
    Copyright = '(c) 2025 AutodeskUninstaller. All rights reserved.'
    Description = 'Modular Autodesk Products Uninstaller with GUI interface'
    PowerShellVersion = '5.1'
    RequiredModules = @()
    RequiredAssemblies = @('System.Windows.Forms', 'System.Drawing')
    ScriptsToProcess = @()
    TypesToProcess = @()
    FormatsToProcess = @()
    NestedModules = @(
        'Modules\Config.psm1',
        'Modules\Logging.psm1',
        'Modules\ProductDetection.psm1',
        'Modules\GUI.psm1',
        'Modules\ProgressWindow.psm1',
        'Modules\UninstallOperations.psm1'
    )
    FunctionsToExport = @()
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    FileList = @(
        'AutodeskUninstaller.psd1',
        'AutodeskUninstaller.psm1',
        'Main.ps1',
        'README.md',
        'Modules\Config.psm1',
        'Modules\Logging.psm1',
        'Modules\ProductDetection.psm1',
        'Modules\GUI.psm1',
        'Modules\ProgressWindow.psm1',
        'Modules\UninstallOperations.psm1'
    )
    PrivateData = @{
        PSData = @{
            Tags = @('Autodesk', 'Uninstaller', 'GUI', 'CAD', 'BIM')
            LicenseUri = ''
            ProjectUri = ''
            IconUri = ''
            ReleaseNotes = 'Initial modular release of Autodesk Uninstaller'
        }
    }
}
