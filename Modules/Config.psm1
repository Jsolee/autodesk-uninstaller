<#
.SYNOPSIS
    Optimized configuration module for Autodesk Uninstaller
.DESCRIPTION
    Contains global variables and configuration settings optimized for
    fast, error-free uninstallation and reinstallation
#>

# Global variables
$script:SelectedProducts = @()
$script:UninstallMode = $null
$script:LogPath = $null
$script:ActionLog = $null
$script:TranscriptLog = $null
$script:AddInsBackupPath = $null
$script:ProgressForm = $null
$script:ProgressLabel = $null
$script:ProgressBar = $null

# Configuration constants
$script:Config = @{
    LogRootPath = "C:\Temp\AutodeskUninstaller"
    AddInsBackupRootPath = "C:\Temp\AutodeskAddInsBackup"
    
    # Services - only stop/disable those that are truly product-specific
    AutodeskServices = @(
        'AdAppMgrSvc',           # Autodesk Application Manager
        'AdskLicensingService',  # Autodesk Licensing Service
        'Autodesk Content Service' # Content service
        # Removed: GenuineService, FNPLicensingService - these are shared
    )
    
    # Processes - only kill those that block uninstallation
    AutodeskProcesses = @(
        'AdAppMgrSvc',
        'AdskAccessServiceHost', 
        'Autodesk Desktop App',
        'AdskIdentityManager',
        'message_router'
        # Removed: licensing processes that might be used by other software
    )
    
    # Registry hives for product detection
    RegistryHives = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
        'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
    )
    
    # Product-specific paths only (not shared components)
    ProductPaths = @{
        'Revit' = @(
            'C:\Program Files\Autodesk\Revit 20*',  # Version-specific
            'C:\ProgramData\Autodesk\RVT 20*'       # Version-specific data
        )
        'AutoCAD' = @(
            'C:\Program Files\Autodesk\AutoCAD 20*',
            'C:\ProgramData\Autodesk\AutoCAD 20*'
        )
        '3dsMax' = @(
            'C:\Program Files\Autodesk\3ds Max 20*',
            'C:\ProgramData\Autodesk\3dsMax 20*'
        )
        'Maya' = @(
            'C:\Program Files\Autodesk\Maya20*',
            'C:\ProgramData\Autodesk\Maya20*'
        )
        'Inventor' = @(
            'C:\Program Files\Autodesk\Inventor 20*',
            'C:\ProgramData\Autodesk\Inventor 20*'
        )
        'DesktopConnector' = @(
            'C:\Program Files\Autodesk\Desktop Connector'
        )
        'Navisworks' = @(
            'C:\Program Files\Autodesk\Navisworks * 20*',
            'C:\ProgramData\Autodesk\Navisworks * 20*'
        )
        'Civil3D' = @(
            'C:\Program Files\Autodesk\AutoCAD 20*',  # Civil 3D is AutoCAD-based
            'C:\ProgramData\Autodesk\C3D 20*'
        )
        'Fusion' = @(
            "$env:LOCALAPPDATA\Autodesk\webdeploy\production\*fusion*"
        )
    }
    
    # Add-in paths - comprehensive list for proper backup
    AddInPaths = @{
        'Revit' = @(
            @{ Path = '\Autodesk\Revit\Addins'; Pattern = '*' },
            @{ Path = '\Autodesk\ApplicationPlugins'; Pattern = '*Revit*' },
            @{ Path = '\ModPlus\Revit'; Pattern = '*' },
            @{ Path = '\Autodesk\Revit\Macros'; Pattern = '*' }
        )
        'AutoCAD' = @(
            @{ Path = '\Autodesk\AutoCAD\R*\enu\Support'; Pattern = '*' },
            @{ Path = '\Autodesk\ApplicationPlugins'; Pattern = '*AutoCAD*' },
            @{ Path = '\Autodesk\AutoCAD\R*\enu\Express'; Pattern = '*' }
        )
        '3dsMax' = @(
            @{ Path = '\Autodesk\3dsMax\20*\plugins'; Pattern = '*' },
            @{ Path = '\Autodesk\3dsMax\20*\scripts'; Pattern = '*' },
            @{ Path = '\Autodesk\ApplicationPlugins'; Pattern = '*3dsMax*' }
        )
        'Maya' = @(
            @{ Path = '\Autodesk\maya\20*\scripts'; Pattern = '*' },
            @{ Path = '\Autodesk\maya\20*\plug-ins'; Pattern = '*' },
            @{ Path = '\Autodesk\ApplicationPlugins'; Pattern = '*Maya*' }
        )
    }
    
    # Paths to preserve during cleanup
    PreservePaths = @(
        # Add-in and plugin directories
        '*\Addins\*',
        '*\ApplicationPlugins\*',
        '*\plugins\*',
        '*\plug-ins\*',
        '*\scripts\*',
        '*\Macros\*',
        '*\Express\*',
        # Support files
        '*\Support\*.lsp',
        '*\Support\*.fas',
        '*\Support\*.vlx',
        '*\Support\*.cui*',
        '*\Support\*.mnl',
        '*\Support\*.pat',
        '*\Support\*.lin',
        '*\Support\*.shx',
        '*\Support\*.ctb',
        '*\Support\*.stb',
        '*\Support\*.pc3',
        '*\Support\*.pmp',
        # User configurations
        '*\*.arg',
        '*\user.config',
        '*\Settings\*.xml'
    )
    
    # Minimal set of registry cleanup paths (product-specific only)
    RegistryCleanupPaths = @(
        'HKLM:\SOFTWARE\Autodesk\UPI2',
        'HKLM:\SOFTWARE\Wow6432Node\Autodesk\UPI2',
        'HKCU:\SOFTWARE\Autodesk\UPI2'
        # Removed shared licensing and system paths
    )
    
    # Shared components to never delete
    SharedComponents = @(
        '*\Common Files\*',
        '*\Shared\*',
        '*\System\*',
        '*\Framework\*',
        '*\Runtime\*',
        '*\Redistributable\*',
        '*\Library\*',
        '*FLEXnet*',
        '*\Microsoft*'
    )
}

