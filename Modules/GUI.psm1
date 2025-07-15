<#
.SYNOPSIS
    GUI module for Autodesk Uninstaller
.DESCRIPTION
    Handles all GUI creation and user interaction
#>

<#
.SYNOPSIS
    Shows the main product selection GUI
.DESCRIPTION
    Displays a modern GUI for selecting products to uninstall
.PARAMETER Products
    Array of products to display in the GUI
.OUTPUTS
    Boolean indicating if user confirmed the selection
#>
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
    
    # Create header panel
    $headerPanel = New-HeaderPanel -Form $form
    
    # Create product list panel
    $listPanel, $listView = New-ProductListPanel -Form $form -Products $Products
    
    # Create select all checkbox
    $selectAllCheckBox = New-SelectAllCheckbox -Form $form -ListView $listView
    
    # Create mode selection panel
    $fullUninstallRadio, $reinstallRadio = New-ModeSelectionPanel -Form $form
    
    # Create button panel
    $uninstallButton, $cancelButton = New-ButtonPanel -Form $form
    
    # Form result handler
    if ($form.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $selectedProducts = @()
        foreach ($item in $listView.Items) {
            if ($item.Checked) {
                $mainProduct = $item.Tag
                # Expand main product into its components for uninstallation
                if ($mainProduct.Components) {
                    $selectedProducts += $mainProduct.Components
                } else {
                    $selectedProducts += $mainProduct
                }
            }
        }
        
        $uninstallMode = if ($fullUninstallRadio.Checked) { 'Complete' } else { 'Reinstall' }
        
        Set-SelectedProducts -value $selectedProducts
        Set-UninstallMode -value $uninstallMode
        
        return $true
    }
    
    return $false
}

<#
.SYNOPSIS
    Creates the header panel for the main form
.DESCRIPTION
    Creates and configures the header panel with title and subtitle
.PARAMETER Form
    The parent form to add the panel to
.OUTPUTS
    The created header panel
#>
function New-HeaderPanel {
    param([System.Windows.Forms.Form]$Form)
    
    # Custom Panel for header
    $headerPanel = New-Object System.Windows.Forms.Panel
    $headerPanel.Size = New-Object System.Drawing.Size(920, 100)
    $headerPanel.Location = New-Object System.Drawing.Point(0, 0)
    $headerPanel.BackColor = [System.Drawing.Color]::White
    $Form.Controls.Add($headerPanel)
    
    # Title Label
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
    
    return $headerPanel
}

<#
.SYNOPSIS
    Creates the product list panel
.DESCRIPTION
    Creates and configures the product list panel with ListView
.PARAMETER Form
    The parent form to add the panel to
.PARAMETER Products
    Array of products to display
.OUTPUTS
    Tuple containing the list panel and ListView
