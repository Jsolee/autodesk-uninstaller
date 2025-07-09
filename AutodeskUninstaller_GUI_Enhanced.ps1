# Show summary with modern dialog
    $summaryForm = New-Object System.Windows.Forms.Form
    $summaryForm.Text = "Uninstallation Complete"
    $summaryForm.Size = New-Object System.Drawing.Size(520, 450)
    $summaryForm.StartPosition = "CenterScreen"
    $summaryForm.FormBorderStyle = 'FixedSingle'
    $summaryForm.MaximizeBox = $false
    $summaryForm.BackColor = [System.Drawing.Color]::White
    
    # Success icon
    $successLabel = New-Object System.Windows.Forms.Label
    $successLabel.Text = [char]::ConvertFromUtf32(0x2705)  # Check mark emoji
    $successLabel.Font<#  ---------------------------------------------------------------------------
    Autodesk Products — GUI Uninstaller with selective cleanup
    File   :  AutodeskUninstaller_GUI.ps1
    Updated: 2025‑07‑04
    Usage  :  powershell.exe -ExecutionPolicy Bypass -File .\AutodeskUninstaller_GUI_Enhanced.ps1
    Features:
      - GUI interface for product selection
      - Detects all Autodesk products
      - Choice between full uninstall and reinstall preparation
      - Preserves add-ins for reinstallation scenario
      - Detailed logging of all operations
--------------------------------------------------------------------------- #>

# Load required assemblies first
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ─── Global variables ───────────────────────────────────────────────────────
$script:SelectedProducts = @()
$script:UninstallMode = $null
$script:LogPath = $null
$script:ActionLog = $null
$script:TranscriptLog = $null
$script:AddInsBackupPath = $null
$script:ProgressForm = $null
$script:ProgressLabel = $null
$script:ProgressBar = $null

# ─── Elevation check ────────────────────────────────────────────────────────
$identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal $identity
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
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
    exit 1
}

# ─── Logging functions ──────────────────────────────────────────────────────
function Initialize-Logging {
    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $script:LogPath = "C:\Temp\AutodeskUninstaller"
    [void](New-Item -ItemType Directory -Path $script:LogPath -Force)
    
    $script:ActionLog = "$LogPath\AutodeskUninstaller_Actions_$timestamp.log"
    $script:TranscriptLog = "$LogPath\AutodeskUninstaller_Transcript_$timestamp.log"
    
    Start-Transcript -Path $script:TranscriptLog
}

function Write-ActionLog {
    param([string]$msg)
    $timestampedMsg = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $msg"
    Add-Content -Path $script:ActionLog -Value $timestampedMsg -Encoding UTF8
}

# ─── Product detection ──────────────────────────────────────────────────────
function Get-AutodeskProducts {
    Write-ActionLog "Scanning for Autodesk products..."
    
    $hives = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
        'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
    )
    
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
            $productType = 'Other'
            if ($displayName -match 'Revit') { $productType = 'Revit' }
            elseif ($displayName -match 'AutoCAD') { $productType = 'AutoCAD' }
            elseif ($displayName -match '3ds Max') { $productType = '3dsMax' }
            elseif ($displayName -match 'Maya') { $productType = 'Maya' }
            elseif ($displayName -match 'Inventor') { $productType = 'Inventor' }
            elseif ($displayName -match 'Desktop Connector') { $productType = 'DesktopConnector' }
            elseif ($displayName -match 'Navisworks') { $productType = 'Navisworks' }
            elseif ($displayName -match 'Civil 3D') { $productType = 'Civil3D' }
            elseif ($displayName -match 'Fusion') { $productType = 'Fusion' }
            
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