# Getters and setters for global variables
function Get-SelectedProducts { return $script:SelectedProducts }
function Set-SelectedProducts { param($value) $script:SelectedProducts = $value }

function Get-UninstallMode { return $script:UninstallMode }
function Set-UninstallMode { param($value) $script:UninstallMode = $value }

function Get-LogPath { return $script:LogPath }
function Set-LogPath { param($value) $script:LogPath = $value }

function Get-ActionLog { return $script:ActionLog }
function Set-ActionLog { param($value) $script:ActionLog = $value }

function Get-TranscriptLog { return $script:TranscriptLog }
function Set-TranscriptLog { param($value) $script:TranscriptLog = $value }

function Get-AddInsBackupPath { return $script:AddInsBackupPath }
function Set-AddInsBackupPath { param($value) $script:AddInsBackupPath = $value }

function Get-ProgressForm { return $script:ProgressForm }
function Set-ProgressForm { param($value) $script:ProgressForm = $value }

function Get-ProgressLabel { return $script:ProgressLabel }
function Set-ProgressLabel { param($value) $script:ProgressLabel = $value }

function Get-ProgressBar { return $script:ProgressBar }
function Set-ProgressBar { param($value) $script:ProgressBar = $value }

function Get-Config { return $script:Config }

# Export functions
Export-ModuleMember -Function @(
    'Get-SelectedProducts', 'Set-SelectedProducts',
    'Get-UninstallMode', 'Set-UninstallMode',
    'Get-LogPath', 'Set-LogPath',
    'Get-ActionLog', 'Set-ActionLog',
    'Get-TranscriptLog', 'Set-TranscriptLog',
    'Get-AddInsBackupPath', 'Set-AddInsBackupPath',
    'Get-ProgressForm', 'Set-ProgressForm',
    'Get-ProgressLabel', 'Set-ProgressLabel',
    'Get-ProgressBar', 'Set-ProgressBar',
    'Get-Config'
)