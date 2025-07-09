<#
.SYNOPSIS
    Configuration module for Autodesk Uninstaller
.DESCRIPTION
    Contains global variables and configuration settings
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
    AutodeskServices = @('GenuineService', 'AdskLicensingService', 'AdAppMgrSvc', 'FNPLicensingService')
    AutodeskProcesses = @('message_router', 'GenuineService', 'AdSSO', 'AdskAccessServiceHost')
    RegistryHives = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
        'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
    )
    ProductPaths = @{
        'Revit' = @(
            'C:\Program Files\Autodesk\Revit*',
            'C:\ProgramData\Autodesk\RVT*',
            'C:\Program Files\NREL\OpenStudio CLI For Revit*'
        )
        'AutoCAD' = @(
            'C:\Program Files\Autodesk\AutoCAD*',
            'C:\ProgramData\Autodesk\AutoCAD*'
        )
        '3dsMax' = @(
            'C:\Program Files\Autodesk\3ds Max*',
            'C:\ProgramData\Autodesk\3dsMax*'
        )
        'DesktopConnector' = @(
            'C:\Program Files\Autodesk\Desktop Connector',
            'C:\ProgramData\Autodesk\Desktop Connector'
        )
    }
    AddInPaths = @{
        'Revit' = @(
            @{ Path = '\Autodesk\Revit\Addins'; Pattern = '*' },
            @{ Path = '\Autodesk\ApplicationPlugins'; Pattern = '*Revit*' }
        )
        'AutoCAD' = @(
            @{ Path = '\Autodesk\AutoCAD\*\Support'; Pattern = '*' },
            @{ Path = '\Autodesk\ApplicationPlugins'; Pattern = '*AutoCAD*' }
        )
        '3dsMax' = @(
            @{ Path = '\Autodesk\3dsMax\*\plugins'; Pattern = '*' },
            @{ Path = '\Autodesk\ApplicationPlugins'; Pattern = '*3dsMax*' }
        )
    }
    PreservePaths = @(
        '*\Addins\*',
        '*\ApplicationPlugins\*',
        '*\plugins\*',
        '*\Support\*.lsp',
        '*\Support\*.fas',
        '*\Support\*.vlx'
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