# ─── GUI Creation ───────────────────────────────────────────────────────────
function Show-ProductSelectionGUI {
    param([array]$Products)
    
    # Enable visual styles for better rendering
    [System.Windows.Forms.Application]::EnableVisualStyles()
    
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Autodesk Uninstaller"
    $form.Size = New-Object System.Drawing.Size(920, 690)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = 'FixedSingle'
    $form.MaximizeBox = $false
    $form.BackColor = [System.Drawing.Color]::FromArgb(249, 249, 249)
    
    # Custom Panel for header
    $headerPanel = New-Object System.Windows.Forms.Panel
    $headerPanel.Size = New-Object System.Drawing.Size(920, 100)
    $headerPanel.Location = New-Object System.Drawing.Point(0, 0)
    $headerPanel.BackColor = [System.Drawing.Color]::White
    $form.Controls.Add($headerPanel)
    
    # Title Label with San Francisco-like font
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = "Autodesk Uninstaller"
    $titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 28, [System.Drawing.FontStyle]::Regular)
    $titleLabel.ForeColor = [System.Drawing.Color]::FromArgb(0, 0, 0)
    $titleLabel.Location = New-Object System.Drawing.Point(40, 25)
    $titleLabel.Size = New-Object System.Drawing.Size(500, 45)
    $titleLabel.AutoSize = $false
    $headerPanel.Controls.Add($titleLabel)
    
    # Subtitle
    $subtitleLabel = New-Object System.Windows.Forms.Label
    $subtitleLabel.Text = "Select products to remove from your system"
    $subtitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Regular)
    $subtitleLabel.ForeColor = [System.Drawing.Color]::FromArgb(142, 142, 147)
    $subtitleLabel.Location = New-Object System.Drawing.Point(42, 65)
    $subtitleLabel.Size = New-Object System.Drawing.Size(500, 20)
    $headerPanel.Controls.Add($subtitleLabel)
    
    # Custom ListView with modern styling
    $listPanel = New-Object System.Windows.Forms.Panel
    $listPanel.Location = New-Object System.Drawing.Point(40, 130)
    $listPanel.Size = New-Object System.Drawing.Size(840, 320)
    $listPanel.BackColor = [System.Drawing.Color]::White
    $listPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::None
    $form.Controls.Add($listPanel)
    
    # Add subtle border to panel
    $listPanel.Add_Paint({
        $g = $_.Graphics
        $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(229, 229, 234), 1)
        $g.DrawRectangle($pen, 0, 0, $listPanel.Width - 1, $listPanel.Height - 1)
        $pen.Dispose()
    })
    
    $listView = New-Object System.Windows.Forms.ListView
    $listView.Location = New-Object System.Drawing.Point(1, 1)
    $listView.Size = New-Object System.Drawing.Size(838, 318)
    $listView.View = 'Details'
    $listView.CheckBoxes = $true
    $listView.FullRowSelect = $true
    $listView.GridLines = $false
    $listView.BorderStyle = 'None'
    $listView.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $listView.BackColor = [System.Drawing.Color]::White
    $listView.ForeColor = [System.Drawing.Color]::FromArgb(0, 0, 0)
    
    # Configure header style
    $listView.OwnerDraw = $false
    
    # Add columns with better proportions
    [void]$listView.Columns.Add("Product Name", 480)
    [void]$listView.Columns.Add("Version", 140)
    [void]$listView.Columns.Add("Type", 180)
    
    # Style the column headers
    foreach ($column in $listView.Columns) {
        $column.TextAlign = 'Left'
    }
    
    # Populate ListView with alternating row colors
    $rowIndex = 0
    foreach ($product in $Products) {
        $item = New-Object System.Windows.Forms.ListViewItem($product.DisplayName)
        [void]$item.SubItems.Add($product.DisplayVersion)
        [void]$item.SubItems.Add($product.ProductType)
        $item.Tag = $product
        
        if ($rowIndex % 2 -eq 1) {
            $item.BackColor = [System.Drawing.Color]::FromArgb(249, 249, 249)
        }
        
        [void]$listView.Items.Add($item)
        $rowIndex++
    }
    
    $listPanel.Controls.Add($listView)
    
    # Modern styled Select All checkbox
    $selectAllCheckBox = New-Object System.Windows.Forms.CheckBox
    $selectAllCheckBox.Text = "Select All"
    $selectAllCheckBox.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $selectAllCheckBox.ForeColor = [System.Drawing.Color]::FromArgb(0, 122, 255)
    $selectAllCheckBox.Location = New-Object System.Drawing.Point(40, 460)
    $selectAllCheckBox.Size = New-Object System.Drawing.Size(100, 25)
    $selectAllCheckBox.FlatStyle = 'Flat'
    $selectAllCheckBox.Add_CheckedChanged({
        foreach ($item in $listView.Items) {
            $item.Checked = $selectAllCheckBox.Checked
        }
    })
    $form.Controls.Add($selectAllCheckBox)
    
    # Uninstall Mode Section with modern styling
    $modeLabel = New-Object System.Windows.Forms.Label
    $modeLabel.Text = "Uninstall Options"
    $modeLabel.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Regular)
    $modeLabel.Location = New-Object System.Drawing.Point(40, 495)
    $modeLabel.Size = New-Object System.Drawing.Size(200, 25)
    $form.Controls.Add($modeLabel)
    
    # Radio button panel
    $radioPanel = New-Object System.Windows.Forms.Panel
    $radioPanel.Location = New-Object System.Drawing.Point(40, 525)
    $radioPanel.Size = New-Object System.Drawing.Size(600, 60)
    $radioPanel.BackColor = [System.Drawing.Color]::FromArgb(249, 249, 249)
    $form.Controls.Add($radioPanel)
    
    $fullUninstallRadio = New-Object System.Windows.Forms.RadioButton
    $fullUninstallRadio.Text = "Complete removal - Remove all data including add-ins and preferences"
    $fullUninstallRadio.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $fullUninstallRadio.Location = New-Object System.Drawing.Point(10, 5)
    $fullUninstallRadio.Size = New-Object System.Drawing.Size(580, 25)
    $fullUninstallRadio.Checked = $true
    $fullUninstallRadio.FlatStyle = 'Flat'
    
    $reinstallRadio = New-Object System.Windows.Forms.RadioButton
    $reinstallRadio.Text = "Reinstall preparation - Preserve add-ins and user settings for later use"
    $reinstallRadio.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $reinstallRadio.Location = New-Object System.Drawing.Point(10, 30)
    $reinstallRadio.Size = New-Object System.Drawing.Size(580, 25)
    $reinstallRadio.FlatStyle = 'Flat'
    
    $radioPanel.Controls.Add($fullUninstallRadio)
    $radioPanel.Controls.Add($reinstallRadio)
    
    # Modern styled buttons
    $buttonPanel = New-Object System.Windows.Forms.Panel
    $buttonPanel.Location = New-Object System.Drawing.Point(0, 600)
    $buttonPanel.Size = New-Object System.Drawing.Size(920, 60)
    $buttonPanel.BackColor = [System.Drawing.Color]::FromArgb(249, 249, 249)
    $form.Controls.Add($buttonPanel)
    
    # Cancel button (secondary style)
    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Text = "Cancel"
    $cancelButton.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $cancelButton.Location = New-Object System.Drawing.Point(660, 15)
    $cancelButton.Size = New-Object System.Drawing.Size(100, 32)
    $cancelButton.FlatStyle = 'Flat'
    $cancelButton.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(209, 209, 214)
    $cancelButton.BackColor = [System.Drawing.Color]::White
    $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    
    # Uninstall button (primary style)
    $uninstallButton = New-Object System.Windows.Forms.Button
    $uninstallButton.Text = "Uninstall"
    $uninstallButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)
    $uninstallButton.Location = New-Object System.Drawing.Point(770, 15)
    $uninstallButton.Size = New-Object System.Drawing.Size(110, 32)
    $uninstallButton.FlatStyle = 'Flat'
    $uninstallButton.FlatAppearance.BorderSize = 0
    $uninstallButton.BackColor = [System.Drawing.Color]::FromArgb(0, 122, 255)
    $uninstallButton.ForeColor = [System.Drawing.Color]::White
    $uninstallButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    
    # Add hover effects
    $uninstallButton.Add_MouseEnter({
        $uninstallButton.BackColor = [System.Drawing.Color]::FromArgb(0, 100, 220)
    })
    $uninstallButton.Add_MouseLeave({
        $uninstallButton.BackColor = [System.Drawing.Color]::FromArgb(0, 122, 255)
    })
    
    $cancelButton.Add_MouseEnter({
        $cancelButton.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240)
    })
    $cancelButton.Add_MouseLeave({
        $cancelButton.BackColor = [System.Drawing.Color]::White
    })
    
    $buttonPanel.Controls.Add($uninstallButton)
    $buttonPanel.Controls.Add($cancelButton)
    
    # Form result handler
    if ($form.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $script:SelectedProducts = @()
        foreach ($item in $listView.Items) {
            if ($item.Checked) {
                $script:SelectedProducts += $item.Tag
            }
        }
        
        $script:UninstallMode = if ($fullUninstallRadio.Checked) { 'Full' } else { 'Reinstall' }
        return $true
    }
    
    return $false
}

