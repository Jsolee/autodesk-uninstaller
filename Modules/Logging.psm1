<#
.SYNOPSIS
    Logging module for Autodesk Uninstaller
.DESCRIPTION
    Handles all logging operations including initialization and writing to log files
#>

<#
.SYNOPSIS
    Initializes the logging system
.DESCRIPTION
    Creates log directory and files, starts transcript logging
#>
function Initialize-Logging {
    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $config = Get-Config
    $logPath = $config.LogRootPath
    Set-LogPath -value $logPath
    
    [void](New-Item -ItemType Directory -Path $logPath -Force)
    
    $actionLog = "$logPath\AutodeskUninstaller_Actions_$timestamp.log"
    $transcriptLog = "$logPath\AutodeskUninstaller_Transcript_$timestamp.log"
    
    Set-ActionLog -value $actionLog
    Set-TranscriptLog -value $transcriptLog
    
    Start-Transcript -Path $transcriptLog
}

<#
.SYNOPSIS
    Writes a message to the action log
.DESCRIPTION
    Adds a timestamped message to the action log file
.PARAMETER Message
    The message to write to the log
#>
function Write-ActionLog {
    param([string]$Message)
    
    $actionLog = Get-ActionLog
    if ($actionLog) {
        $timestampedMsg = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message"
        Add-Content -Path $actionLog -Value $timestampedMsg -Encoding UTF8
    }
}

<#
.SYNOPSIS
    Stops the transcript logging
.DESCRIPTION
    Stops the PowerShell transcript that was started during initialization
#>
function Stop-LoggingTranscript {
    try {
        Stop-Transcript
    } catch {
        # Transcript may not be running
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Initialize-Logging',
    'Write-ActionLog',
    'Stop-LoggingTranscript'
)
