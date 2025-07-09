<#
.SYNOPSIS
    Progress window module for Autodesk Uninstaller
.DESCRIPTION
    Handles progress window display and updates
#>

<#
.SYNOPSIS
    Shows or updates the progress window
.DESCRIPTION
    Displays a progress window with status and percentage
.PARAMETER Title
    The title of the progress window
.PARAMETER Status
    The current status message
.PARAMETER PercentComplete
    The completion percentage (0-100)
#>
function Show-ProgressWindow {
    param(
        [string]$Title,
        [string]$Status,
        [int]$PercentComplete = 0
    )
    
    $progressForm = Get-ProgressForm
    $progressLabel = Get-ProgressLabel
    $progressBar = Get-ProgressBar
    
    if (-not $progressForm) {
        $progressForm = New-Object System.Windows.Forms.Form
        $progressForm.Text = $Title
        $progressForm.Size = New-Object System.Drawing.Size(520, 180)
        $progressForm.StartPosition = "CenterScreen"
        $progressForm.FormBorderStyle = 'FixedSingle'
        $progressForm.MaximizeBox = $false
        $progressForm.MinimizeBox = $false
        $progressForm.BackColor = [System.Drawing.Color]::White
        $progressForm.ControlBox = $false
        
        # Progress icon
        $iconLabel = New-Object System.Windows.Forms.Label
        $iconLabel.Text = [char]::ConvertFromUtf32(0x2699)  # Gear emoji
        $iconLabel.Font = New-Object System.Drawing.Font("Segoe UI Emoji", 32)
        $iconLabel.Location = New-Object System.Drawing.Point(40, 25)
        $iconLabel.Size = New-Object System.Drawing.Size(60, 60)
        $progressForm.Controls.Add($iconLabel)
        
        $progressLabel = New-Object System.Windows.Forms.Label
        $progressLabel.Location = New-Object System.Drawing.Point(110, 35)
        $progressLabel.Size = New-Object System.Drawing.Size(360, 40)
        $progressLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11)
        $progressLabel.Text = $Status
        
        $progressBar = New-Object System.Windows.Forms.ProgressBar
        $progressBar.Location = New-Object System.Drawing.Point(40, 100)
        $progressBar.Size = New-Object System.Drawing.Size(440, 8)
        $progressBar.Style = 'Continuous'
        $progressBar.MarqueeAnimationSpeed = 30
        
        # Style the progress bar
        $progressBar.ForeColor = [System.Drawing.Color]::FromArgb(0, 122, 255)
        $progressBar.BackColor = [System.Drawing.Color]::FromArgb(229, 229, 234)
        
        $progressForm.Controls.Add($progressLabel)
        $progressForm.Controls.Add($progressBar)
        
        Set-ProgressForm -value $progressForm
        Set-ProgressLabel -value $progressLabel
        Set-ProgressBar -value $progressBar
        
        $progressForm.Show()
    }
    
    $progressLabel.Text = $Status
    $progressBar.Value = $PercentComplete
    $progressForm.Refresh()
    [System.Windows.Forms.Application]::DoEvents()
}

<#
.SYNOPSIS
    Closes the progress window
.DESCRIPTION
    Closes and disposes of the progress window
#>
function Close-ProgressWindow {
    $progressForm = Get-ProgressForm
    if ($progressForm) {
        $progressForm.Close()
        Set-ProgressForm -value $null
        Set-ProgressLabel -value $null
        Set-ProgressBar -value $null
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Show-ProgressWindow',
    'Close-ProgressWindow'
)