# ─── Uninstall functions ────────────────────────────────────────────────────
function Stop-AutodeskServices {
    Write-ActionLog "Stopping Autodesk services and processes..."
    
    # Stop common Autodesk services
    $services = @('GenuineService', 'AdskLicensingService', 'AdAppMgrSvc', 'FNPLicensingService')
    foreach ($service in $services) {
        try {
            Stop-Service $service -Force -ErrorAction SilentlyContinue
            Set-Service $service -StartupType Disabled -ErrorAction SilentlyContinue
            Write-ActionLog "Stopped service: $service"
        } catch { }
    }
    
    # Kill popup processes
    $processes = @('message_router', 'GenuineService', 'AdSSO', 'AdskAccessServiceHost')
    foreach ($proc in $processes) {
        try {
            Stop-Process -Name $proc -Force -ErrorAction SilentlyContinue
            Write-ActionLog "Killed process: $proc"
        } catch { }
    }
}

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
            $argList = "/X `{$guid`} /qn /l*v `"$script:LogPath\MSI_$($Product.DisplayName -replace '[^\w]','_').log`""
            
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

function Backup-AddIns {
    param([string]$ProductType)
    
    Write-ActionLog "Backing up add-ins for $ProductType..."
    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $script:AddInsBackupPath = "C:\Temp\AutodeskAddInsBackup\$timestamp"
    [void](New-Item -ItemType Directory -Path $script:AddInsBackupPath -Force)
    
    $backedUpItems = @()
    
    # Define add-in locations by product type
    $addInPaths = @{
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
    
    # Get all user profiles
    $profiles = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*' | 
                Where-Object { $_.PSObject.Properties.Name -contains 'ProfileImagePath' -and $_.ProfileImagePath }
    
    foreach ($profile in $profiles) {
        $profilePath = $profile.ProfileImagePath
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
                            $destPath = Join-Path $script:AddInsBackupPath "$userName\$relativePath"
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
    
    Write-ActionLog "Backed up $($backedUpItems.Count) add-in items to: $script:AddInsBackupPath"
    return $backedUpItems
}

function Clear-ProductData {
    param(
        [string]$ProductType,
        [bool]$PreserveAddIns
    )
    
    Write-ActionLog "Clearing $ProductType data (PreserveAddIns: $PreserveAddIns)..."
    
    # Product-specific paths
    $productPaths = @{
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
    $profiles = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*' | 
                Where-Object { $_.PSObject.Properties.Name -contains 'ProfileImagePath' -and $_.ProfileImagePath }
    
    foreach ($profile in $profiles) {
        $profilePath = $profile.ProfileImagePath
        
        if (-not $PreserveAddIns) {
            # Full cleanup - remove everything
            foreach ($appData in @('AppData\Local\Autodesk', 'AppData\Roaming\Autodesk')) {
                $fullPath = Join-Path $profilePath $appData
                if (Test-Path $fullPath) {
                    Get-ChildItem $fullPath -Recurse -File | ForEach-Object {
                        Write-ActionLog "Deleting: $($_.FullName)"
                    }
                    Remove-Item $fullPath -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
        } else {
            # Selective cleanup - preserve add-ins
            $preservePaths = @(
                '*\Addins\*',
                '*\ApplicationPlugins\*',
                '*\plugins\*',
                '*\Support\*.lsp',
                '*\Support\*.fas',
                '*\Support\*.vlx'
            )
            
            foreach ($appData in @('AppData\Local\Autodesk', 'AppData\Roaming\Autodesk')) {
                $basePath = Join-Path $profilePath $appData
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
    }
}

# ─── Progress window ────────────────────────────────────────────────────────
function Show-ProgressWindow {
    param(
        [string]$Title,
        [string]$Status,
        [int]$PercentComplete = 0
    )
    
    if (-not $script:ProgressForm) {
        $script:ProgressForm = New-Object System.Windows.Forms.Form
        $script:ProgressForm.Text = $Title
        $script:ProgressForm.Size = New-Object System.Drawing.Size(520, 180)
        $script:ProgressForm.StartPosition = "CenterScreen"
        $script:ProgressForm.FormBorderStyle = 'FixedSingle'
        $script:ProgressForm.MaximizeBox = $false
        $script:ProgressForm.MinimizeBox = $false
        $script:ProgressForm.BackColor = [System.Drawing.Color]::White
        $script:ProgressForm.ControlBox = $false
        
        # Progress icon
        $iconLabel = New-Object System.Windows.Forms.Label
        $iconLabel.Text = [char]::ConvertFromUtf32(0x2699)  # Gear emoji
        $iconLabel.Font = New-Object System.Drawing.Font("Segoe UI Emoji", 32)
        $iconLabel.Location = New-Object System.Drawing.Point(40, 25)
        $iconLabel.Size = New-Object System.Drawing.Size(60, 60)
        $script:ProgressForm.Controls.Add($iconLabel)
        
        $script:ProgressLabel = New-Object System.Windows.Forms.Label
        $script:ProgressLabel.Location = New-Object System.Drawing.Point(110, 35)
        $script:ProgressLabel.Size = New-Object System.Drawing.Size(360, 40)
        $script:ProgressLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11)
        $script:ProgressLabel.Text = $Status
        
        $script:ProgressBar = New-Object System.Windows.Forms.ProgressBar
        $script:ProgressBar.Location = New-Object System.Drawing.Point(40, 100)
        $script:ProgressBar.Size = New-Object System.Drawing.Size(440, 8)
        $script:ProgressBar.Style = 'Continuous'
        $script:ProgressBar.MarqueeAnimationSpeed = 30
        
        # Style the progress bar
        $script:ProgressBar.ForeColor = [System.Drawing.Color]::FromArgb(0, 122, 255)
        $script:ProgressBar.BackColor = [System.Drawing.Color]::FromArgb(229, 229, 234)
        
        $script:ProgressForm.Controls.Add($script:ProgressLabel)
        $script:ProgressForm.Controls.Add($script:ProgressBar)
        $script:ProgressForm.Show()
    }
    
    $script:ProgressLabel.Text = $Status
    $script:ProgressBar.Value = $PercentComplete
    $script:ProgressForm.Refresh()
    [System.Windows.Forms.Application]::DoEvents()
}

function Close-ProgressWindow {
    if ($script:ProgressForm) {
        $script:ProgressForm.Close()
        $script:ProgressForm = $null
    }
}

# ─── Main execution ─────────────────────────────────────────────────────────
function Main {
    Initialize-Logging
    Write-ActionLog "=== Autodesk Uninstaller Started ==="
    Write-ActionLog "Mode: GUI"
    
    # Detect products
    $products = Get-AutodeskProducts
    
    if ($products.Count -eq 0) {
        $noProductsForm = New-Object System.Windows.Forms.Form
        $noProductsForm.Text = "No Products Found"
        $noProductsForm.Size = New-Object System.Drawing.Size(420, 200)
        $noProductsForm.StartPosition = "CenterScreen"
        $noProductsForm.FormBorderStyle = 'FixedSingle'
        $noProductsForm.MaximizeBox = $false
        $noProductsForm.BackColor = [System.Drawing.Color]::White
        
        $infoIcon = New-Object System.Windows.Forms.Label
        $infoIcon.Text = [char]::ConvertFromUtf32(0x2139)  # Info emoji
        $infoIcon.Font = New-Object System.Drawing.Font("Segoe UI Emoji", 32)
        $infoIcon.Location = New-Object System.Drawing.Point(175, 20)
        $infoIcon.Size = New-Object System.Drawing.Size(70, 50)
        $infoIcon.TextAlign = 'MiddleCenter'
        $noProductsForm.Controls.Add($infoIcon)
        
        $msgLabel = New-Object System.Windows.Forms.Label
        $msgLabel.Text = "No Autodesk products found on this system."
        $msgLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
        $msgLabel.Location = New-Object System.Drawing.Point(40, 80)
        $msgLabel.Size = New-Object System.Drawing.Size(340, 30)
        $msgLabel.TextAlign = 'MiddleCenter'
        $noProductsForm.Controls.Add($msgLabel)
        
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
        $noProductsForm.Controls.Add($okButton)
        
        [void]$noProductsForm.ShowDialog()
        Stop-Transcript
        return
    }
    
    # Show GUI
    if (-not (Show-ProductSelectionGUI -Products $products)) {
        Write-ActionLog "User cancelled operation"
        Stop-Transcript
        return
    }
    
    if ($script:SelectedProducts.Count -eq 0) {
        $noSelectionForm = New-Object System.Windows.Forms.Form
        $noSelectionForm.Text = "No Selection"
        $noSelectionForm.Size = New-Object System.Drawing.Size(420, 200)
        $noSelectionForm.StartPosition = "CenterScreen"
        $noSelectionForm.FormBorderStyle = 'FixedSingle'
        $noSelectionForm.MaximizeBox = $false
        $noSelectionForm.BackColor = [System.Drawing.Color]::White
        
        $warnIcon = New-Object System.Windows.Forms.Label
        $warnIcon.Text = [char]::ConvertFromUtf32(0x26A0)  # Warning emoji
        $warnIcon.Font = New-Object System.Drawing.Font("Segoe UI Emoji", 32)
        $warnIcon.Location = New-Object System.Drawing.Point(175, 20)
        $warnIcon.Size = New-Object System.Drawing.Size(70, 50)
        $warnIcon.TextAlign = 'MiddleCenter'
        $noSelectionForm.Controls.Add($warnIcon)
        
        $msgLabel = New-Object System.Windows.Forms.Label
        $msgLabel.Text = "No products selected for uninstallation."
        $msgLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
        $msgLabel.Location = New-Object System.Drawing.Point(40, 80)
        $msgLabel.Size = New-Object System.Drawing.Size(340, 30)
        $msgLabel.TextAlign = 'MiddleCenter'
        $noSelectionForm.Controls.Add($msgLabel)
        
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
        $noSelectionForm.Controls.Add($okButton)
        
        [void]$noSelectionForm.ShowDialog()
        Stop-Transcript
        return
    }
    
    Write-ActionLog "Selected products: $($script:SelectedProducts.Count)"
    Write-ActionLog "Uninstall mode: $script:UninstallMode"
    
    # Confirm action with modern dialog
    $confirmForm = New-Object System.Windows.Forms.Form
    $confirmForm.Text = "Confirm Uninstallation"
    $confirmForm.Size = New-Object System.Drawing.Size(520, 420)
    $confirmForm.StartPosition = "CenterScreen"
    $confirmForm.FormBorderStyle = 'FixedSingle'
    $confirmForm.MaximizeBox = $false
    $confirmForm.BackColor = [System.Drawing.Color]::White
    
    # Warning icon
    $warnLabel = New-Object System.Windows.Forms.Label
    $warnLabel.Text = [char]::ConvertFromUtf32(0x26A0)  # Warning emoji
    $warnLabel.Font = New-Object System.Drawing.Font("Segoe UI Emoji", 48)
    $warnLabel.Location = New-Object System.Drawing.Point(210, 20)
    $warnLabel.Size = New-Object System.Drawing.Size(100, 80)
    $warnLabel.TextAlign = 'MiddleCenter'
    $confirmForm.Controls.Add($warnLabel)
    
    # Title
    $confirmTitle = New-Object System.Windows.Forms.Label
    $confirmTitle.Text = "Confirm Uninstallation"
    $confirmTitle.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Regular)
    $confirmTitle.Location = New-Object System.Drawing.Point(40, 110)
    $confirmTitle.Size = New-Object System.Drawing.Size(440, 30)
    $confirmTitle.TextAlign = 'MiddleCenter'
    $confirmForm.Controls.Add($confirmTitle)
    
    # Message
    $message = "You are about to uninstall $($script:SelectedProducts.Count) product(s)`n`n"
    $message += "Mode: $script:UninstallMode uninstall`n`n"
    
    $messageLabel = New-Object System.Windows.Forms.Label
    $messageLabel.Text = $message
    $messageLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $messageLabel.ForeColor = [System.Drawing.Color]::FromArgb(60, 60, 67)
    $messageLabel.Location = New-Object System.Drawing.Point(40, 150)
    $messageLabel.Size = New-Object System.Drawing.Size(440, 60)
    $messageLabel.TextAlign = 'MiddleCenter'
    $confirmForm.Controls.Add($messageLabel)
    
    # Products list
    $productsList = New-Object System.Windows.Forms.TextBox
    $productsList.Multiline = $true
    $productsList.ScrollBars = 'Vertical'
    $productsList.ReadOnly = $true
    $productsList.BorderStyle = 'FixedSingle'
    $productsList.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $productsList.Location = New-Object System.Drawing.Point(40, 220)
    $productsList.Size = New-Object System.Drawing.Size(440, 80)
    $productsList.BackColor = [System.Drawing.Color]::FromArgb(249, 249, 249)
    
    $productText = ""
    foreach ($product in $script:SelectedProducts) {
        $productText += [char]0x2022 + " $($product.DisplayName)`r`n"
    }
    $productsList.Text = $productText.TrimEnd()
    $confirmForm.Controls.Add($productsList)
    
    # Buttons
    $confirmButtonPanel = New-Object System.Windows.Forms.Panel
    $confirmButtonPanel.Location = New-Object System.Drawing.Point(0, 320)
    $confirmButtonPanel.Size = New-Object System.Drawing.Size(520, 60)
    $confirmButtonPanel.BackColor = [System.Drawing.Color]::FromArgb(249, 249, 249)
    $confirmForm.Controls.Add($confirmButtonPanel)
    
    $noButton = New-Object System.Windows.Forms.Button
    $noButton.Text = "Cancel"
    $noButton.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $noButton.Location = New-Object System.Drawing.Point(250, 15)
    $noButton.Size = New-Object System.Drawing.Size(100, 32)
    $noButton.FlatStyle = 'Flat'
    $noButton.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(209, 209, 214)
    $noButton.BackColor = [System.Drawing.Color]::White
    $noButton.DialogResult = [System.Windows.Forms.DialogResult]::No
    
    $yesButton = New-Object System.Windows.Forms.Button
    $yesButton.Text = "Continue"
    $yesButton.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $yesButton.Location = New-Object System.Drawing.Point(360, 15)
    $yesButton.Size = New-Object System.Drawing.Size(110, 32)
    $yesButton.FlatStyle = 'Flat'
    $yesButton.FlatAppearance.BorderSize = 0
    $yesButton.BackColor = [System.Drawing.Color]::FromArgb(255, 59, 48)
    $yesButton.ForeColor = [System.Drawing.Color]::White
    $yesButton.DialogResult = [System.Windows.Forms.DialogResult]::Yes
    
    $confirmButtonPanel.Controls.Add($noButton)
    $confirmButtonPanel.Controls.Add($yesButton)
    
    $result = $confirmForm.ShowDialog()
    
    if ($result -ne [System.Windows.Forms.DialogResult]::Yes) {
        Write-ActionLog "User cancelled at confirmation"
        Stop-Transcript
        return
    }
    
    # Stop services
    Show-ProgressWindow -Title "Autodesk Uninstaller" -Status "Stopping Autodesk services..." -PercentComplete 5
    Stop-AutodeskServices
    
    # Backup add-ins if reinstall mode
    if ($script:UninstallMode -eq 'Reinstall') {
        Show-ProgressWindow -Title "Autodesk Uninstaller" -Status "Backing up add-ins..." -PercentComplete 10
        
        $productTypes = $script:SelectedProducts.ProductType | Select-Object -Unique
        foreach ($type in $productTypes) {
            Backup-AddIns -ProductType $type
        }
    }
    
    # Uninstall products
    $totalProducts = $script:SelectedProducts.Count
    $currentProduct = 0
    $successCount = 0
    $failCount = 0
    
    foreach ($product in $script:SelectedProducts) {
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
    
    $productTypes = $script:SelectedProducts.ProductType | Select-Object -Unique
    foreach ($type in $productTypes) {
        Clear-ProductData -ProductType $type -PreserveAddIns ($script:UninstallMode -eq 'Reinstall')
    }
    
    Close-ProgressWindow
    
    # Summary
    Write-ActionLog "=== Uninstallation Complete ==="
    Write-ActionLog "Successful: $successCount"
    Write-ActionLog "Failed: $failCount"
    Write-ActionLog "Mode: $script:UninstallMode"
    if ($script:AddInsBackupPath) {
        Write-ActionLog "Add-ins backed up to: $script:AddInsBackupPath"
    }
    
    Stop-Transcript
    
    # Show summary with modern dialog
    $summaryForm = New-Object System.Windows.Forms.Form
    $summaryForm.Text = "Uninstallation Complete"
    $summaryForm.Size = New-Object System.Drawing.Size(520, 450)
    $summaryForm.StartPosition = "CenterScreen"
    $summaryForm.FormBorderStyle = 'FixedSingle'
    $summaryForm.MaximizeBox = $false
    $summaryForm.BackColor = [System.Drawing.Color]::White
    
    # Success icon
    $successLabel = New-Object System.Windows.Forms.Label
    $successLabel.Text = [char]::ConvertFromUtf32(0x2705)
    $successLabel.Font = New-Object System.Drawing.Font("Segoe UI Emoji", 48)
    $successLabel.Location = New-Object System.Drawing.Point(210, 20)
    $successLabel.Size = New-Object System.Drawing.Size(100, 80)
    $successLabel.TextAlign = 'MiddleCenter'
    $summaryForm.Controls.Add($successLabel)
    
    # Title
    $summaryTitle = New-Object System.Windows.Forms.Label
    $summaryTitle.Text = "Uninstallation Complete"
    $summaryTitle.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Regular)
    $summaryTitle.Location = New-Object System.Drawing.Point(40, 110)
    $summaryTitle.Size = New-Object System.Drawing.Size(440, 30)
    $summaryTitle.TextAlign = 'MiddleCenter'
    $summaryForm.Controls.Add($summaryTitle)
    
    # Summary stats panel
    $statsPanel = New-Object System.Windows.Forms.Panel
    $statsPanel.Location = New-Object System.Drawing.Point(40, 160)
    $statsPanel.Size = New-Object System.Drawing.Size(440, 80)
    $statsPanel.BackColor = [System.Drawing.Color]::FromArgb(249, 249, 249)
    $summaryForm.Controls.Add($statsPanel)
    
    # Success count
    $successStat = New-Object System.Windows.Forms.Label
    $successStat.Text = "$successCount`nSuccessful"
    $successStat.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $successStat.ForeColor = [System.Drawing.Color]::FromArgb(52, 199, 89)
    $successStat.Location = New-Object System.Drawing.Point(100, 15)
    $successStat.Size = New-Object System.Drawing.Size(100, 50)
    $successStat.TextAlign = 'MiddleCenter'
    $statsPanel.Controls.Add($successStat)
    
    # Failed count
    $failStat = New-Object System.Windows.Forms.Label
    $failStat.Text = "$failCount`nFailed"
    $failStat.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $failStat.ForeColor = if ($failCount -gt 0) { [System.Drawing.Color]::FromArgb(255, 59, 48) } else { [System.Drawing.Color]::FromArgb(142, 142, 147) }
    $failStat.Location = New-Object System.Drawing.Point(240, 15)
    $failStat.Size = New-Object System.Drawing.Size(100, 50)
    $failStat.TextAlign = 'MiddleCenter'
    $statsPanel.Controls.Add($failStat)
    
    # Details
    $detailsLabel = New-Object System.Windows.Forms.Label
    $detailsLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $detailsLabel.ForeColor = [System.Drawing.Color]::FromArgb(60, 60, 67)
    $detailsLabel.Location = New-Object System.Drawing.Point(40, 260)
    $detailsLabel.Size = New-Object System.Drawing.Size(440, 60)
    
    $detailsText = "Logs saved to:`n$script:LogPath`n"
    if ($script:AddInsBackupPath) {
        $detailsText += "`nAdd-ins backed up to:`n$script:AddInsBackupPath"
    }
    $detailsLabel.Text = $detailsText
    $summaryForm.Controls.Add($detailsLabel)
    
    # Restart recommendation
    $restartLabel = New-Object System.Windows.Forms.Label
    $restartLabel.Text = "$([char]::ConvertFromUtf32(0x1F4A1)) A system restart is recommended to complete the process."
    $restartLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $restartLabel.ForeColor = [System.Drawing.Color]::FromArgb(0, 122, 255)
    $restartLabel.Location = New-Object System.Drawing.Point(40, 330)
    $restartLabel.Size = New-Object System.Drawing.Size(440, 20)
    $restartLabel.TextAlign = 'MiddleCenter'
    $summaryForm.Controls.Add($restartLabel)
    
    # Done button
    $doneButtonPanel = New-Object System.Windows.Forms.Panel
    $doneButtonPanel.Location = New-Object System.Drawing.Point(0, 360)
    $doneButtonPanel.Size = New-Object System.Drawing.Size(520, 60)
    $doneButtonPanel.BackColor = [System.Drawing.Color]::FromArgb(249, 249, 249)
    $summaryForm.Controls.Add($doneButtonPanel)
    
    $doneButton = New-Object System.Windows.Forms.Button
    $doneButton.Text = "Done"
    $doneButton.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $doneButton.Location = New-Object System.Drawing.Point(360, 15)
    $doneButton.Size = New-Object System.Drawing.Size(110, 32)
    $doneButton.FlatStyle = 'Flat'
    $doneButton.FlatAppearance.BorderSize = 0
    $doneButton.BackColor = [System.Drawing.Color]::FromArgb(0, 122, 255)
    $doneButton.ForeColor = [System.Drawing.Color]::White
    $doneButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    
    $doneButtonPanel.Controls.Add($doneButton)
    
    [void]$summaryForm.ShowDialog()
}

# Run main function
Main