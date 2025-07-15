<#  ---------------------------------------------------------------------------
    Autodesk Products — Optimized GUI Uninstaller
    File   :  Main.ps1
    Updated: 2025‑01‑08
    Usage  :  powershell.exe -ExecutionPolicy Bypass -File .\Main.ps1
    Features:
      - Optimized for fast, silent uninstallation
      - Prevents reinstallation issues
      - No CMD popups or errors
      - Smart cleanup order
      - Parallel processing where possible
--------------------------------------------------------------------------- #>

# Load required assemblies first
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Set console window state to minimize popups
Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    public class Win32Console {
        [DllImport("kernel32.dll")]
        public static extern IntPtr GetConsoleWindow();
        [DllImport("user32.dll")]
        public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
        public const int SW_HIDE = 0;
        public const int SW_MINIMIZE = 6;
    }
"@

# Hide PowerShell console window
$consolePtr = [Win32Console]::GetConsoleWindow()
[Win32Console]::ShowWindow($consolePtr, [Win32Console]::SW_MINIMIZE)

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
    Processes the uninstallation workflow with optimized order
.DESCRIPTION
    Handles the main uninstallation process in the correct order to prevent errors
.OUTPUTS
    Hashtable containing success and failure counts
#>
function Invoke-UninstallationProcess {
    $successCount = 0
    $failCount = 0
    
    try {
        $selectedProducts = Get-SelectedProducts
        $uninstallMode = Get-UninstallMode
        
        # STEP 1: Stop services and processes first (5%)
        Show-ProgressWindow -Title "Autodesk Uninstaller" -Status "Stopping Autodesk services..." -PercentComplete 5
        Stop-AutodeskServices | Out-Null
        
        # STEP 2: Backup add-ins if reinstall mode (10%)
        if ($uninstallMode -eq 'Reinstall') {
            Show-ProgressWindow -Title "Autodesk Uninstaller" -Status "Backing up add-ins..." -PercentComplete 10
            
            $productTypes = $selectedProducts.ProductType | Select-Object -Unique
            foreach ($type in $productTypes) {
                Backup-AddIns -ProductType $type | Out-Null
            }
        }
        
        # STEP 3: Sort products by dependency order (15%)
        Show-ProgressWindow -Title "Autodesk Uninstaller" -Status "Analyzing product dependencies..." -PercentComplete 15
        
        # Sort products: Add-ins first, then secondary products, then main products
        $sortedProducts = $selectedProducts | Sort-Object -Property @{
            Expression = {
                switch -Wildcard ($_.DisplayName) {
                    "*Add-in*" { 1 }
                    "*Plugin*" { 1 }
                    "*Extension*" { 1 }
                    "*Tools*" { 2 }
                    "*Content*" { 2 }
                    "*Library*" { 2 }
                    "Desktop Connector" { 3 }
                    default { 4 }
                }
            }
        }, DisplayName
        
        # STEP 4: Uninstall products in dependency order (20-85%)
        $totalProducts = $sortedProducts.Count
        $currentProduct = 0
        
        foreach ($product in $sortedProducts) {
            $currentProduct++
            $percentComplete = 20 + (($currentProduct / $totalProducts) * 65)
            
            Show-ProgressWindow -Title "Autodesk Uninstaller" `
                               -Status "Uninstalling $($product.DisplayName)... ($currentProduct of $totalProducts)" `
                               -PercentComplete $percentComplete
            
            if (Uninstall-Product -Product $product) {
                $successCount++
            } else {
                $failCount++
            }
            
            # Small delay to ensure processes are terminated
            Start-Sleep -Milliseconds 250
        }
        
        # STEP 5: Clean product data (90%)
        Show-ProgressWindow -Title "Autodesk Uninstaller" -Status "Cleaning product data..." -PercentComplete 90
        
        $productTypes = $selectedProducts.ProductType | Select-Object -Unique
        foreach ($type in $productTypes) {
            Clear-ProductData -ProductType $type -PreserveAddIns ($uninstallMode -eq 'Reinstall')
        }
        
        # STEP 6: Clean system remnants last (95%)
        Show-ProgressWindow -Title "Autodesk Uninstaller" -Status "Cleaning system remnants..." -PercentComplete 95
        Clear-AutodeskSystemRemnants
        
        # STEP 7: Final cleanup (100%)
        Show-ProgressWindow -Title "Autodesk Uninstaller" -Status "Finalizing..." -PercentComplete 100
        Start-Sleep -Milliseconds 500
        
    } catch {
        Write-ActionLog "Error in uninstallation process: $_"
        # Continue to return results even if there was an error
    } finally {
        # Always close progress window
        Close-ProgressWindow
    }
    
    # Ensure we always return a valid object
    Write-ActionLog "Creating result object with Success=$successCount, Failed=$failCount"
    
    $resultObject = [PSCustomObject]@{
        Success = [int]$successCount
        Failed = [int]$failCount
    }
    
    Write-ActionLog "Result object created. Type: $($resultObject.GetType().FullName)"
    Write-ActionLog "Result object properties: $($resultObject.PSObject.Properties.Name -join ', ')"
    
    # Validate the object before returning
    if (-not ($resultObject.PSObject.Properties.Name -contains 'Success')) {
        Write-ActionLog "ERROR: Success property missing from result object"
        throw "Failed to create Success property"
    }
    if (-not ($resultObject.PSObject.Properties.Name -contains 'Failed')) {
        Write-ActionLog "ERROR: Failed property missing from result object"
        throw "Failed to create Failed property"
    }
    
    Write-ActionLog "Result object validation passed"
    return $resultObject
}

