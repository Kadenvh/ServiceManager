# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║                         🚀 SERVICE MANAGER 🚀                               ║
# ║                          ⚡ Built for Power Users ⚡                         ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

# Set working directory to script location
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path -Parent $scriptPath
Set-Location -Path $scriptDir

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Windows.Forms.Application]::EnableVisualStyles()
[System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)

# ═══════════════════════════════════════════════════════════════════════════════
# 🔧 SETUP CHECK & INITIALIZATION
# ═══════════════════════════════════════════════════════════════════════════════

Write-Host "🚀 ServiceManager Starting..." -ForegroundColor Cyan

# Check if setup script exists
if (-not (Test-Path ".\ServiceManager-PSADMIN-setup.ps1")) {
    Write-Host "❌ Setup script not found" -ForegroundColor Red
    [System.Windows.Forms.MessageBox]::Show(
        "ServiceManager-PSADMIN-setup.ps1 not found.`n`nPlease ensure all required files are present in the directory.",
        "Setup Required",
        "OK",
        "Error"
    )
    exit 1
}

# Check if user_config exists, if not run setup
if (-not (Test-Path ".\user_config")) {
    Write-Host "📁 User configuration not found - running setup..." -ForegroundColor Yellow
    
    # Run setup wizard
    try {
        $setupResult = & ".\ServiceManager-PSADMIN-setup.ps1" -IntegratedSetup
        if (-not $setupResult) {
            Write-Host "❌ Setup failed or was cancelled" -ForegroundColor Red
            [System.Windows.Forms.MessageBox]::Show(
                "Setup was not completed.`n`nPlease run ServiceManager-PSADMIN-setup.ps1 to configure the application.",
                "Setup Required",
                "OK",
                "Warning"
            )
            exit 1
        }
    } catch {
        Write-Host "❌ Setup failed to run: $($_.Exception.Message)" -ForegroundColor Red
        [System.Windows.Forms.MessageBox]::Show(
            "Failed to run setup:`n`n$($_.Exception.Message)`n`nPlease run ServiceManager-PSADMIN-setup.ps1 manually.",
            "Setup Error",
            "OK",
            "Error"
        )
        exit 1
    }
}

# Verify user configuration files exist and are valid
$configFiles = @(
    @{ Path = ".\user_config\scripts_storage.json"; Name = "Scripts Storage" },
    @{ Path = ".\user_config\app_settings.json"; Name = "App Settings" }
)

foreach ($file in $configFiles) {
    if (-not (Test-Path $file.Path)) {
        Write-Host "❌ $($file.Name) file missing" -ForegroundColor Red
        [System.Windows.Forms.MessageBox]::Show(
            "$($file.Name) file is missing.`n`nPlease run ServiceManager-PSADMIN-setup.ps1 to reconfigure.",
            "Configuration Missing",
            "OK",
            "Error"
        )
        exit 1
    }
    
    try {
        $null = Get-Content $file.Path -Raw | ConvertFrom-Json
    } catch {
        Write-Host "❌ Invalid $($file.Name) file" -ForegroundColor Red
        [System.Windows.Forms.MessageBox]::Show(
            "$($file.Name) file is corrupted.`n`nPlease run ServiceManager-PSADMIN-setup.ps1 to reconfigure.",
            "Invalid Configuration",
            "OK",
            "Error"
        )
        exit 1
    }
}

Write-Host "✅ User configuration verified" -ForegroundColor Green

# Modern Color Palette
$global:Theme = @{
    Primary = [System.Drawing.Color]::FromArgb(64, 128, 255)
    Secondary = [System.Drawing.Color]::FromArgb(100, 200, 100)
    Accent = [System.Drawing.Color]::FromArgb(255, 165, 0)
    Danger = [System.Drawing.Color]::FromArgb(255, 85, 85)
    Dark = [System.Drawing.Color]::FromArgb(45, 45, 48)
    Light = [System.Drawing.Color]::FromArgb(248, 249, 250)
    Surface = [System.Drawing.Color]::FromArgb(255, 255, 255)
    Text = [System.Drawing.Color]::FromArgb(33, 37, 41)
    TextMuted = [System.Drawing.Color]::FromArgb(108, 117, 125)
}

# Global Configuration - Now using user_config directory
$global:ConfigFile = ".\user_config\scripts_storage.json"
$global:SettingsFile = ".\user_config\app_settings.json"
$global:LogEntries = [System.Collections.ArrayList]::new()
$global:ActiveTabs = @{}

