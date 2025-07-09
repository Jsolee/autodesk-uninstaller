<#  ---------------------------------------------------------------------------
    Autodesk Products — GUI Uninstaller with selective cleanup
    File   :  Main.ps1
    Updated: 2025‑01‑08
    Usage  :  powershell.exe -ExecutionPolicy Bypass -File .\Main.ps1
    Features:
      - GUI interface for product selection
      - Detects all Autodesk products
      - Choice between full uninstall and reinstall preparation
      - Preserves add-ins for reinstallation scenario
      - Detailed logging of all operations
      - Modular architecture for easy maintenance
--------------------------------------------------------------------------- #>

# Load required assemblies first
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Host "Starting Autodesk Uninstaller..." -ForegroundColor Cyan

# Get the script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ModulesDir = Join-Path $ScriptDir "Modules"

Write-Host "Script Directory: $ScriptDir" -ForegroundColor Yellow
Write-Host "Modules Directory: $ModulesDir" -ForegroundColor Yellow

# Verify modules directory exists
if (-not (Test-Path $ModulesDir)) {
    Write-Error "Modules directory not found at: $ModulesDir"
    exit 1
}

# Import all required modules with error handling
$RequiredModules = @(
    'Config.psm1',          # Must be first - contains global variables
    'Logging.psm1',
    'ProductDetection.psm1',
    'ProgressWindow.psm1',
    'UninstallOperations.psm1',
    'GUI.psm1'              # GUI last as it may depend on others
)

foreach ($ModuleName in $RequiredModules) {
    $ModulePath = Join-Path $ModulesDir $ModuleName
    if (Test-Path $ModulePath) {
        try {
            Import-Module -Name $ModulePath -Force -ErrorAction Stop
            Write-Host "Successfully imported: $ModuleName" -ForegroundColor Green
        } catch {
            Write-Error "Failed to import module $ModuleName : $_"
            exit 1
        }
    } else {
        Write-Error "Module not found: $ModulePath"
        exit 1
    }
}

# Verify critical functions are available
$CriticalFunctions = @('Initialize-Logging', 'Get-Config', 'Get-AutodeskProducts')
foreach ($FunctionName in $CriticalFunctions) {
    if (-not (Get-Command $FunctionName -ErrorAction SilentlyContinue)) {
        Write-Error "Critical function '$FunctionName' not found after module import"
        exit 1
    }
}
Write-Host "All critical functions verified" -ForegroundColor Green

<#
.SYNOPSIS
    Checks if the script is running with administrator privileges
.DESCRIPTION
    Verifies administrator privileges and shows elevation dialog if needed
.OUTPUTS
    Boolean indicating if running as administrator