#>
function New-ProductListPanel {
    param([System.Windows.Forms.Form]$Form, [array]$Products)
    
    # Custom ListView with modern styling
    $listPanel = New-Object System.Windows.Forms.Panel
    $listPanel.Location = New-Object System.Drawing.Point(40, 130)
    $listPanel.Size = New-Object System.Drawing.Size(840, 320)
    $listPanel.BackColor = [System.Drawing.Color]::White
    $listPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::None
    $Form.Controls.Add($listPanel)
    
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
    
    # Add columns
    [void]$listView.Columns.Add("Product Name", 480)
    [void]$listView.Columns.Add("Version", 140)
    [void]$listView.Columns.Add("Type", 180)
    
    # Style the column headers
    foreach ($column in $listView.Columns) {
        $column.TextAlign = 'Left'
    }
    
    # Populate ListView with main products
    $rowIndex = 0
    foreach ($product in $Products) {
        $displayName = $product.DisplayName
        if ($product.ComponentCount -gt 1) {
            $displayName += " ($($product.ComponentCount) components)"
        }
        
        $item = New-Object System.Windows.Forms.ListViewItem($displayName)
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
    
    return $listPanel, $listView
}

<#
.SYNOPSIS
    Creates the Select All checkbox
.DESCRIPTION
    Creates and configures the Select All checkbox
.PARAMETER Form
    The parent form to add the checkbox to
.PARAMETER ListView
    The ListView to control with the checkbox
.OUTPUTS
    The created checkbox
#>
function New-SelectAllCheckbox {
    param([System.Windows.Forms.Form]$Form, [System.Windows.Forms.ListView]$ListView)
    
    $selectAllCheckBox = New-Object System.Windows.Forms.CheckBox
    $selectAllCheckBox.Text = "Select All"
    $selectAllCheckBox.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $selectAllCheckBox.ForeColor = [System.Drawing.Color]::FromArgb(0, 122, 255)
    $selectAllCheckBox.Location = New-Object System.Drawing.Point(40, 460)
    $selectAllCheckBox.Size = New-Object System.Drawing.Size(100, 25)
    $selectAllCheckBox.FlatStyle = 'Flat'
    $selectAllCheckBox.Add_CheckedChanged({
        foreach ($item in $ListView.Items) {
            $item.Checked = $selectAllCheckBox.Checked
        }
    })
    $Form.Controls.Add($selectAllCheckBox)
    
    return $selectAllCheckBox
}

<#
.SYNOPSIS
    Creates the mode selection panel
.DESCRIPTION
    Creates and configures the uninstall mode selection panel
.PARAMETER Form
    The parent form to add the panel to
.OUTPUTS
    Tuple containing the full uninstall and reinstall radio buttons
#>
function New-ModeSelectionPanel {
    param([System.Windows.Forms.Form]$Form)
    
    # Uninstall Mode Section
    $modeLabel = New-Object System.Windows.Forms.Label
    $modeLabel.Text = "Uninstall Options"
    $modeLabel.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Regular)
    $modeLabel.Location = New-Object System.Drawing.Point(40, 495)
    $modeLabel.Size = New-Object System.Drawing.Size(200, 25)
    $Form.Controls.Add($modeLabel)
    
    # Radio button panel
    $radioPanel = New-Object System.Windows.Forms.Panel
    $radioPanel.Location = New-Object System.Drawing.Point(40, 525)
    $radioPanel.Size = New-Object System.Drawing.Size(600, 60)
    $radioPanel.BackColor = [System.Drawing.Color]::FromArgb(249, 249, 249)
    $Form.Controls.Add($radioPanel)
    
    $fullUninstallRadio = New-Object System.Windows.Forms.RadioButton
    $fullUninstallRadio.Text = "Complete removal - Remove all data including add-ins and preferences"
    $fullUninstallRadio.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $fullUninstallRadio.Location = New-Object System.Drawing.Point(10, 5)
    $fullUninstallRadio.Size = New-Object System.Drawing.Size(580, 25)
    $fullUninstallRadio.Checked = $true
    $fullUninstallRadio.FlatStyle = 'Flat'
    
    $reinstallRadio = New-Object System.Windows.Forms.RadioButton
    $reinstallRadio.Text = "Reinstall preparation - Preserve licensing, add-ins, and shared components"
    $reinstallRadio.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $reinstallRadio.Location = New-Object System.Drawing.Point(10, 30)
    $reinstallRadio.Size = New-Object System.Drawing.Size(580, 25)
    $reinstallRadio.FlatStyle = 'Flat'
    
    $radioPanel.Controls.Add($fullUninstallRadio)
    $radioPanel.Controls.Add($reinstallRadio)
    
    return $fullUninstallRadio, $reinstallRadio
}

<#
.SYNOPSIS
    Creates the button panel
.DESCRIPTION
    Creates and configures the button panel with Uninstall and Cancel buttons
.PARAMETER Form
    The parent form to add the panel to
.OUTPUTS
    Tuple containing the uninstall and cancel buttons
#>
function New-ButtonPanel {
    param([System.Windows.Forms.Form]$Form)
    
    # Modern styled buttons
    $buttonPanel = New-Object System.Windows.Forms.Panel
    $buttonPanel.Location = New-Object System.Drawing.Point(0, 600)
    $buttonPanel.Size = New-Object System.Drawing.Size(920, 60)
    $buttonPanel.BackColor = [System.Drawing.Color]::FromArgb(249, 249, 249)
    $Form.Controls.Add($buttonPanel)
    
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
    
    return $uninstallButton, $cancelButton
}

<#
.SYNOPSIS
    Shows a message dialog
.DESCRIPTION
    Displays a modern message dialog with custom icon and message