# Enhanced Extension Support
$global:SupportedTypes = @{
    "Script" = @{
        ".ps1" = @{
            name = "PowerShell Script"
            icon = "🔵"
            validator = "Test-PowerShellScript"
        }
    }
    "Application" = @{
        ".exe" = @{
            name = "Windows Application"
            icon = "⚙️"
            validator = "Test-ExecutableApp"
        }
        ".msi" = @{
            name = "Installer Package"
            icon = "📦"
            validator = "Test-ExecutableApp"
        }
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🔧 CONFIGURATION MANAGEMENT
# ═══════════════════════════════════════════════════════════════════════════════

function Load-AppSettings {
    if (Test-Path $global:SettingsFile) {
        try {
            return Get-Content $global:SettingsFile -Raw | ConvertFrom-Json
        } catch {
            Add-LogEntry "Settings corrupted, creating defaults" "Warning"
            return Create-DefaultSettings
        }
    } else {
        return Create-DefaultSettings
    }
}

function Create-DefaultSettings {
    $defaultSettings = @{
        version = "2.0"
        serviceManagerPath = ".\ServiceManager.ps1"
        defaultScriptLocation = ".\"
        autoOrganizeScripts = $true
        theme = "Modern"
        enableNotifications = $true
        firstRun = $false
    }
    Save-AppSettings $defaultSettings
    return $defaultSettings
}

function Save-AppSettings {
    param($settings)
    try {
        $settings | ConvertTo-Json -Depth 10 | Set-Content $global:SettingsFile
        return $true
    } catch {
        Add-LogEntry "Failed to save settings: $($_.Exception.Message)" "Error"
        return $false
    }
}

function Load-ScriptConfig {
    if (Test-Path $global:ConfigFile) {
        try {
            $configData = Get-Content $global:ConfigFile -Raw | ConvertFrom-Json
            if ($configData -is [array]) {
                $config = $configData[1]
                if (-not $config.version) { $config.version = "1.0" }
            } else {
                $config = $configData
            }
            return $config
        } catch {
            Add-LogEntry "Config corrupted, creating new one" "Warning"
            return Create-DefaultConfig
        }
    } else {
        return Create-DefaultConfig
    }
}

function Create-DefaultConfig {
    $defaultConfig = @{
        version = "2.0"
        lastModified = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        scripts = @()
        categories = @("AI Services", "Automation", "Development", "System", "Applications", "Custom")
        statistics = @{
            totalExecutions = 0
            favoriteScripts = @()
        }
    }
    Save-ScriptConfig $defaultConfig
    return $defaultConfig
}

function Save-ScriptConfig {
    param($config)
    try {
        $config.lastModified = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        $config | ConvertTo-Json -Depth 10 | Set-Content $global:ConfigFile
        return $true
    } catch {
        Add-LogEntry "Failed to save configuration: $($_.Exception.Message)" "Error"
        return $false
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# 📝 ENHANCED LOGGING SYSTEM
# ═══════════════════════════════════════════════════════════════════════════════

function Add-LogEntry {
    param([string]$message, [string]$level = "Info")
    
    $timestamp = Get-Date -Format "HH:mm:ss"
    $levelIcon = switch ($level) {
        "Success" { "✅" }
        "Warning" { "⚠️" }
        "Error" { "❌" }
        "Info" { "ℹ️" }
        default { "📝" }
    }
    
    $logMessage = "[$timestamp] $levelIcon $message"
    [void]$global:LogEntries.Add(@{ Message = $logMessage; Level = $level; Timestamp = Get-Date })
    
    if ($global:LogTextBox) {
        $color = switch ($level) {
            "Success" { [System.Drawing.Color]::LightGreen }
            "Warning" { [System.Drawing.Color]::Yellow }
            "Error" { [System.Drawing.Color]::LightCoral }
            default { [System.Drawing.Color]::LightGray }
        }
        
        $global:LogTextBox.SelectionStart = $global:LogTextBox.Text.Length
        $global:LogTextBox.SelectionColor = $color
        $global:LogTextBox.AppendText("$logMessage`r`n")
        $global:LogTextBox.ScrollToCaret()
    }
    
    $consoleColor = switch ($level) {
        "Success" { "Green" }
        "Warning" { "Yellow" }
        "Error" { "Red" }
        default { "Gray" }
    }
    Write-Host $logMessage -ForegroundColor $consoleColor
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🔍 VALIDATION SYSTEM
# ═══════════════════════════════════════════════════════════════════════════════

function Test-PowerShellScript {
    param($FilePath)
    
    $result = @{ IsValid = $false; Errors = @(); Warnings = @(); Suggestions = @(); Score = 0 }
    
    try {
        if (-not (Test-Path $FilePath)) {
            $result.Errors += "File not found: $FilePath"
            return $result
        }
        
        $fileInfo = Get-Item $FilePath
        if ($fileInfo.Length -eq 0) {
            $result.Errors += "File is empty"
            return $result
        }
        
        $content = Get-Content $FilePath -Raw
        
        try {
            $null = [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$null, [ref]$null)
            $result.Score += 30
        } catch {
            $result.Errors += "PowerShell syntax error: $($_.Exception.Message)"
        }
        
        if ($content -match '\$scriptPath.*Split-Path.*MyInvocation\.MyCommand\.Path') {
            $result.Score += 20
            $result.Suggestions += "✅ Proper path setup detected"
        }
        
        if ($content -match 'Set-Location.*\$scriptPath') {
            $result.Score += 15
        }
        
        if ($content -match 'Write-Host|Write-Output') {
            $result.Score += 10
            $result.Suggestions += "✅ Output/logging detected"
        }
        
        if ($content -match 'try\s*{.*}.*catch|trap') {
            $result.Score += 15
            $result.Suggestions += "✅ Error handling detected"
        }
        
        $result.IsValid = ($result.Errors.Count -eq 0) -and ($result.Score -ge 30)
        
    } catch {
        $result.Errors += "Validation error: $($_.Exception.Message)"
    }
    
    return $result
}

function Test-ExecutableApp {
    param($FilePath)
    
    $result = @{ IsValid = $false; Errors = @(); Warnings = @(); Suggestions = @(); Score = 0 }
    
    try {
        if (-not (Test-Path $FilePath)) {
            $result.Errors += "Application not found: $FilePath"
            return $result
        }
        
        $fileInfo = Get-Item $FilePath
        
        if ($fileInfo.Extension -notin @('.exe', '.msi', '.bat', '.cmd')) {
            $result.Errors += "Not a valid executable file"
            return $result
        }
        
        if ($fileInfo.Length -eq 0) {
            $result.Errors += "Executable file is empty or corrupted"
            return $result
        }
        
        try {
            $versionInfo = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($FilePath)
            if ($versionInfo.FileDescription) {
                $result.Suggestions += "✅ Application: $($versionInfo.FileDescription)"
                $result.Score += 20
            }
            if ($versionInfo.FileVersion) {
                $result.Suggestions += "✅ Version: $($versionInfo.FileVersion)"
                $result.Score += 10
            }
        } catch {
            $result.Warnings += "Could not read version information"
        }
        
        try {
            $signature = Get-AuthenticodeSignature $FilePath -ErrorAction SilentlyContinue
            if ($signature.Status -eq 'Valid') {
                $result.Suggestions += "✅ Digitally signed and trusted"
                $result.Score += 25
            } elseif ($signature.Status -eq 'NotSigned') {
                $result.Warnings += "Application is not digitally signed"
            }
        } catch { }
        
        $result.Score += 45
        $result.IsValid = ($result.Errors.Count -eq 0)
        
    } catch {
        $result.Errors += "Validation error: $($_.Exception.Message)"
    }
    
    return $result
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🚀 ENHANCED ADD DIALOG
# ═══════════════════════════════════════════════════════════════════════════════

# ═══════════════════════════════════════════════════════════════════════════════
# 🔄 UI REFRESH FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

function Get-ServiceStatus {
    param($service)
    
    $fullPath = Join-Path $service.directory "$($service.fileName)$($service.extension)"
    
    if (-not (Test-Path $fullPath)) {
        return @{ Status = "Missing"; Color = "Red"; Icon = "🔴" }
    }
    
    try {
        if ($service.mode -eq "Application") {
            $validation = Test-ExecutableApp $fullPath
        } else {
            $validation = Test-PowerShellScript $fullPath
        }
        
        if ($validation.IsValid) {
            return @{ Status = "Ready"; Color = "Green"; Icon = "🟢" }
        } else {
            return @{ Status = "Error"; Color = "Orange"; Icon = "🟠" }
        }
    } catch {
        return @{ Status = "Error"; Color = "Red"; Icon = "🔴" }
    }
}

function Get-ServiceRunningState {
    param($service)
    
    try {
        if ($service.mode -eq "Application") {
            # Check if the application process is running
            $processName = [System.IO.Path]::GetFileNameWithoutExtension($service.fileName)
            $runningProcesses = Get-Process -Name $processName -ErrorAction SilentlyContinue
            
            if ($runningProcesses) {
                return @{ IsRunning = $true; Icon = "⏹️"; Color = [System.Drawing.Color]::FromArgb(200, 220, 53, 69); Tooltip = "Stop $($service.name)" }
            } else {
                return @{ IsRunning = $false; Icon = "▶️"; Color = [System.Drawing.Color]::FromArgb(200, 40, 167, 69); Tooltip = "Start $($service.name)" }
            }
        } else {
            # For scripts, check if there are PowerShell processes running this script
            $scriptProcesses = Get-Process -Name "powershell" -ErrorAction SilentlyContinue | Where-Object {
                $_.CommandLine -like "*$($service.fileName)*" -or $_.MainWindowTitle -like "*$($service.name)*"
            }
            
            if ($scriptProcesses) {
                return @{ IsRunning = $true; Icon = "⏹️"; Color = [System.Drawing.Color]::FromArgb(200, 220, 53, 69); Tooltip = "Stop $($service.name)" }
            } else {
                return @{ IsRunning = $false; Icon = "▶️"; Color = [System.Drawing.Color]::FromArgb(200, 40, 167, 69); Tooltip = "Start $($service.name)" }
            }
        }
    } catch {
        # Default to start state if we can't determine running state
        return @{ IsRunning = $false; Icon = "▶️"; Color = [System.Drawing.Color]::FromArgb(200, 40, 167, 69); Tooltip = "Start $($service.name)" }
    }
}

function Stop-SingleService {
    param($service)
    
    try {
        Add-LogEntry "Attempting to stop: $($service.name)" "Info"
        
        if ($service.mode -eq "Application") {
            # Stop application process
            $processName = [System.IO.Path]::GetFileNameWithoutExtension($service.fileName)
            $runningProcesses = Get-Process -Name $processName -ErrorAction SilentlyContinue
            
            if ($runningProcesses) {
                foreach ($proc in $runningProcesses) {
                    $proc.CloseMainWindow()
                    Start-Sleep -Milliseconds 500
                    if (-not $proc.HasExited) {
                        $proc.Kill()
                    }
                }
                Add-LogEntry "Stopped application: $($service.name)" "Success"
                [System.Windows.Forms.MessageBox]::Show("✅ $($service.name) stopped successfully", "Service Stopped", "OK", "Information")
            } else {
                Add-LogEntry "No running instances found for: $($service.name)" "Warning"
            }
        } else {
            # Stop script processes
            $scriptProcesses = Get-Process -Name "powershell" -ErrorAction SilentlyContinue | Where-Object {
                $_.CommandLine -like "*$($service.fileName)*" -or $_.MainWindowTitle -like "*$($service.name)*"
            }
            
            if ($scriptProcesses) {
                foreach ($proc in $scriptProcesses) {
                    $proc.CloseMainWindow()
                    Start-Sleep -Milliseconds 500
                    if (-not $proc.HasExited) {
                        $proc.Kill()
                    }
                }
                Add-LogEntry "Stopped script: $($service.name)" "Success"
                [System.Windows.Forms.MessageBox]::Show("✅ $($service.name) stopped successfully", "Service Stopped", "OK", "Information")
            } else {
                Add-LogEntry "No running instances found for: $($service.name)" "Warning"
            }
        }
    } catch {
        $errorMsg = "Failed to stop $($service.name): $($_.Exception.Message)"
        Add-LogEntry $errorMsg "Error"
        [System.Windows.Forms.MessageBox]::Show($errorMsg, "Stop Error", "OK", "Error")
    }
}

# Duplicate functions removed - kept the ones below

function Remove-ServiceInstantly {
    param($service, $config, $servicesPanel)
    
    # Check if service is protected (built-in)
    if ($service.isBuiltIn -eq $true) {
        Add-LogEntry "Cannot remove built-in service: $($service.name)" "Warning"
        [System.Windows.Forms.MessageBox]::Show("Cannot remove built-in service: $($service.name)", "Protected Service", "OK", "Warning")
        return $false
    }
    
    # Remove from config
    $config.scripts = $config.scripts | Where-Object { 
        -not (($_.name -eq $service.name) -and ($_.directory -eq $service.directory))
    }
    
    # Save config
    if (Save-ScriptConfig $config) {
        # Update global config reference
        $script:config = $config
        
        # Refresh UI immediately
        Refresh-ServiceInterface $servicesPanel $config
        
        Add-LogEntry "Removed: $($service.name)" "Success"
        return $true
    }
    
    return $false
}

function Refresh-ServiceInterface {
    param($servicesPanel, $config)
    
    # Suspend layout for better performance
    $servicesPanel.SuspendLayout()
    
    # Clear existing controls
    $servicesPanel.Controls.Clear()
    
    # Check if there are any services to display
    if ($config.scripts.Count -eq 0) {
        # Show welcome message for new users
        $welcomeLabel = New-Object System.Windows.Forms.Label
        $welcomeLabel.Location = New-Object System.Drawing.Point(15, 50)
        $welcomeLabel.Size = New-Object System.Drawing.Size(440, 100)
        $welcomeLabel.Text = @"
🎉 Welcome to ServiceManager!

No services are currently configured.

Click '➕ Add Script/App' above to add your first PowerShell script or application.

You can manage both .ps1 scripts and .exe applications from this interface.
"@
        $welcomeLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11)
        $welcomeLabel.ForeColor = $global:Theme.TextMuted
        $welcomeLabel.TextAlign = "MiddleCenter"
        $servicesPanel.Controls.Add($welcomeLabel)
    } else {
        # Create service buttons with enhanced styling
        $buttonY = 15
        $buttonHeight = 35
        $buttonSpacing = 5
        $categorySpacing = 20
        
        # Group by category
        $groupedServices = $config.scripts | Group-Object category
        
        foreach ($categoryGroup in $groupedServices) {
            # Category header
            $categoryLabel = New-Object System.Windows.Forms.Label
            $categoryLabel.Location = New-Object System.Drawing.Point(15, $buttonY)
            $categoryLabel.Size = New-Object System.Drawing.Size(440, 18)
            $categoryLabel.Text = "📁 $($categoryGroup.Name)"
            $categoryLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
            $categoryLabel.ForeColor = $global:Theme.Primary
            $servicesPanel.Controls.Add($categoryLabel)
            
            $buttonY += $categorySpacing
            
            foreach ($service in $categoryGroup.Group) {
                # Get service status
                $status = Get-ServiceStatus $service
                $runningState = Get-ServiceRunningState $service
                
                # Create service container panel
                $servicePanel = New-Object System.Windows.Forms.Panel
                $servicePanel.Location = New-Object System.Drawing.Point(15, $buttonY)
                $servicePanel.Size = New-Object System.Drawing.Size(440, $buttonHeight)
                $servicePanel.BackColor = [System.Drawing.Color]::$($service.color)
                $servicePanel.BorderStyle = "None"
                
                # Start/Stop button (far left) - with smart state
                $startStopButton = New-Object System.Windows.Forms.Button
                $startStopButton.Location = New-Object System.Drawing.Point(2, 2)
                $startStopButton.Size = New-Object System.Drawing.Size(28, ($buttonHeight - 4))
                $startStopButton.Text = $runningState.Icon
                $startStopButton.BackColor = $runningState.Color
                $startStopButton.Font = New-Object System.Drawing.Font("Segoe UI", 10)
                $startStopButton.FlatStyle = "Flat"
                $startStopButton.ForeColor = [System.Drawing.Color]::White
                $startStopButton.Tag = @{ Service = $service; IsRunning = $runningState.IsRunning }
                $startStopButton.Cursor = "Hand"
                
                # Add tooltip
                $tooltip = New-Object System.Windows.Forms.ToolTip
                $tooltip.SetToolTip($startStopButton, $runningState.Tooltip)
                
                # Start/Stop button hover effects
                $startStopButton.Add_MouseEnter({
                    $originalColor = $this.BackColor
                    $this.BackColor = [System.Drawing.Color]::FromArgb(255, $originalColor.R, $originalColor.G, $originalColor.B)
                })
                $startStopButton.Add_MouseLeave({
                    $tagData = $this.Tag
                    if ($tagData.IsRunning) {
                        $this.BackColor = [System.Drawing.Color]::FromArgb(200, 220, 53, 69)
                    } else {
                        $this.BackColor = [System.Drawing.Color]::FromArgb(200, 40, 167, 69)
                    }
                })
                
                # Start/Stop button click event
                $startStopButton.Add_Click({
                    $tagData = $this.Tag
                    $svc = $tagData.Service
                    
                    if ($tagData.IsRunning) {
                        # Service is running, try to stop it
                        Stop-SingleService $svc
                    } else {
                        # Service is not running, start it
                        Execute-EnhancedService $svc $true
                    }
                    
                    # Refresh the interface to update button states
                    Start-Sleep -Milliseconds 500  # Brief delay to let process start/stop
                    Refresh-ServiceInterface $servicesPanel $script:config
                })
                
                # Main service button (middle section)
                $button = New-Object System.Windows.Forms.Button
                $button.Location = New-Object System.Drawing.Point(35, 0)
                $button.Size = New-Object System.Drawing.Size(340, $buttonHeight)
                $button.Text = "$($status.Icon) $($service.icon) $($service.name) $(if ($service.mode -eq 'Application') { '⚙️' } else { '📜' })"
                $button.BackColor = [System.Drawing.Color]::$($service.color)
                $button.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
                $button.FlatStyle = "Flat"
                $button.ForeColor = [System.Drawing.Color]::White
                $button.Tag = $service
                $button.TextAlign = "MiddleLeft"
                $button.Padding = New-Object System.Windows.Forms.Padding(15, 0, 0, 0)
                
                # Enhanced hover effects for main button
                $button.Add_MouseEnter({
                    $this.BackColor = [System.Drawing.Color]::FromArgb(220, $this.BackColor.R, $this.BackColor.G, $this.BackColor.B)
                    $this.Parent.BackColor = $this.BackColor
                })
                $button.Add_MouseLeave({
                    $this.BackColor = [System.Drawing.Color]::$($this.Tag.color)
                    $this.Parent.BackColor = $this.BackColor
                })
                
                # Click event for main button
                $button.Add_Click({
                    $svc = $this.Tag
                    Execute-EnhancedService $svc $true
                })
                
                # Add buttons to service panel
                $servicePanel.Controls.Add($startStopButton)
                $servicePanel.Controls.Add($button)
                
                # Only add trash button for non-built-in services
                if ($service.isBuiltIn -ne $true) {
                    # Trash button (far right, smaller)
                    $trashButton = New-Object System.Windows.Forms.Button
                    $trashButton.Location = New-Object System.Drawing.Point(410, 2)
                    $trashButton.Size = New-Object System.Drawing.Size(26, ($buttonHeight - 4))
                    $trashButton.Text = "🗑️"
                    $trashButton.BackColor = [System.Drawing.Color]::FromArgb(200, 220, 53, 69)
                    $trashButton.Font = New-Object System.Drawing.Font("Segoe UI", 10)
                    $trashButton.FlatStyle = "Flat"
                    $trashButton.ForeColor = [System.Drawing.Color]::White
                    $trashButton.Tag = $service
                    $trashButton.Cursor = "Hand"
                    
                    # Trash button hover effects
                    $trashButton.Add_MouseEnter({
                        $this.BackColor = [System.Drawing.Color]::FromArgb(255, 220, 53, 69)
                    })
                    $trashButton.Add_MouseLeave({
                        $this.BackColor = [System.Drawing.Color]::FromArgb(200, 220, 53, 69)
                    })
                    
                    # Trash button click event
                    $trashButton.Add_Click({
                        $svc = $this.Tag
                        if (Remove-ServiceInstantly $svc $script:config $servicesPanel) {
                            # No additional action needed - UI already refreshed
                        }
                    })
                    
                    $servicePanel.Controls.Add($trashButton)
                } else {
                    # For built-in services, extend main button to cover the trash area
                    $button.Size = New-Object System.Drawing.Size(405, $buttonHeight)
                }
                
                # Add service panel to main panel
                $servicesPanel.Controls.Add($servicePanel)
                $buttonY += ($buttonHeight + $buttonSpacing)
            }
            
            $buttonY += 10
        }
    }
    
    # Resume layout and refresh
    $servicesPanel.ResumeLayout($true)
    $servicesPanel.Refresh()
}

function Show-RestartDialog {
    param($title, $message)
    
    $restartForm = New-Object System.Windows.Forms.Form
    $restartForm.Text = $title
    $restartForm.Size = New-Object System.Drawing.Size(400, 200)
    $restartForm.StartPosition = "CenterParent"
    $restartForm.FormBorderStyle = "FixedDialog"
    $restartForm.MaximizeBox = $false
    $restartForm.MinimizeBox = $false
    $restartForm.BackColor = $global:Theme.Light
    
    $messageLabel = New-Object System.Windows.Forms.Label
    $messageLabel.Location = New-Object System.Drawing.Point(20, 20)
    $messageLabel.Size = New-Object System.Drawing.Size(340, 60)
    $messageLabel.Text = $message
    $messageLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11)
    $messageLabel.ForeColor = $global:Theme.Text
    $messageLabel.TextAlign = "MiddleCenter"
    $restartForm.Controls.Add($messageLabel)
    
    $restartNowButton = New-Object System.Windows.Forms.Button
    $restartNowButton.Location = New-Object System.Drawing.Point(80, 100)
    $restartNowButton.Size = New-Object System.Drawing.Size(100, 35)
    $restartNowButton.Text = "🔄 Restart Now"
    $restartNowButton.BackColor = $global:Theme.Primary
    $restartNowButton.ForeColor = [System.Drawing.Color]::White
    $restartNowButton.FlatStyle = "Flat"
    $restartNowButton.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $restartNowButton.DialogResult = "Yes"
    $restartForm.Controls.Add($restartNowButton)
    
    $restartLaterButton = New-Object System.Windows.Forms.Button
    $restartLaterButton.Location = New-Object System.Drawing.Point(200, 100)
    $restartLaterButton.Size = New-Object System.Drawing.Size(100, 35)
    $restartLaterButton.Text = "⏰ Later"
    $restartLaterButton.BackColor = $global:Theme.TextMuted
    $restartLaterButton.ForeColor = [System.Drawing.Color]::White
    $restartLaterButton.FlatStyle = "Flat"
    $restartLaterButton.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $restartLaterButton.DialogResult = "No"
    $restartForm.Controls.Add($restartLaterButton)
    
    $result = $restartForm.ShowDialog()
    $restartForm.Dispose()
    
    if ($result -eq "Yes") {
        $form.Close()
        Start-Process -FilePath "powershell" -ArgumentList "-ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`""
    }
}

function Show-EnhancedAddDialog {
    param($config, $servicesPanel)
    
    $addForm = New-Object System.Windows.Forms.Form
    $addForm.Text = "Add New Item - ServiceManager"
    $addForm.Size = New-Object System.Drawing.Size(600, 550)
    $addForm.StartPosition = "CenterParent"
    $addForm.FormBorderStyle = "FixedDialog"
    $addForm.MaximizeBox = $false
    $addForm.MinimizeBox = $false
    $addForm.BackColor = $global:Theme.Light
    
    # Header
    $headerPanel = New-Object System.Windows.Forms.Panel
    $headerPanel.Location = New-Object System.Drawing.Point(0, 0)
    $headerPanel.Size = New-Object System.Drawing.Size(600, 60)
    $headerPanel.BackColor = $global:Theme.Primary
    $addForm.Controls.Add($headerPanel)
    
    $headerLabel = New-Object System.Windows.Forms.Label
    $headerLabel.Location = New-Object System.Drawing.Point(20, 15)
    $headerLabel.Size = New-Object System.Drawing.Size(560, 30)
    $headerLabel.Text = "🚀 Add New Script or Application"
    $headerLabel.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
    $headerLabel.ForeColor = [System.Drawing.Color]::White
    $headerPanel.Controls.Add($headerLabel)
    
    # Tab Control
    $tabControl = New-Object System.Windows.Forms.TabControl
    $tabControl.Location = New-Object System.Drawing.Point(20, 80)
    $tabControl.Size = New-Object System.Drawing.Size(560, 380)
    $addForm.Controls.Add($tabControl)
    
    # Script Tab
    $scriptTab = New-Object System.Windows.Forms.TabPage
    $scriptTab.Text = "📜 PowerShell Script"
    $scriptTab.BackColor = $global:Theme.Surface
    $tabControl.TabPages.Add($scriptTab)
    
    # Script fields
    $fileLabel = New-Object System.Windows.Forms.Label
    $fileLabel.Location = New-Object System.Drawing.Point(20, 30)
    $fileLabel.Size = New-Object System.Drawing.Size(100, 25)
    $fileLabel.Text = "📝 Script Name:"
    $fileLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $scriptTab.Controls.Add($fileLabel)
    
    $fileNameTextBox = New-Object System.Windows.Forms.TextBox
    $fileNameTextBox.Location = New-Object System.Drawing.Point(130, 28)
    $fileNameTextBox.Size = New-Object System.Drawing.Size(280, 25)
    $fileNameTextBox.Text = "MyScript"
    $scriptTab.Controls.Add($fileNameTextBox)
    
    $extensionCombo = New-Object System.Windows.Forms.ComboBox
    $extensionCombo.Location = New-Object System.Drawing.Point(420, 28)
    $extensionCombo.Size = New-Object System.Drawing.Size(80, 25)
    $extensionCombo.DropDownStyle = "DropDownList"
    $extensionCombo.Items.AddRange(@(".ps1"))
    $extensionCombo.SelectedIndex = 0
    $scriptTab.Controls.Add($extensionCombo)
    
    $typeLabel = New-Object System.Windows.Forms.Label
    $typeLabel.Location = New-Object System.Drawing.Point(20, 70)
    $typeLabel.Size = New-Object System.Drawing.Size(100, 25)
    $typeLabel.Text = "⚙️ Type:"
    $typeLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $scriptTab.Controls.Add($typeLabel)
    
    $typeCombo = New-Object System.Windows.Forms.ComboBox
    $typeCombo.Location = New-Object System.Drawing.Point(130, 68)
    $typeCombo.Size = New-Object System.Drawing.Size(120, 25)
    $typeCombo.DropDownStyle = "DropDownList"
    $typeCombo.Items.AddRange(@("start", "stop", "utility"))
    $typeCombo.SelectedIndex = 0
    $scriptTab.Controls.Add($typeCombo)
    
    $categoryLabel = New-Object System.Windows.Forms.Label
    $categoryLabel.Location = New-Object System.Drawing.Point(270, 70)
    $categoryLabel.Size = New-Object System.Drawing.Size(80, 25)
    $categoryLabel.Text = "🏷️ Category:"
    $categoryLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $scriptTab.Controls.Add($categoryLabel)
    
    $categoryCombo = New-Object System.Windows.Forms.ComboBox
    $categoryCombo.Location = New-Object System.Drawing.Point(350, 68)
    $categoryCombo.Size = New-Object System.Drawing.Size(150, 25)
    $categoryCombo.DropDownStyle = "DropDownList"
    $categoryCombo.Items.AddRange($config.categories)
    $categoryCombo.SelectedIndex = 0
    $scriptTab.Controls.Add($categoryCombo)
    
    $dirLabel = New-Object System.Windows.Forms.Label
    $dirLabel.Location = New-Object System.Drawing.Point(20, 110)
    $dirLabel.Size = New-Object System.Drawing.Size(100, 25)
    $dirLabel.Text = "📁 Directory:"
    $dirLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $scriptTab.Controls.Add($dirLabel)
    
    $dirTextBox = New-Object System.Windows.Forms.TextBox
    $dirTextBox.Location = New-Object System.Drawing.Point(130, 108)
    $dirTextBox.Size = New-Object System.Drawing.Size(300, 25)
    $scriptTab.Controls.Add($dirTextBox)
    
    $browseButton = New-Object System.Windows.Forms.Button
    $browseButton.Location = New-Object System.Drawing.Point(440, 107)
    $browseButton.Size = New-Object System.Drawing.Size(60, 27)
    $browseButton.Text = "Browse"
    $browseButton.BackColor = $global:Theme.Secondary
    $browseButton.ForeColor = [System.Drawing.Color]::White
    $browseButton.FlatStyle = "Flat"
    $browseButton.Add_Click({
        $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
        if ($folderDialog.ShowDialog() -eq "OK") {
            $dirTextBox.Text = $folderDialog.SelectedPath
        }
    })
    $scriptTab.Controls.Add($browseButton)
    
    $fileSelectButton = New-Object System.Windows.Forms.Button
    $fileSelectButton.Location = New-Object System.Drawing.Point(130, 148)
    $fileSelectButton.Size = New-Object System.Drawing.Size(120, 27)
    $fileSelectButton.Text = "Select File..."
    $fileSelectButton.BackColor = $global:Theme.Accent
    $fileSelectButton.ForeColor = [System.Drawing.Color]::White
    $fileSelectButton.FlatStyle = "Flat"
    $fileSelectButton.Add_Click({
        $fileDialog = New-Object System.Windows.Forms.OpenFileDialog
        $fileDialog.Filter = "PowerShell Scripts (*.ps1)|*.ps1"
        
        if ($fileDialog.ShowDialog() -eq "OK") {
            $fileInfo = Get-Item $fileDialog.FileName
            $fileNameTextBox.Text = [System.IO.Path]::GetFileNameWithoutExtension($fileDialog.FileName)
            $dirTextBox.Text = $fileInfo.DirectoryName
            
            $fileName = $fileInfo.Name.ToLower()
            if ($fileName -like "*start*") {
                $typeCombo.SelectedItem = "start"
            } elseif ($fileName -like "*stop*" -or $fileName -like "*kill*") {
                $typeCombo.SelectedItem = "stop"
            }
        }
    })
    $scriptTab.Controls.Add($fileSelectButton)
    
    # Application Tab
    $appTab = New-Object System.Windows.Forms.TabPage
    $appTab.Text = "⚙️ Application / EXE"
    $appTab.BackColor = $global:Theme.Surface
    $tabControl.TabPages.Add($appTab)
    
    # Application fields
    $appNameLabel = New-Object System.Windows.Forms.Label
    $appNameLabel.Location = New-Object System.Drawing.Point(20, 30)
    $appNameLabel.Size = New-Object System.Drawing.Size(100, 25)
    $appNameLabel.Text = "⚙️ App Name:"
    $appNameLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $appTab.Controls.Add($appNameLabel)
    
    $appNameTextBox = New-Object System.Windows.Forms.TextBox
    $appNameTextBox.Location = New-Object System.Drawing.Point(130, 28)
    $appNameTextBox.Size = New-Object System.Drawing.Size(280, 25)
    $appNameTextBox.Text = "MyApplication"
    $appTab.Controls.Add($appNameTextBox)
    
    $appExtensionCombo = New-Object System.Windows.Forms.ComboBox
    $appExtensionCombo.Location = New-Object System.Drawing.Point(420, 28)
    $appExtensionCombo.Size = New-Object System.Drawing.Size(80, 25)
    $appExtensionCombo.DropDownStyle = "DropDownList"
    $appExtensionCombo.Items.AddRange(@(".exe", ".msi"))
    $appExtensionCombo.SelectedIndex = 0
    $appTab.Controls.Add($appExtensionCombo)
    
    $appDirLabel = New-Object System.Windows.Forms.Label
    $appDirLabel.Location = New-Object System.Drawing.Point(20, 70)
    $appDirLabel.Size = New-Object System.Drawing.Size(100, 25)
    $appDirLabel.Text = "📁 Directory:"
    $appDirLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $appTab.Controls.Add($appDirLabel)
    
    $appDirTextBox = New-Object System.Windows.Forms.TextBox
    $appDirTextBox.Location = New-Object System.Drawing.Point(130, 68)
    $appDirTextBox.Size = New-Object System.Drawing.Size(300, 25)
    $appTab.Controls.Add($appDirTextBox)
    
    $appBrowseButton = New-Object System.Windows.Forms.Button
    $appBrowseButton.Location = New-Object System.Drawing.Point(440, 67)
    $appBrowseButton.Size = New-Object System.Drawing.Size(60, 27)
    $appBrowseButton.Text = "Browse"
    $appBrowseButton.BackColor = $global:Theme.Secondary
    $appBrowseButton.ForeColor = [System.Drawing.Color]::White
    $appBrowseButton.FlatStyle = "Flat"
    $appBrowseButton.Add_Click({
        $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
        if ($folderDialog.ShowDialog() -eq "OK") {
            $appDirTextBox.Text = $folderDialog.SelectedPath
        }
    })
    $appTab.Controls.Add($appBrowseButton)
    
    $appFileSelectButton = New-Object System.Windows.Forms.Button
    $appFileSelectButton.Location = New-Object System.Drawing.Point(130, 110)
    $appFileSelectButton.Size = New-Object System.Drawing.Size(120, 27)
    $appFileSelectButton.Text = "Browse for EXE..."
    $appFileSelectButton.BackColor = $global:Theme.Primary
    $appFileSelectButton.ForeColor = [System.Drawing.Color]::White
    $appFileSelectButton.FlatStyle = "Flat"
    $appFileSelectButton.Add_Click({
        $fileDialog = New-Object System.Windows.Forms.OpenFileDialog
        $fileDialog.Filter = "Applications (*.exe)|*.exe|Installers (*.msi)|*.msi"
        
        if ($fileDialog.ShowDialog() -eq "OK") {
            $fileInfo = Get-Item $fileDialog.FileName
            $appNameTextBox.Text = [System.IO.Path]::GetFileNameWithoutExtension($fileDialog.FileName)
            $appDirTextBox.Text = $fileInfo.DirectoryName
            $appExtensionCombo.SelectedItem = $fileInfo.Extension
        }
    })
    $appTab.Controls.Add($appFileSelectButton)
    
    # Dialog Buttons
    $addButton = New-Object System.Windows.Forms.Button
    $addButton.Location = New-Object System.Drawing.Point(420, 480)
    $addButton.Size = New-Object System.Drawing.Size(75, 30)
    $addButton.Text = "Add"
    $addButton.BackColor = $global:Theme.Secondary
    $addButton.ForeColor = [System.Drawing.Color]::White
    $addButton.FlatStyle = "Flat"
    $addButton.DialogResult = "OK"
    $addForm.Controls.Add($addButton)
    
    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Location = New-Object System.Drawing.Point(505, 480)
    $cancelButton.Size = New-Object System.Drawing.Size(75, 30)
    $cancelButton.Text = "Cancel"
    $cancelButton.BackColor = $global:Theme.TextMuted
    $cancelButton.ForeColor = [System.Drawing.Color]::White
    $cancelButton.FlatStyle = "Flat"
    $cancelButton.DialogResult = "Cancel"
    $addForm.Controls.Add($cancelButton)
    
    $result = $addForm.ShowDialog()
    
    if ($result -eq "OK") {
        $isScript = ($tabControl.SelectedTab -eq $scriptTab)
        
        if ($isScript) {
            $fullPath = Join-Path $dirTextBox.Text "$($fileNameTextBox.Text)$($extensionCombo.SelectedItem)"
            $validation = Test-PowerShellScript $fullPath
            
            if (-not $validation.IsValid) {
                [System.Windows.Forms.MessageBox]::Show("Script validation failed:`n`n" + ($validation.Errors -join "`n"), "Validation Error", "OK", "Error")
                $addForm.Dispose()
                return $false
            }
            
            $newItem = @{
                name = "[$($typeCombo.SelectedItem.Substring(0,1).ToUpper())] $($fileNameTextBox.Text)"
                fileName = $fileNameTextBox.Text
                extension = $extensionCombo.SelectedItem
                type = $typeCombo.SelectedItem
                mode = "Script"
                category = $categoryCombo.SelectedItem
                color = if ($typeCombo.SelectedItem -eq "start") { "LightGreen" } else { "LightCoral" }
                directory = $dirTextBox.Text
                isBuiltIn = $false
                icon = "🔵"
                created = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
            }
        } else {
            $fullPath = Join-Path $appDirTextBox.Text "$($appNameTextBox.Text)$($appExtensionCombo.SelectedItem)"
            $validation = Test-ExecutableApp $fullPath
            
            if (-not $validation.IsValid) {
                [System.Windows.Forms.MessageBox]::Show("Application validation failed:`n`n" + ($validation.Errors -join "`n"), "Validation Error", "OK", "Error")
                $addForm.Dispose()
                return $false
            }
            
            $newItem = @{
                name = "[⚙️] $($appNameTextBox.Text)"
                fileName = $appNameTextBox.Text
                extension = $appExtensionCombo.SelectedItem
                type = "application"
                mode = "Application"
                category = "Applications"
                color = "LightBlue"
                directory = $appDirTextBox.Text
                isBuiltIn = $false
                icon = "⚙️"
                created = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
            }
        }
        
        $config.scripts = @($config.scripts) + $newItem
        
        if (Save-ScriptConfig $config) {
            Add-LogEntry "Successfully added: $($newItem.name)" "Success"
            $addForm.Dispose()
            
            # Refresh the UI immediately instead of requiring restart
            Refresh-ServiceInterface $servicesPanel $config
            Add-LogEntry "Interface updated with new service" "Success"
            
            # Show simple success message - no restart needed
            [System.Windows.Forms.MessageBox]::Show("✅ $($newItem.name) added successfully!", "Service Added", "OK", "Information")
            return $true
        }
    }
    
    $addForm.Dispose()
    return $false
}

# ═══════════════════════════════════════════════════════════════════════════════
# ⚙️ SETTINGS SYSTEM
# ═══════════════════════════════════════════════════════════════════════════════

function Show-SettingsDialog {
    param($settings)
    
    $settingsForm = New-Object System.Windows.Forms.Form
    $settingsForm.Text = "⚙️ ServiceManager Settings"
    $settingsForm.Size = New-Object System.Drawing.Size(500, 350)
    $settingsForm.StartPosition = "CenterParent"
    $settingsForm.FormBorderStyle = "FixedDialog"
    $settingsForm.MaximizeBox = $false
    $settingsForm.BackColor = $global:Theme.Light
    
    # ServiceManager Path
    $pathLabel = New-Object System.Windows.Forms.Label
    $pathLabel.Location = New-Object System.Drawing.Point(30, 30)
    $pathLabel.Size = New-Object System.Drawing.Size(150, 25)
    $pathLabel.Text = "🎯 ServiceManager Path:"
    $pathLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $settingsForm.Controls.Add($pathLabel)
    
    $pathTextBox = New-Object System.Windows.Forms.TextBox
    $pathTextBox.Location = New-Object System.Drawing.Point(30, 60)
    $pathTextBox.Size = New-Object System.Drawing.Size(350, 25)
    $pathTextBox.Text = $settings.serviceManagerPath
    $settingsForm.Controls.Add($pathTextBox)
    
    $pathBrowseButton = New-Object System.Windows.Forms.Button
    $pathBrowseButton.Location = New-Object System.Drawing.Point(390, 59)
    $pathBrowseButton.Size = New-Object System.Drawing.Size(50, 27)
    $pathBrowseButton.Text = "..."
    $pathBrowseButton.BackColor = $global:Theme.Primary
    $pathBrowseButton.ForeColor = [System.Drawing.Color]::White
    $pathBrowseButton.FlatStyle = "Flat"
    $pathBrowseButton.Add_Click({
        $fileDialog = New-Object System.Windows.Forms.OpenFileDialog
        $fileDialog.Filter = "PowerShell Scripts (*.ps1)|*.ps1"
        if ($fileDialog.ShowDialog() -eq "OK") {
            $pathTextBox.Text = $fileDialog.FileName
        }
    })
    $settingsForm.Controls.Add($pathBrowseButton)
    
    # Default Script Location
    $scriptLocationLabel = New-Object System.Windows.Forms.Label
    $scriptLocationLabel.Location = New-Object System.Drawing.Point(30, 100)
    $scriptLocationLabel.Size = New-Object System.Drawing.Size(200, 25)
    $scriptLocationLabel.Text = "📁 Default Script Location:"
    $scriptLocationLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $settingsForm.Controls.Add($scriptLocationLabel)
    
    $scriptLocationTextBox = New-Object System.Windows.Forms.TextBox
    $scriptLocationTextBox.Location = New-Object System.Drawing.Point(30, 130)
    $scriptLocationTextBox.Size = New-Object System.Drawing.Size(350, 25)
    $scriptLocationTextBox.Text = $settings.defaultScriptLocation
    $settingsForm.Controls.Add($scriptLocationTextBox)
    
    # Auto-organize checkbox
    $autoOrganizeCheckBox = New-Object System.Windows.Forms.CheckBox
    $autoOrganizeCheckBox.Location = New-Object System.Drawing.Point(30, 170)
    $autoOrganizeCheckBox.Size = New-Object System.Drawing.Size(350, 25)
    $autoOrganizeCheckBox.Text = "🗂️ Auto-organize scripts into start/stop folders"
    $autoOrganizeCheckBox.Checked = $settings.autoOrganizeScripts
    $settingsForm.Controls.Add($autoOrganizeCheckBox)
    
    # Reset Configuration Button
    $resetConfigButton = New-Object System.Windows.Forms.Button
    $resetConfigButton.Location = New-Object System.Drawing.Point(30, 210)
    $resetConfigButton.Size = New-Object System.Drawing.Size(150, 30)
    $resetConfigButton.Text = "🔄 Reset Configuration"
    $resetConfigButton.BackColor = $global:Theme.Danger
    $resetConfigButton.ForeColor = [System.Drawing.Color]::White
    $resetConfigButton.FlatStyle = "Flat"
    $resetConfigButton.Add_Click({
        $confirm = [System.Windows.Forms.MessageBox]::Show("This will delete all your configured services and reset to defaults.`n`nAre you sure?", "Reset Configuration", "YesNo", "Warning")
        if ($confirm -eq "Yes") {
            try {
                Remove-Item ".\user_config" -Recurse -Force
                [System.Windows.Forms.MessageBox]::Show("Configuration reset complete.`n`nServiceManager will restart with setup wizard.", "Reset Complete", "OK", "Information")
                $settingsForm.Close()
                $form.Close()
                Start-Process -FilePath "powershell" -ArgumentList "-ExecutionPolicy Bypass -File `".\ServiceManager.ps1`""
            } catch {
                [System.Windows.Forms.MessageBox]::Show("Failed to reset configuration: $($_.Exception.Message)", "Reset Failed", "OK", "Error")
            }
        }
    })
    $settingsForm.Controls.Add($resetConfigButton)
    
    # Buttons
    $saveButton = New-Object System.Windows.Forms.Button
    $saveButton.Location = New-Object System.Drawing.Point(280, 280)
    $saveButton.Size = New-Object System.Drawing.Size(75, 30)
    $saveButton.Text = "Save"
    $saveButton.BackColor = $global:Theme.Secondary
    $saveButton.ForeColor = [System.Drawing.Color]::White
    $saveButton.FlatStyle = "Flat"
    $saveButton.DialogResult = "OK"
    $settingsForm.Controls.Add($saveButton)
    
    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Location = New-Object System.Drawing.Point(365, 280)
    $cancelButton.Size = New-Object System.Drawing.Size(75, 30)
    $cancelButton.Text = "Cancel"
    $cancelButton.BackColor = $global:Theme.TextMuted
    $cancelButton.ForeColor = [System.Drawing.Color]::White
    $cancelButton.FlatStyle = "Flat"
    $cancelButton.DialogResult = "Cancel"
    $settingsForm.Controls.Add($cancelButton)
    
    $result = $settingsForm.ShowDialog()
    
    if ($result -eq "OK") {
        $settings.serviceManagerPath = $pathTextBox.Text
        $settings.defaultScriptLocation = $scriptLocationTextBox.Text
        $settings.autoOrganizeScripts = $autoOrganizeCheckBox.Checked
        
        if (Save-AppSettings $settings) {
            Add-LogEntry "Settings saved successfully" "Success"
            [System.Windows.Forms.MessageBox]::Show("✅ Settings saved successfully!", "Settings", "OK", "Information")
        }
    }
    
    $settingsForm.Dispose()
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🗑️ ENHANCED REMOVE DIALOG
# ═══════════════════════════════════════════════════════════════════════════════

function Show-RemoveDialog {
    param($config, $servicesPanel)
    
    $customServices = $config.scripts | Where-Object { -not $_.isBuiltIn }
    if ($customServices.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("No custom services to remove.`n(Built-in services cannot be removed)", "No Custom Services", "OK", "Information")
        return $false
    }
    
    $removeForm = New-Object System.Windows.Forms.Form
    $removeForm.Text = "🗑️ Remove Service"
    $removeForm.Size = New-Object System.Drawing.Size(500, 350)
    $removeForm.StartPosition = "CenterParent"
    $removeForm.FormBorderStyle = "FixedDialog"
    $removeForm.MaximizeBox = $false
    $removeForm.BackColor = $global:Theme.Light
    
    $headerLabel = New-Object System.Windows.Forms.Label
    $headerLabel.Location = New-Object System.Drawing.Point(20, 20)
    $headerLabel.Size = New-Object System.Drawing.Size(450, 30)
    $headerLabel.Text = "🗑️ Select service to remove:"
    $headerLabel.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $headerLabel.ForeColor = $global:Theme.Danger
    $removeForm.Controls.Add($headerLabel)
    
    $listBox = New-Object System.Windows.Forms.ListBox
    $listBox.Location = New-Object System.Drawing.Point(20, 60)
    $listBox.Size = New-Object System.Drawing.Size(450, 180)
    $listBox.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $listBox.BackColor = $global:Theme.Surface
    
    foreach ($service in $customServices) {
        $displayText = "$($service.icon) $($service.name) - $(Split-Path $service.directory -Leaf)"
        $listBox.Items.Add($displayText)
    }
    $removeForm.Controls.Add($listBox)
    
    $warningLabel = New-Object System.Windows.Forms.Label
    $warningLabel.Location = New-Object System.Drawing.Point(20, 250)
    $warningLabel.Size = New-Object System.Drawing.Size(450, 20)
    $warningLabel.Text = "⚠️ Warning: This action cannot be undone!"
    $warningLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $warningLabel.ForeColor = $global:Theme.Danger
    $removeForm.Controls.Add($warningLabel)
    
    $removeButton = New-Object System.Windows.Forms.Button
    $removeButton.Location = New-Object System.Drawing.Point(310, 280)
    $removeButton.Size = New-Object System.Drawing.Size(75, 30)
    $removeButton.Text = "Remove"
    $removeButton.BackColor = $global:Theme.Danger
    $removeButton.ForeColor = [System.Drawing.Color]::White
    $removeButton.FlatStyle = "Flat"
    $removeButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $removeButton.DialogResult = "OK"
    $removeForm.Controls.Add($removeButton)
    
    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Location = New-Object System.Drawing.Point(395, 280)
    $cancelButton.Size = New-Object System.Drawing.Size(75, 30)
    $cancelButton.Text = "Cancel"
    $cancelButton.BackColor = $global:Theme.TextMuted
    $cancelButton.ForeColor = [System.Drawing.Color]::White
    $cancelButton.FlatStyle = "Flat"
    $cancelButton.DialogResult = "Cancel"
    $removeForm.Controls.Add($cancelButton)
    
    $result = $removeForm.ShowDialog()
    
    if ($result -eq "OK" -and $listBox.SelectedIndex -ge 0) {
        $selectedService = $customServices[$listBox.SelectedIndex]
        $confirm = [System.Windows.Forms.MessageBox]::Show(
            "Remove '$($selectedService.name)'?`n`nThis action cannot be undone.", 
            "Confirm Removal", "YesNo", "Warning")
        
        if ($confirm -eq "Yes") {
            $config.scripts = $config.scripts | Where-Object { 
                -not (($_.name -eq $selectedService.name) -and ($_.directory -eq $selectedService.directory))
            }
            
            if (Save-ScriptConfig $config) {
                Add-LogEntry "Removed: $($selectedService.name)" "Success"
                $removeForm.Dispose()
                
                # Refresh the UI immediately instead of requiring restart
                Refresh-ServiceInterface $servicesPanel $config
                Add-LogEntry "Interface updated after service removal" "Success"
                
                Show-RestartDialog "Service Removed" "✅ $($selectedService.name) removed successfully!`n`nThe interface has been updated. You can optionally restart for a complete refresh."
                return $true
            }
        }
    }
    
    $removeForm.Dispose()
    return $false
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🚀 ENHANCED EXECUTION ENGINE
# ═══════════════════════════════════════════════════════════════════════════════

function Execute-EnhancedService {
    param($service, $showPopup = $true)
    
    if ($service.mode -eq "Application") {
        $fullPath = Join-Path $service.directory "$($service.fileName)$($service.extension)"
        
        Add-LogEntry "Launching application: $($service.name)" "Info"
        
        if (-not (Test-Path $fullPath)) {
            $errorMsg = "Application not found: $fullPath"
            Add-LogEntry $errorMsg "Error"
            if ($showPopup) {
                [System.Windows.Forms.MessageBox]::Show($errorMsg, "Application Missing", "OK", "Error")
            }
            return $false
        }
        
        try {
            $startInfo = New-Object System.Diagnostics.ProcessStartInfo
            $startInfo.FileName = "powershell.exe"
            $startInfo.Arguments = "-NoExit -Command `"cd '$($service.directory)'; Write-Host '[APP] $($service.name)' -ForegroundColor Cyan; & '.\$($service.fileName)$($service.extension)'`""
            $startInfo.WorkingDirectory = $service.directory
            
            $process = [System.Diagnostics.Process]::Start($startInfo)
            
            Add-LogEntry "Successfully launched: $($service.name)" "Success"
            if ($showPopup) {
                [System.Windows.Forms.MessageBox]::Show("✅ $($service.name) launched successfully", "Application Started", "OK", "Information")
            }
            return $true
        } catch {
            $errorMsg = "Failed to launch $($service.name): $($_.Exception.Message)"
            Add-LogEntry $errorMsg "Error"
            if ($showPopup) {
                [System.Windows.Forms.MessageBox]::Show($errorMsg, "Launch Error", "OK", "Error")
            }
            return $false
        }
    } else {
        $fullPath = Join-Path $service.directory "$($service.fileName)$($service.extension)"
        
        Add-LogEntry "Executing script: $($service.name)" "Info"
        
        if (-not (Test-Path $fullPath)) {
            $errorMsg = "Script not found: $fullPath"
            Add-LogEntry $errorMsg "Error"
            if ($showPopup) {
                [System.Windows.Forms.MessageBox]::Show($errorMsg, "Script Missing", "OK", "Error")
            }
            return $false
        }
        
        try {
            if ($global:HasWindowsTerminal -and -not $showPopup) {
                Start-Process -FilePath "wt" -ArgumentList @(
                    "new-tab",
                    "--title", "`"$($service.name)`"",
                    "PowerShell", "-NoExit", 
                    "-Command", "Set-Location '$($service.directory)'; Write-Host '[SCRIPT] $($service.name)' -ForegroundColor Green; & '.\$($service.fileName)$($service.extension)'"
                )
            } else {
                Start-Process -FilePath "powershell" -ArgumentList @(
                    "-NoExit",
                    "-Command",
                    "Set-Location '$($service.directory)'; Write-Host '[GUI] $($service.name)' -ForegroundColor Green; & '.\$($service.fileName)$($service.extension)'"
                ) -WorkingDirectory $service.directory
            }
            
            Add-LogEntry "Successfully started: $($service.name)" "Success"
            if ($showPopup) {
                [System.Windows.Forms.MessageBox]::Show("✅ $($service.name) initiated successfully", "Script Started", "OK", "Information")
            }
            return $true
        } catch {
            $errorMsg = "Failed to execute $($service.name): $($_.Exception.Message)"
            Add-LogEntry $errorMsg "Error"
            if ($showPopup) {
                [System.Windows.Forms.MessageBox]::Show($errorMsg, "Execution Error", "OK", "Error")
            }
            return $false
        }
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🛑 ENHANCED STOP ALL FUNCTION
# ═══════════════════════════════════════════════════════════════════════════════

function Stop-AllServices {
    param($config)
    
    Add-LogEntry "🛑 Stopping all services..." "Info"
    $results = @()
    
    # Stop custom stop services by executing their scripts
    $customStops = $config.scripts | Where-Object { -not $_.isBuiltIn -and $_.type -like "*stop*" }
    foreach ($service in $customStops) {
        $success = Execute-EnhancedService $service $false
        if ($success) {
            $results += "✅ $($service.name)"
        } else {
            $results += "❌ $($service.name)"
        }
        Start-Sleep 1
    }
    
    # Stop any applications that might be running
    $applications = $config.scripts | Where-Object { $_.mode -eq "Application" }
    foreach ($app in $applications) {
        $appName = [System.IO.Path]::GetFileNameWithoutExtension($app.fileName)
        $processes = Get-Process -Name $appName -ErrorAction SilentlyContinue
        $killedCount = 0
        
        foreach ($process in $processes) {
            try {
                Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
                Add-LogEntry "Stopped application: $($process.ProcessName)" "Success"
                $killedCount++
            } catch { }
        }
        
        if ($killedCount -gt 0) {
            $results += "✅ $($app.name) ($killedCount processes stopped)"
        } else {
            $results += "ℹ️ $($app.name) (not running)"
        }
    }
    
    $message = "🛑 Stop All Results:`n`n" + ($results -join "`n")
    [System.Windows.Forms.MessageBox]::Show($message, "Stop All Complete", "OK", "Information")
    Add-LogEntry "🛑 Stop All completed" "Success"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎮 MAIN APPLICATION INTERFACE
# ═══════════════════════════════════════════════════════════════════════════════

Write-Host "🚀 ServiceManager Loading..." -ForegroundColor Cyan

# Check Windows Terminal
$global:HasWindowsTerminal = $false
try {
    $null = Get-Command wt -ErrorAction Stop
    $global:HasWindowsTerminal = $true
    Write-Host "✅ Windows Terminal detected" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Windows Terminal not found" -ForegroundColor Yellow
}

# Load configurations
$script:config = Load-ScriptConfig
$script:settings = Load-AppSettings

Write-Host "✅ Loaded $($script:config.scripts.Count) configured services" -ForegroundColor Green

# Create Optimized Main Form
$form = New-Object System.Windows.Forms.Form
$form.Text = "🚀 ServiceManager"
$form.Size = New-Object System.Drawing.Size(1000, 650)
$form.MinimumSize = New-Object System.Drawing.Size(900, 600)
$form.StartPosition = "CenterScreen"
$form.BackColor = $global:Theme.Light

# Header Panel
$headerPanel = New-Object System.Windows.Forms.Panel
$headerPanel.Location = New-Object System.Drawing.Point(0, 0)
$headerPanel.Size = New-Object System.Drawing.Size(1000, 70)
$headerPanel.BackColor = $global:Theme.Primary
$headerPanel.Anchor = "Top,Left,Right"
$form.Controls.Add($headerPanel)

$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Location = New-Object System.Drawing.Point(30, 15)
$titleLabel.Size = New-Object System.Drawing.Size(600, 30)
$titleLabel.Text = "🚀 ServiceManager"
$titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$titleLabel.ForeColor = [System.Drawing.Color]::White
$headerPanel.Controls.Add($titleLabel)

$subtitleLabel = New-Object System.Windows.Forms.Label
$subtitleLabel.Location = New-Object System.Drawing.Point(30, 45)
$subtitleLabel.Size = New-Object System.Drawing.Size(600, 20)
$subtitleLabel.Text = "⚡ Professional Application & Service Launcher ⚡"
$subtitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$subtitleLabel.ForeColor = [System.Drawing.Color]::LightGray
$headerPanel.Controls.Add($subtitleLabel)

# Settings Menu (3-line dropdown) 
$settingsMenuButton = New-Object System.Windows.Forms.Button
$settingsMenuButton.Location = New-Object System.Drawing.Point(920, 15)
$settingsMenuButton.Size = New-Object System.Drawing.Size(50, 40)
$settingsMenuButton.Text = "☰"
$settingsMenuButton.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$settingsMenuButton.BackColor = [System.Drawing.Color]::FromArgb(255, 255, 255, 30)
$settingsMenuButton.ForeColor = [System.Drawing.Color]::White
$settingsMenuButton.FlatStyle = "Flat"
$settingsMenuButton.Anchor = "Top,Right"
$settingsMenuButton.Add_Click({
    $menu = New-Object System.Windows.Forms.ContextMenuStrip
    
    $settingsItem = New-Object System.Windows.Forms.ToolStripMenuItem
    $settingsItem.Text = "⚙️  Settings"
    $settingsItem.Add_Click({ Show-SettingsDialog $script:settings })
    $menu.Items.Add($settingsItem)
    
    $restartItem = New-Object System.Windows.Forms.ToolStripMenuItem
    $restartItem.Text = "🔄 Restart Application"
    $restartItem.Add_Click({
        $form.Close()
        Start-Process -FilePath "powershell" -ArgumentList "-ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`""
    })
    $menu.Items.Add($restartItem)
    
    $menu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))
    
    $scriptsItem = New-Object System.Windows.Forms.ToolStripMenuItem
    $scriptsItem.Text = "📁 Open Script Folders"
    $scriptsItem.Add_Click({
        if (Test-Path ".\start") {
            Start-Process "explorer.exe" -ArgumentList ".\start"
        }
    })
    $menu.Items.Add($scriptsItem)
    
    $exportItem = New-Object System.Windows.Forms.ToolStripMenuItem
    $exportItem.Text = "📋 Export Configuration"
    $exportItem.Add_Click({
        $saveDialog = New-Object System.Windows.Forms.SaveFileDialog
        $saveDialog.Filter = "JSON files (*.json)|*.json"
        $saveDialog.FileName = "servicemanager-config-$(Get-Date -Format 'yyyyMMdd').json"
        if ($saveDialog.ShowDialog() -eq "OK") {
            Copy-Item $global:ConfigFile $saveDialog.FileName
            [System.Windows.Forms.MessageBox]::Show("Configuration exported!", "Export", "OK", "Information")
        }
    })
    $menu.Items.Add($exportItem)
    
    $menu.Show($settingsMenuButton, 0, $settingsMenuButton.Height)
})
$headerPanel.Controls.Add($settingsMenuButton)

# Management Panel
$managementPanel = New-Object System.Windows.Forms.Panel
$managementPanel.Location = New-Object System.Drawing.Point(20, 80)
$managementPanel.Size = New-Object System.Drawing.Size(960, 50)
$managementPanel.BackColor = $global:Theme.Surface
$managementPanel.BorderStyle = "FixedSingle"
$managementPanel.Anchor = "Top,Left,Right"
$form.Controls.Add($managementPanel)

$addButton = New-Object System.Windows.Forms.Button
$addButton.Location = New-Object System.Drawing.Point(15, 12)
$addButton.Size = New-Object System.Drawing.Size(120, 28)
$addButton.Text = "➕ Add Script/App"
$addButton.BackColor = $global:Theme.Secondary
$addButton.ForeColor = [System.Drawing.Color]::White
$addButton.FlatStyle = "Flat"
$addButton.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$addButton.Add_Click({
    Show-EnhancedAddDialog $script:config $servicesPanel
})
$managementPanel.Controls.Add($addButton)

# Remove button removed - now using individual trash icons per service

$refreshButton = New-Object System.Windows.Forms.Button
$refreshButton.Location = New-Object System.Drawing.Point(145, 12)
$refreshButton.Size = New-Object System.Drawing.Size(100, 28)
$refreshButton.Text = "🔄 Refresh"
$refreshButton.BackColor = $global:Theme.Accent
$refreshButton.ForeColor = [System.Drawing.Color]::White
$refreshButton.FlatStyle = "Flat"
$refreshButton.Add_Click({
    try {
        # Reload config from file
        $script:config = Load-ScriptConfig
        
        # Refresh the services interface
        Refresh-ServiceInterface $servicesPanel $script:config
        
        # Clear and refresh logs
        $global:LogTextBox.Clear()
        $global:LogEntries.Clear()
        Add-LogEntry "Interface refreshed from config file" "Success"
        Add-LogEntry "Loaded $($script:config.scripts.Count) services" "Info"
    } catch {
        Add-LogEntry "Error refreshing interface: $($_.Exception.Message)" "Error"
    }
})
$managementPanel.Controls.Add($refreshButton)

# OPTIMIZED HORIZONTAL LAYOUT - Services on Left, Logs on Right
$servicesPanel = New-Object System.Windows.Forms.Panel
$servicesPanel.Location = New-Object System.Drawing.Point(20, 140)
$servicesPanel.Size = New-Object System.Drawing.Size(480, 350)
$servicesPanel.BorderStyle = "FixedSingle"
$servicesPanel.BackColor = $global:Theme.Surface
$servicesPanel.AutoScroll = $true
$servicesPanel.Anchor = "Top,Left,Bottom"
$form.Controls.Add($servicesPanel)

# Initialize the services interface using the refresh function
Refresh-ServiceInterface $servicesPanel $script:config

# Control Panel (Below Services)
$controlPanel = New-Object System.Windows.Forms.Panel
$controlPanel.Location = New-Object System.Drawing.Point(20, 500)
$controlPanel.Size = New-Object System.Drawing.Size(480, 50)
$controlPanel.BackColor = $global:Theme.Dark
$controlPanel.BorderStyle = "FixedSingle"
$controlPanel.Anchor = "Bottom,Left"
$form.Controls.Add($controlPanel)

$startAllButton = New-Object System.Windows.Forms.Button
$startAllButton.Location = New-Object System.Drawing.Point(15, 10)
$startAllButton.Size = New-Object System.Drawing.Size(90, 30)
$startAllButton.Text = "🚀 Start All"
$startAllButton.BackColor = $global:Theme.Secondary
$startAllButton.ForeColor = [System.Drawing.Color]::White
$startAllButton.FlatStyle = "Flat"
$startAllButton.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$startAllButton.Add_Click({
    Add-LogEntry "🚀 Starting all services..." "Info"
    $startServices = $script:config.scripts | Where-Object { $_.type -like "*start*" -or $_.mode -eq "Application" }
    $results = @()
    
    foreach ($service in $startServices) {
        $success = Execute-EnhancedService $service $false
        if ($success) {
            $results += "✅ $($service.name)"
        } else {
            $results += "❌ $($service.name)"
        }
        Start-Sleep 1
    }
    
    $message = "🚀 Start All Results:`n`n" + ($results -join "`n")
    [System.Windows.Forms.MessageBox]::Show($message, "Start All Complete", "OK", "Information")
    Add-LogEntry "🚀 Start All completed" "Success"
})
$controlPanel.Controls.Add($startAllButton)

$stopAllButton = New-Object System.Windows.Forms.Button
$stopAllButton.Location = New-Object System.Drawing.Point(115, 10)
$stopAllButton.Size = New-Object System.Drawing.Size(90, 30)
$stopAllButton.Text = "🛑 Stop All"
$stopAllButton.BackColor = $global:Theme.Danger
$stopAllButton.ForeColor = [System.Drawing.Color]::White
$stopAllButton.FlatStyle = "Flat"
$stopAllButton.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$stopAllButton.Add_Click({
    Stop-AllServices $script:config
})
$controlPanel.Controls.Add($stopAllButton)

$testButton = New-Object System.Windows.Forms.Button
$testButton.Location = New-Object System.Drawing.Point(215, 10)
$testButton.Size = New-Object System.Drawing.Size(100, 30)
$testButton.Text = "🔍 Validate All"
$testButton.BackColor = $global:Theme.Accent
$testButton.ForeColor = [System.Drawing.Color]::White
$testButton.FlatStyle = "Flat"
$testButton.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$testButton.Add_Click({
    Add-LogEntry "🔍 Validating all items..." "Info"
    $results = @()
    
    foreach ($service in $script:config.scripts) {
        $fullPath = Join-Path $service.directory "$($service.fileName)$($service.extension)"
        
        if ($service.mode -eq "Application") {
            $validation = Test-ExecutableApp $fullPath
        } else {
            $validation = Test-PowerShellScript $fullPath
        }
        
        if ($validation.IsValid) {
            $results += "✅ $($service.name) (Score: $($validation.Score)/100)"
        } else {
            $results += "❌ $($service.name) - Issues Found"
        }
    }
    
    $message = "🔍 Validation Results:`n`n" + ($results -join "`n")
    [System.Windows.Forms.MessageBox]::Show($message, "Validation Complete", "OK", "Information")
})
$controlPanel.Controls.Add($testButton)

$clearLogsButton = New-Object System.Windows.Forms.Button
$clearLogsButton.Location = New-Object System.Drawing.Point(325, 10)
$clearLogsButton.Size = New-Object System.Drawing.Size(90, 30)
$clearLogsButton.Text = "🧹 Clear Logs"
$clearLogsButton.BackColor = $global:Theme.TextMuted
$clearLogsButton.ForeColor = [System.Drawing.Color]::White
$clearLogsButton.FlatStyle = "Flat"
$clearLogsButton.Add_Click({
    $global:LogEntries.Clear()
    $global:LogTextBox.Clear()
    Add-LogEntry "Logs cleared" "Info"
})
$controlPanel.Controls.Add($clearLogsButton)

# OPTIMIZED LOGS PANEL (Right Side)
$logsLabel = New-Object System.Windows.Forms.Label
$logsLabel.Location = New-Object System.Drawing.Point(520, 140)
$logsLabel.Size = New-Object System.Drawing.Size(200, 25)
$logsLabel.Text = "📋 Service Logs"
$logsLabel.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$logsLabel.ForeColor = $global:Theme.Text
$logsLabel.Anchor = "Top,Right"
$form.Controls.Add($logsLabel)

$global:LogTextBox = New-Object System.Windows.Forms.RichTextBox
$global:LogTextBox.Location = New-Object System.Drawing.Point(520, 165)
$global:LogTextBox.Size = New-Object System.Drawing.Size(460, 385)
$global:LogTextBox.Multiline = $true
$global:LogTextBox.ScrollBars = "Vertical"
$global:LogTextBox.ReadOnly = $true
$global:LogTextBox.BackColor = [System.Drawing.Color]::Black
$global:LogTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
$global:LogTextBox.BorderStyle = "FixedSingle"
$global:LogTextBox.Anchor = "Top,Bottom,Right"
$form.Controls.Add($global:LogTextBox)

# Initialize logs
Add-LogEntry "🚀 ServiceManager started successfully" "Success"
Add-LogEntry "Loaded $($config.scripts.Count) configured services" "Info"
Add-LogEntry "Windows Terminal: $(if ($global:HasWindowsTerminal) { 'Available ✅' } else { 'Not found ⚠️' })" "Info"
Add-LogEntry "Ready for action! 🎯" "Success"

Write-Host "✅ ServiceManager interface loaded successfully" -ForegroundColor Green

# Show the form
[System.Windows.Forms.Application]::Run($form)

Write-Host "🎯 ServiceManager closed gracefully" -ForegroundColor Cyan