<#
.SYNOPSIS
    Main entry point for the Autodesk Uninstaller
.DESCRIPTION
    Orchestrates the entire uninstallation process from start to finish
#>
function Main {
    # Set process priority to high for better performance
    $currentProcess = Get-Process -Id $PID
    $currentProcess.PriorityClass = 'High'
    
    # Check administrator privileges
    if (-not (Test-AdministratorPrivileges)) {
        Show-ElevationDialog
        exit 1
    }
    
    # Initialize logging
    Initialize-Logging
    Write-ActionLog "=== Autodesk Uninstaller Started ==="
    Write-ActionLog "Mode: GUI"
    Write-ActionLog "PowerShell Version: $($PSVersionTable.PSVersion)"
    Write-ActionLog "OS Version: $([System.Environment]::OSVersion.Version)"
    
    try {
        # Detect products with progress indication
        [System.Windows.Forms.Application]::EnableVisualStyles()
        $detectForm = New-Object System.Windows.Forms.Form
        $detectForm.Text = "Detecting Autodesk Products..."
        $detectForm.Size = New-Object System.Drawing.Size(350, 120)
        $detectForm.StartPosition = "CenterScreen"
        $detectForm.FormBorderStyle = 'FixedDialog'
        $detectForm.MaximizeBox = $false
        $detectForm.MinimizeBox = $false
        
        $detectLabel = New-Object System.Windows.Forms.Label
        $detectLabel.Text = "Scanning for installed Autodesk products..."
        $detectLabel.Location = New-Object System.Drawing.Point(50, 30)
        $detectLabel.Size = New-Object System.Drawing.Size(250, 30)
        $detectLabel.TextAlign = 'MiddleCenter'
        $detectForm.Controls.Add($detectLabel)
        
        $detectForm.Show()
        [System.Windows.Forms.Application]::DoEvents()
        
        $products = @(Get-AutodeskProducts)
        
        $detectForm.Close()
        
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
        
        $selectedProducts = @(Get-SelectedProducts)
        if ($selectedProducts.Count -eq 0) {
            Show-MessageDialog -Title "No Selection" `
                              -Message "No products selected for uninstallation." `
                              -Icon ([char]::ConvertFromUtf32(0x26A0))
            return
        }
        
        $uninstallMode = Get-UninstallMode
        Write-ActionLog "Selected products: $($selectedProducts.Count)"
        Write-ActionLog "Uninstall mode: $uninstallMode"
        
        # Log selected products
        foreach ($product in $selectedProducts) {
            Write-ActionLog "  - $($product.DisplayName) v$($product.DisplayVersion)"
        }
        
        # Show confirmation dialog
        if (-not (Show-ConfirmationDialog)) {
            Write-ActionLog "User cancelled at confirmation"
            return
        }
        
        # Process uninstallation
        Write-ActionLog "Starting uninstallation process..."
        $results = Invoke-UninstallationProcess
        
        # Ensure we get the actual object, not an array wrapper
        if ($results -is [System.Array] -and $results.Count -eq 1) {
            $results = $results[0]
        }
        
        Write-ActionLog "Uninstallation process completed"
        
        # Validate results object
        Write-ActionLog "Validating results object..."
        Write-ActionLog "Results is null: $($null -eq $results)"
        if ($results) {
            Write-ActionLog "Results type: $($results.GetType().FullName)"
            Write-ActionLog "Results properties: $($results.PSObject.Properties.Name -join ', ')"
        }
        
        if (-not $results) {
            throw "Uninstallation process returned null results"
        }
        
        if (-not ($results.PSObject.Properties.Name -contains 'Success')) {
            throw "Results object missing Success property. Available properties: $($results.PSObject.Properties.Name -join ', ')"
        }
        
        if (-not ($results.PSObject.Properties.Name -contains 'Failed')) {
            throw "Results object missing Failed property. Available properties: $($results.PSObject.Properties.Name -join ', ')"
        }
        
        Write-ActionLog "Results validation passed"
        
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
        Write-ActionLog "Stack trace: $($_.ScriptStackTrace)"
        Show-MessageDialog -Title "Error" `
                          -Message "An error occurred during execution:`n`n$($_.Exception.Message)`n`nCheck the logs for details." `
                          -Icon ([char]::ConvertFromUtf32(0x274C))
    } finally {
        # Cleanup
        Close-ProgressWindow
        Stop-LoggingTranscript
        
        # Restore process priority
        $currentProcess.PriorityClass = 'Normal'
        
        # Restore console window
        [Win32Console]::ShowWindow($consolePtr, [Win32Console]::SW_MINIMIZE)
    }
}

# Run main function
Main