.PARAMETER Title
    The title of the dialog
.PARAMETER Message
    The message to display
.PARAMETER Icon
    The Unicode icon to display
.PARAMETER Size
    The size of the dialog (default: 420x200)
#>
function Show-MessageDialog {
    param(
        [string]$Title,
        [string]$Message,
        [string]$Icon,
        [System.Drawing.Size]$Size = (New-Object System.Drawing.Size(420, 200))
    )
    
    $dialog = New-Object System.Windows.Forms.Form
    $dialog.Text = $Title
    $dialog.Size = $Size
    $dialog.StartPosition = "CenterScreen"
    $dialog.FormBorderStyle = 'FixedSingle'
    $dialog.MaximizeBox = $false
    $dialog.BackColor = [System.Drawing.Color]::White
    
    # Icon
    $iconLabel = New-Object System.Windows.Forms.Label
    $iconLabel.Text = $Icon
    $iconLabel.Font = New-Object System.Drawing.Font("Segoe UI Emoji", 32)
    $iconLabel.Location = New-Object System.Drawing.Point(175, 20)
    $iconLabel.Size = New-Object System.Drawing.Size(70, 50)
    $iconLabel.TextAlign = 'MiddleCenter'
    $dialog.Controls.Add($iconLabel)
    
    # Message
    $msgLabel = New-Object System.Windows.Forms.Label
    $msgLabel.Text = $Message
    $msgLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $msgLabel.Location = New-Object System.Drawing.Point(40, 80)
    $msgLabel.Size = New-Object System.Drawing.Size(340, 40)
    $msgLabel.TextAlign = 'MiddleCenter'
    $dialog.Controls.Add($msgLabel)
    
    # OK Button
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
    $dialog.Controls.Add($okButton)
    
    return $dialog.ShowDialog()
}

<#
.SYNOPSIS
    Shows a confirmation dialog
.DESCRIPTION
    Displays a confirmation dialog with product list and options
.OUTPUTS
    Boolean indicating if user confirmed
#>
function Show-ConfirmationDialog {
    $selectedProducts = Get-SelectedProducts
    $uninstallMode = Get-UninstallMode
    
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
    $selectedProducts = @(Get-SelectedProducts)
    $productCount = $selectedProducts.Count
    $message = "You are about to uninstall $productCount product(s)`n`n"
    $message += "Mode: $uninstallMode uninstall`n`n"
    
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
    foreach ($product in $selectedProducts) {
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
    return ($result -eq [System.Windows.Forms.DialogResult]::Yes)
}

<#
.SYNOPSIS
    Shows the summary dialog
.DESCRIPTION
    Displays a summary dialog with uninstallation results
.PARAMETER SuccessCount
    Number of successful uninstalls
.PARAMETER FailCount
    Number of failed uninstalls
#>
function Show-SummaryDialog {
    param(
        [int]$SuccessCount,
        [int]$FailCount
    )
    
    $logPath = Get-LogPath
    $addInsBackupPath = Get-AddInsBackupPath
    
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
    $successStat.Text = "$SuccessCount`nSuccessful"
    $successStat.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $successStat.ForeColor = [System.Drawing.Color]::FromArgb(52, 199, 89)
    $successStat.Location = New-Object System.Drawing.Point(100, 15)
    $successStat.Size = New-Object System.Drawing.Size(100, 50)
    $successStat.TextAlign = 'MiddleCenter'
    $statsPanel.Controls.Add($successStat)
    
    # Failed count
    $failStat = New-Object System.Windows.Forms.Label
    $failStat.Text = "$FailCount`nFailed"
    $failStat.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $failStat.ForeColor = if ($FailCount -gt 0) { [System.Drawing.Color]::FromArgb(255, 59, 48) } else { [System.Drawing.Color]::FromArgb(142, 142, 147) }
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
    
    $detailsText = "Logs saved to:`n$logPath`n"
    if ($addInsBackupPath) {
        $detailsText += "`nAdd-ins backed up to:`n$addInsBackupPath"
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

# Export functions
Export-ModuleMember -Function @(
    'Show-ProductSelectionGUI',
    'Show-MessageDialog',
    'Show-ConfirmationDialog',
    'Show-SummaryDialog'
)