#>
function Test-AdministratorPrivileges {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal $identity
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

<#
.SYNOPSIS
    Shows an elevation required dialog
.DESCRIPTION
    Displays a dialog informing the user that administrator privileges are required
#>
function Show-ElevationDialog {
    [System.Windows.Forms.Application]::EnableVisualStyles()
    
    $elevationForm = New-Object System.Windows.Forms.Form
    $elevationForm.Text = "Administrator Privileges Required"
    $elevationForm.Size = New-Object System.Drawing.Size(420, 200)
    $elevationForm.StartPosition = "CenterScreen"
    $elevationForm.FormBorderStyle = 'FixedSingle'
    $elevationForm.MaximizeBox = $false
    $elevationForm.BackColor = [System.Drawing.Color]::White
    
    $lockIcon = New-Object System.Windows.Forms.Label
    $lockIcon.Text = [char]::ConvertFromUtf32(0x1F512)  # Lock emoji
    $lockIcon.Font = New-Object System.Drawing.Font("Segoe UI Emoji", 32)
    $lockIcon.Location = New-Object System.Drawing.Point(175, 20)
    $lockIcon.Size = New-Object System.Drawing.Size(70, 50)
    $lockIcon.TextAlign = 'MiddleCenter'
    $elevationForm.Controls.Add($lockIcon)
    
    $msgLabel = New-Object System.Windows.Forms.Label
    $msgLabel.Text = "This application requires administrator privileges.`nPlease run as administrator."
    $msgLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $msgLabel.Location = New-Object System.Drawing.Point(40, 80)
    $msgLabel.Size = New-Object System.Drawing.Size(340, 40)
    $msgLabel.TextAlign = 'MiddleCenter'
    $elevationForm.Controls.Add($msgLabel)
    
    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Text = "OK"
    $okButton.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $okButton.Location = New-Object System.Drawing.Point(160, 130)
    $okButton.Size = New-Object System.Drawing.Size(100, 32)
    $okButton.FlatStyle = 'Flat'
    $okButton.FlatAppearance.BorderSize = 0
    $okButton.BackColor = [System.Drawing.Color]::FromArgb(0, 122, 255)
    $okButton.ForeColor = [System.Drawing.Color]::White
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $elevationForm.Controls.Add($okButton)
    
    [void]$elevationForm.ShowDialog()
}

<#
.SYNOPSIS
    Processes the uninstallation workflow
.DESCRIPTION
    Handles the main uninstallation process including services, backup, and cleanup
.OUTPUTS
    Hashtable containing success and failure counts
#>
function Invoke-UninstallationProcess {
    $selectedProducts = Get-SelectedProducts
    $uninstallMode = Get-UninstallMode
    
    # Stop services
    Show-ProgressWindow -Title "Autodesk Uninstaller" -Status "Stopping Autodesk services..." -PercentComplete 5
    Stop-AutodeskServices
    
    # Backup add-ins if reinstall mode
    if ($uninstallMode -eq 'Reinstall') {
        Show-ProgressWindow -Title "Autodesk Uninstaller" -Status "Backing up add-ins..." -PercentComplete 10
        
        $productTypes = $selectedProducts.ProductType | Select-Object -Unique
        foreach ($type in $productTypes) {
            Backup-AddIns -ProductType $type
        }
    }
    
    # Uninstall products
    $totalProducts = $selectedProducts.Count
    $currentProduct = 0
    $successCount = 0
    $failCount = 0
    
    foreach ($product in $selectedProducts) {
        $currentProduct++
        $percentComplete = 15 + (($currentProduct / $totalProducts) * 70)
        
        Show-ProgressWindow -Title "Autodesk Uninstaller" `
                           -Status "Uninstalling $($product.DisplayName)... ($currentProduct of $totalProducts)" `
                           -PercentComplete $percentComplete
        
        if (Uninstall-Product -Product $product) {
            $successCount++
        } else {
            $failCount++
        }
    }
    
    # Cleanup
    Show-ProgressWindow -Title "Autodesk Uninstaller" -Status "Cleaning up..." -PercentComplete 90
    
    $productTypes = $selectedProducts.ProductType | Select-Object -Unique
    foreach ($type in $productTypes) {
        Clear-ProductData -ProductType $type -PreserveAddIns ($uninstallMode -eq 'Reinstall')
    }
    
    Close-ProgressWindow
    
    return @{
        Success = $successCount
        Failed = $failCount
    }
}

<#
.SYNOPSIS
    Main entry point for the Autodesk Uninstaller
.DESCRIPTION
    Orchestrates the entire uninstallation process from start to finish
#>
function Main {
    # Check administrator privileges
    if (-not (Test-AdministratorPrivileges)) {
        Show-ElevationDialog
        exit 1
    }
    
    # Initialize logging
    Initialize-Logging
    Write-ActionLog "=== Autodesk Uninstaller Started ==="
    Write-ActionLog "Mode: GUI"
    
    try {
        # Detect products
        $products = Get-AutodeskProducts
        
        if ($products.Count -eq 0) {
            Show-MessageDialog -Title "No Products Found" `
                              -Message "No Autodesk products found on this system." `
                              -Icon ([char]::ConvertFromUtf32(0x2139))
            return
        }
        
        # Show product selection GUI
        if (-not (Show-ProductSelectionGUI -Products $products)) {
            Write-ActionLog "User cancelled operation"
            return
        }
        
        $selectedProducts = Get-SelectedProducts
        if ($selectedProducts.Count -eq 0) {
            Show-MessageDialog -Title "No Selection" `
                              -Message "No products selected for uninstallation." `
                              -Icon ([char]::ConvertFromUtf32(0x26A0))
            return
        }
        
        $uninstallMode = Get-UninstallMode
        Write-ActionLog "Selected products: $($selectedProducts.Count)"
        Write-ActionLog "Uninstall mode: $uninstallMode"
        
        # Show confirmation dialog
        if (-not (Show-ConfirmationDialog)) {
            Write-ActionLog "User cancelled at confirmation"
            return
        }
        
        # Process uninstallation
        $results = Invoke-UninstallationProcess
        
        # Log results
        Write-ActionLog "=== Uninstallation Complete ==="
        Write-ActionLog "Successful: $($results.Success)"
        Write-ActionLog "Failed: $($results.Failed)"
        Write-ActionLog "Mode: $uninstallMode"
        
        $addInsBackupPath = Get-AddInsBackupPath
        if ($addInsBackupPath) {
            Write-ActionLog "Add-ins backed up to: $addInsBackupPath"
        }
        
        # Show summary dialog
        Show-SummaryDialog -SuccessCount $results.Success -FailCount $results.Failed
        
    } catch {
        Write-ActionLog "Fatal error: $_"
        Show-MessageDialog -Title "Error" `
                          -Message "An error occurred during execution. Check the logs for details." `
                          -Icon ([char]::ConvertFromUtf32(0x274C))
    } finally {
        # Cleanup
        Close-ProgressWindow
        Stop-LoggingTranscript
    }
}

# Run main function
Main
