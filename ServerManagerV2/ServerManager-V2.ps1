# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║              🚀 SERVER MANAGER V2 - REVOLUTIONARY EDITION 🚀                ║
# ║                    Professional Application & Service Launcher               ║
# ║                          ⚡ Built for Power Users ⚡                         ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Drawing.Design

# ═══════════════════════════════════════════════════════════════════════════════
# 🎨 VISUAL THEMES & ENHANCED STYLING
# ═══════════════════════════════════════════════════════════════════════════════

[System.Windows.Forms.Application]::EnableVisualStyles()
[System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)

# Modern Color Palette
$global:Theme = @{
    Primary = [System.Drawing.Color]::FromArgb(64, 128, 255)      # Modern Blue
    Secondary = [System.Drawing.Color]::FromArgb(100, 200, 100)   # Success Green  
    Accent = [System.Drawing.Color]::FromArgb(255, 165, 0)        # Warning Orange
    Danger = [System.Drawing.Color]::FromArgb(255, 85, 85)        # Error Red
    Dark = [System.Drawing.Color]::FromArgb(45, 45, 48)           # Dark Gray
    Light = [System.Drawing.Color]::FromArgb(248, 249, 250)       # Light Gray
    Surface = [System.Drawing.Color]::FromArgb(255, 255, 255)     # White
    Text = [System.Drawing.Color]::FromArgb(33, 37, 41)           # Dark Text
    TextMuted = [System.Drawing.Color]::FromArgb(108, 117, 125)   # Muted Text
}

# ═══════════════════════════════════════════════════════════════════════════════
# ⚙️ GLOBAL CONFIGURATION & STATE MANAGEMENT
# ═══════════════════════════════════════════════════════════════════════════════

$global:ConfigFile = ".\scripts_storage.json"
$global:SettingsFile = ".\app_settings.json"
$global:LogEntries = [System.Collections.ArrayList]::new()
$global:ActiveTabs = @{}
$global:CurrentMode = "Script"  # Script or Application mode

# Enhanced Extension Support System
$global:SupportedTypes = @{
    "Script" = @{
        ".ps1" = @{
            name = "PowerShell Script"
            icon = "🔵"
            description = "Windows PowerShell automation script"
            executeMethod = "PowerShell"
            validator = "Test-PowerShellScript"
        }
        # Future: ".py", ".js", ".bat", etc.
    }
    "Application" = @{
        ".exe" = @{
            name = "Windows Application"
            icon = "⚙️"
            description = "Windows executable application"
            executeMethod = "Direct"
            validator = "Test-ExecutableApp"
        }
        ".msi" = @{
            name = "Installer Package"
            icon = "📦"
            description = "Windows installer package"
            executeMethod = "Direct"
            validator = "Test-ExecutableApp"
        }
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🔧 ENHANCED CONFIGURATION MANAGEMENT
# ═══════════════════════════════════════════════════════════════════════════════

function Load-AppSettings {
    if (Test-Path $global:SettingsFile) {
        try {
            $settings = Get-Content $global:SettingsFile -Raw | ConvertFrom-Json
            return $settings
        } catch {
            Add-LogEntry "[WARN] Settings corrupted, creating defaults" "Warning"
            return Create-DefaultSettings
        }
    } else {
        return Create-DefaultSettings
    }
}

function Create-DefaultSettings {
    $defaultSettings = @{
        version = "2.0"
        serviceManagerPath = ".\ServerManager-V2.ps1"
        defaultScriptLocation = ".\scripts\"
        autoOrganizeScripts = $true
        showAdvancedOptions = $false
        theme = "Modern"
        startInFullscreen = $false
        enableNotifications = $true
        logLevel = "Info"
        autoCheckUpdates = $true
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
        Add-LogEntry "[ERROR] Failed to save settings: $($_.Exception.Message)" "Error"
        return $false
    }
}

function Load-ScriptConfig {
    if (Test-Path $global:ConfigFile) {
        try {
            $configData = Get-Content $global:ConfigFile -Raw | ConvertFrom-Json
            # Handle both V1 and V2 formats
            if ($configData -is [array]) {
                # V1 format conversion
                $config = $configData[1]
                if (-not $config.version) { $config.version = "1.0" }
            } else {
                $config = $configData
            }
            return $config
        } catch {
            Add-LogEntry "[WARN] Config corrupted, creating new one" "Warning"
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
        scripts = @(
            @{
                name = "[*] Start MCP Server"
                fileName = "MCP-Startup"
                extension = ".ps1"
                type = "start"
                mode = "Script"
                color = "LightGreen"
                directory = "C:\aiMain\Zoe\DockerMCP"
                isBuiltIn = $true
                icon = "🔵"
                category = "AI Services"
            },
            @{
                name = "[X] Stop MCP Server"
                fileName = "MCP-Kill"
                extension = ".ps1"
                type = "stop"
                mode = "Script"
                color = "LightCoral"
                directory = "C:\aiMain\Zoe\DockerMCP"
                isBuiltIn = $true
                icon = "🔴"
                category = "AI Services"
            },
            @{
                name = "[*] Start n8n"
                fileName = "n8nStartup"
                extension = ".ps1"
                type = "start"
                mode = "Script"
                color = "LightBlue"
                directory = "C:\aiMain\Zoe\Dockern8n"
                isBuiltIn = $true
                icon = "🌐"
                category = "Automation"
            },
            @{
                name = "[X] Stop n8n"
                fileName = "n8nKill"
                extension = ".ps1"
                type = "stop"
                mode = "Script"
                color = "LightCoral"
                directory = "C:\aiMain\Zoe\Dockern8n"
                isBuiltIn = $true
                icon = "🔴"
                category = "Automation"
            }
        )
        categories = @("AI Services", "Automation", "Development", "System", "Custom")
        statistics = @{
            totalExecutions = 0
            lastUsed = $null
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
        Add-LogEntry "[ERROR] Failed to save configuration: $($_.Exception.Message)" "Error"
        return $false
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# 📝 ENHANCED LOGGING SYSTEM
# ═══════════════════════════════════════════════════════════════════════════════

function Add-LogEntry {
    param(
        [string]$message,
        [string]$level = "Info"
    )
    
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
    
    # Update log display with color coding
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
    
    # Console output with color
    $consoleColor = switch ($level) {
        "Success" { "Green" }
        "Warning" { "Yellow" }
        "Error" { "Red" }
        default { "Gray" }
    }
    Write-Host $logMessage -ForegroundColor $consoleColor
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🔍 ADVANCED VALIDATION SYSTEM
# ═══════════════════════════════════════════════════════════════════════════════

function Test-PowerShellScript {
    param($FilePath)
    
    $result = @{
        IsValid = $false
        Errors = @()
        Warnings = @()
        Suggestions = @()
        Score = 0
    }
    
    try {
        # File existence
        if (-not (Test-Path $FilePath)) {
            $result.Errors += "File not found: $FilePath"
            return $result
        }
        
        # File size check
        $fileInfo = Get-Item $FilePath
        if ($fileInfo.Length -eq 0) {
            $result.Errors += "File is empty"
            return $result
        }
        
        # Read content for analysis
        $content = Get-Content $FilePath -Raw
        
        # Basic PowerShell syntax check
        try {
            $null = [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$null, [ref]$null)
            $result.Score += 30
        } catch {
            $result.Errors += "PowerShell syntax error: $($_.Exception.Message)"
        }
        
        # Check for required path setup
        if ($content -match '\$scriptPath.*Split-Path.*MyInvocation\.MyCommand\.Path') {
            $result.Score += 20
            $result.Suggestions += "✅ Proper path setup detected"
        } else {
            $result.Warnings += "Missing recommended path setup: `$scriptPath = Split-Path -Parent `$MyInvocation.MyCommand.Path"
        }
        
        # Check for Set-Location
        if ($content -match 'Set-Location.*\$scriptPath') {
            $result.Score += 15
        } else {
            $result.Warnings += "Consider adding: Set-Location `$scriptPath"
        }
        
        # Check for logging/output
        if ($content -match 'Write-Host|Write-Output|Write-Information') {
            $result.Score += 10
            $result.Suggestions += "✅ Output/logging detected"
        }
        
        # Check for error handling
        if ($content -match 'try\s*{.*}.*catch|trap') {
            $result.Score += 15
            $result.Suggestions += "✅ Error handling detected"
        } else {
            $result.Suggestions += "Consider adding try/catch blocks for better error handling"
        }
        
        # Final validation
        $result.IsValid = ($result.Errors.Count -eq 0) -and ($result.Score -ge 30)
        
    } catch {
        $result.Errors += "Validation error: $($_.Exception.Message)"
    }
    
    return $result
}

function Test-ExecutableApp {
    param($FilePath)
    
    $result = @{
        IsValid = $false
        Errors = @()
        Warnings = @()
        Suggestions = @()
        Score = 0
    }
    
    try {
        # File existence
        if (-not (Test-Path $FilePath)) {
            $result.Errors += "Application not found: $FilePath"
            return $result
        }
        
        $fileInfo = Get-Item $FilePath
        
        # Check if it's actually an executable
        if ($fileInfo.Extension -notin @('.exe', '.msi', '.bat', '.cmd')) {
            $result.Errors += "Not a valid executable file"
            return $result
        }
        
        # Check file size (shouldn't be 0)
        if ($fileInfo.Length -eq 0) {
            $result.Errors += "Executable file is empty or corrupted"
            return $result
        }
        
        # Try to get file version info
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
        
        # Check if file is digitally signed
        try {
            $signature = Get-AuthenticodeSignature $FilePath -ErrorAction SilentlyContinue
            if ($signature.Status -eq 'Valid') {
                $result.Suggestions += "✅ Digitally signed and trusted"
                $result.Score += 25
            } elseif ($signature.Status -eq 'NotSigned') {
                $result.Warnings += "Application is not digitally signed"
            }
        } catch {
            # Ignore signature check errors
        }
        
        # Check file attributes
        if ($fileInfo.Attributes -band [System.IO.FileAttributes]::ReadOnly) {
            $result.Warnings += "File is read-only"
        }
        
        $result.Score += 45  # Base score for valid executable
        $result.IsValid = ($result.Errors.Count -eq 0)
        
    } catch {
        $result.Errors += "Validation error: $($_.Exception.Message)"
    }
    
    return $result
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🚀 REVOLUTIONARY ADD SCRIPT DIALOG WITH TABS
# ═══════════════════════════════════════════════════════════════════════════════

function Show-EnhancedAddDialog {
    param($config)
    
    # Create modern dialog with tabs
    $addForm = New-Object System.Windows.Forms.Form
    $addForm.Text = "Add New Item - ServerManager V2"
    $addForm.Size = New-Object System.Drawing.Size(600, 550)
    $addForm.StartPosition = "CenterParent"
    $addForm.FormBorderStyle = "FixedDialog"
    $addForm.MaximizeBox = $false
    $addForm.MinimizeBox = $false
    $addForm.BackColor = $global:Theme.Light
    $addForm.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    
    # Modern header
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
    
    # Tab Control for Script vs Application
    $tabControl = New-Object System.Windows.Forms.TabControl
    $tabControl.Location = New-Object System.Drawing.Point(20, 80)
    $tabControl.Size = New-Object System.Drawing.Size(560, 380)
    $tabControl.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $addForm.Controls.Add($tabControl)
    
    # ═══════════════════════════════════════════════════════════════════════════
    # 📜 SCRIPT TAB
    # ═══════════════════════════════════════════════════════════════════════════
    
    $scriptTab = New-Object System.Windows.Forms.TabPage
    $scriptTab.Text = "📜 PowerShell Script"
    $scriptTab.BackColor = $global:Theme.Surface
    $scriptTab.Padding = New-Object System.Windows.Forms.Padding(15)
    $tabControl.TabPages.Add($scriptTab)
    
    # Filename and Extension (Revolutionary Layout!)
    $fileLabel = New-Object System.Windows.Forms.Label
    $fileLabel.Location = New-Object System.Drawing.Point(20, 30)
    $fileLabel.Size = New-Object System.Drawing.Size(120, 25)
    $fileLabel.Text = "📝 Script Name:"
    $fileLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $scriptTab.Controls.Add($fileLabel)
    
    $fileNameTextBox = New-Object System.Windows.Forms.TextBox
    $fileNameTextBox.Location = New-Object System.Drawing.Point(140, 28)
    $fileNameTextBox.Size = New-Object System.Drawing.Size(280, 25)
    $fileNameTextBox.Text = "MyScript"
    $fileNameTextBox.Font = New-Object System.Drawing.Font("Consolas", 10)
    $scriptTab.Controls.Add($fileNameTextBox)
    
    $extensionCombo = New-Object System.Windows.Forms.ComboBox
    $extensionCombo.Location = New-Object System.Drawing.Point(430, 28)
    $extensionCombo.Size = New-Object System.Drawing.Size(80, 25)
    $extensionCombo.DropDownStyle = "DropDownList"
    $extensionCombo.Items.AddRange(@(".ps1"))  # Expandable for future
    $extensionCombo.SelectedIndex = 0
    $scriptTab.Controls.Add($extensionCombo)
    
    # Type Selection (Start/Stop)
    $typeLabel = New-Object System.Windows.Forms.Label
    $typeLabel.Location = New-Object System.Drawing.Point(20, 70)
    $typeLabel.Size = New-Object System.Drawing.Size(120, 25)
    $typeLabel.Text = "⚙️ Script Type:"
    $typeLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $scriptTab.Controls.Add($typeLabel)
    
    $typeCombo = New-Object System.Windows.Forms.ComboBox
    $typeCombo.Location = New-Object System.Drawing.Point(140, 68)
    $typeCombo.Size = New-Object System.Drawing.Size(150, 25)
    $typeCombo.DropDownStyle = "DropDownList"
    $typeCombo.Items.AddRange(@("start", "stop", "utility", "maintenance"))
    $typeCombo.SelectedIndex = 0
    $scriptTab.Controls.Add($typeCombo)
    
    # Category Selection
    $categoryLabel = New-Object System.Windows.Forms.Label
    $categoryLabel.Location = New-Object System.Drawing.Point(310, 70)
    $categoryLabel.Size = New-Object System.Drawing.Size(80, 25)
    $categoryLabel.Text = "🏷️ Category:"
    $categoryLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $scriptTab.Controls.Add($categoryLabel)
    
    $categoryCombo = New-Object System.Windows.Forms.ComboBox
    $categoryCombo.Location = New-Object System.Drawing.Point(390, 68)
    $categoryCombo.Size = New-Object System.Drawing.Size(120, 25)
    $categoryCombo.DropDownStyle = "DropDownList"
    $categoryCombo.Items.AddRange($config.categories)
    $categoryCombo.SelectedIndex = 0
    $scriptTab.Controls.Add($categoryCombo)
    
    # Directory Selection with Browse
    $dirLabel = New-Object System.Windows.Forms.Label
    $dirLabel.Location = New-Object System.Drawing.Point(20, 110)
    $dirLabel.Size = New-Object System.Drawing.Size(120, 25)
    $dirLabel.Text = "📁 Directory:"
    $dirLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $scriptTab.Controls.Add($dirLabel)
    
    $dirTextBox = New-Object System.Windows.Forms.TextBox
    $dirTextBox.Location = New-Object System.Drawing.Point(140, 108)
    $dirTextBox.Size = New-Object System.Drawing.Size(300, 25)
    $dirTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
    $scriptTab.Controls.Add($dirTextBox)
    
    $browseButton = New-Object System.Windows.Forms.Button
    $browseButton.Location = New-Object System.Drawing.Point(450, 107)
    $browseButton.Size = New-Object System.Drawing.Size(60, 27)
    $browseButton.Text = "Browse"
    $browseButton.BackColor = $global:Theme.Secondary
    $browseButton.ForeColor = [System.Drawing.Color]::White
    $browseButton.FlatStyle = "Flat"
    $browseButton.Add_Click({
        $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $folderDialog.SelectedPath = if ($dirTextBox.Text) { $dirTextBox.Text } else { (Get-Location).Path }
        if ($folderDialog.ShowDialog() -eq "OK") {
            $dirTextBox.Text = $folderDialog.SelectedPath
        }
    })
    $scriptTab.Controls.Add($browseButton)
    
    # File Browser Integration
    $fileSelectLabel = New-Object System.Windows.Forms.Label
    $fileSelectLabel.Location = New-Object System.Drawing.Point(20, 150)
    $fileSelectLabel.Size = New-Object System.Drawing.Size(150, 25)
    $fileSelectLabel.Text = "🎯 Or Select Existing File:"
    $fileSelectLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $scriptTab.Controls.Add($fileSelectLabel)
    
    $fileSelectButton = New-Object System.Windows.Forms.Button
    $fileSelectButton.Location = New-Object System.Drawing.Point(180, 148)
    $fileSelectButton.Size = New-Object System.Drawing.Size(120, 27)
    $fileSelectButton.Text = "Select File..."
    $fileSelectButton.BackColor = $global:Theme.Accent
    $fileSelectButton.ForeColor = [System.Drawing.Color]::White
    $fileSelectButton.FlatStyle = "Flat"
    $fileSelectButton.Add_Click({
        $fileDialog = New-Object System.Windows.Forms.OpenFileDialog
        $fileDialog.Filter = "PowerShell Scripts (*.ps1)|*.ps1|All files (*.*)|*.*"
        $fileDialog.InitialDirectory = if ($dirTextBox.Text) { $dirTextBox.Text } else { (Get-Location).Path }
        
        if ($fileDialog.ShowDialog() -eq "OK") {
            $selectedFile = $fileDialog.FileName
            $fileInfo = Get-Item $selectedFile
            
            # Auto-populate fields
            $fileNameTextBox.Text = [System.IO.Path]::GetFileNameWithoutExtension($selectedFile)
            $dirTextBox.Text = $fileInfo.DirectoryName
            
            # Auto-detect type from filename
            $fileName = $fileInfo.Name.ToLower()
            if ($fileName -like "*start*" -or $fileName -like "*startup*") {
                $typeCombo.SelectedItem = "start"
            } elseif ($fileName -like "*stop*" -or $fileName -like "*kill*" -or $fileName -like "*shutdown*") {
                $typeCombo.SelectedItem = "stop"
            }
        }
    })
    $scriptTab.Controls.Add($fileSelectButton)
    
    # Smart Validation Panel
    $validationPanel = New-Object System.Windows.Forms.Panel
    $validationPanel.Location = New-Object System.Drawing.Point(20, 190)
    $validationPanel.Size = New-Object System.Drawing.Size(490, 120)
    $validationPanel.BorderStyle = "FixedSingle"
    $validationPanel.BackColor = [System.Drawing.Color]::FromArgb(248, 249, 250)
    $scriptTab.Controls.Add($validationPanel)
    
    $validationLabel = New-Object System.Windows.Forms.Label
    $validationLabel.Location = New-Object System.Drawing.Point(10, 10)
    $validationLabel.Size = New-Object System.Drawing.Size(470, 20)
    $validationLabel.Text = "🔍 File Validation Results"
    $validationLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $validationPanel.Controls.Add($validationLabel)
    
    $validationTextBox = New-Object System.Windows.Forms.TextBox
    $validationTextBox.Location = New-Object System.Drawing.Point(10, 35)
    $validationTextBox.Size = New-Object System.Drawing.Size(470, 75)
    $validationTextBox.Multiline = $true
    $validationTextBox.ScrollBars = "Vertical"
    $validationTextBox.ReadOnly = $true
    $validationTextBox.BackColor = [System.Drawing.Color]::White
    $validationTextBox.Font = New-Object System.Drawing.Font("Consolas", 8)
    $validationTextBox.Text = "💡 Select or enter a file path to see validation results..."
    $validationPanel.Controls.Add($validationTextBox)
    
    # Real-time validation
    $validateScript = {
        if ($fileNameTextBox.Text -and $dirTextBox.Text) {
            $fullPath = Join-Path $dirTextBox.Text "$($fileNameTextBox.Text)$($extensionCombo.SelectedItem)"
            $validation = Test-PowerShellScript $fullPath
            
            $validationText = "📊 Validation Score: $($validation.Score)/100`r`n"
            $validationText += "Status: $(if ($validation.IsValid) { '✅ Valid' } else { '❌ Issues Found' })`r`n`r`n"
            
            if ($validation.Errors) {
                $validationText += "❌ Errors:`r`n" + ($validation.Errors -join "`r`n") + "`r`n`r`n"
            }
            if ($validation.Warnings) {
                $validationText += "⚠️ Warnings:`r`n" + ($validation.Warnings -join "`r`n") + "`r`n`r`n"
            }
            if ($validation.Suggestions) {
                $validationText += "💡 Suggestions:`r`n" + ($validation.Suggestions -join "`r`n")
            }
            
            $validationTextBox.Text = $validationText
        }
    }
    
    $fileNameTextBox.Add_TextChanged($validateScript)
    $dirTextBox.Add_TextChanged($validateScript)
    
    # ═══════════════════════════════════════════════════════════════════════════
    # ⚙️ APPLICATION TAB
    # ═══════════════════════════════════════════════════════════════════════════
    
    $appTab = New-Object System.Windows.Forms.TabPage
    $appTab.Text = "⚙️ Application / EXE"
    $appTab.BackColor = $global:Theme.Surface
    $appTab.Padding = New-Object System.Windows.Forms.Padding(15)
    $tabControl.TabPages.Add($appTab)
    
    # Application Name and Extension
    $appNameLabel = New-Object System.Windows.Forms.Label
    $appNameLabel.Location = New-Object System.Drawing.Point(20, 30)
    $appNameLabel.Size = New-Object System.Drawing.Size(120, 25)
    $appNameLabel.Text = "⚙️ App Name:"
    $appNameLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $appTab.Controls.Add($appNameLabel)
    
    $appNameTextBox = New-Object System.Windows.Forms.TextBox
    $appNameTextBox.Location = New-Object System.Drawing.Point(140, 28)
    $appNameTextBox.Size = New-Object System.Drawing.Size(280, 25)
    $appNameTextBox.Text = "Syncthing"
    $appNameTextBox.Font = New-Object System.Drawing.Font("Consolas", 10)
    $appTab.Controls.Add($appNameTextBox)
    
    $appExtensionCombo = New-Object System.Windows.Forms.ComboBox
    $appExtensionCombo.Location = New-Object System.Drawing.Point(430, 28)
    $appExtensionCombo.Size = New-Object System.Drawing.Size(80, 25)
    $appExtensionCombo.DropDownStyle = "DropDownList"
    $appExtensionCombo.Items.AddRange(@(".exe", ".msi"))
    $appExtensionCombo.SelectedIndex = 0
    $appTab.Controls.Add($appExtensionCombo)
    
    # Application Directory
    $appDirLabel = New-Object System.Windows.Forms.Label
    $appDirLabel.Location = New-Object System.Drawing.Point(20, 70)
    $appDirLabel.Size = New-Object System.Drawing.Size(120, 25)
    $appDirLabel.Text = "📁 Directory:"
    $appDirLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $appTab.Controls.Add($appDirLabel)
    
    $appDirTextBox = New-Object System.Windows.Forms.TextBox
    $appDirTextBox.Location = New-Object System.Drawing.Point(140, 68)
    $appDirTextBox.Size = New-Object System.Drawing.Size(300, 25)
    $appDirTextBox.Text = "C:\Syncthing"
    $appDirTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
    $appTab.Controls.Add($appDirTextBox)
    
    $appBrowseButton = New-Object System.Windows.Forms.Button
    $appBrowseButton.Location = New-Object System.Drawing.Point(450, 67)
    $appBrowseButton.Size = New-Object System.Drawing.Size(60, 27)
    $appBrowseButton.Text = "Browse"
    $appBrowseButton.BackColor = $global:Theme.Secondary
    $appBrowseButton.ForeColor = [System.Drawing.Color]::White
    $appBrowseButton.FlatStyle = "Flat"
    $appBrowseButton.Add_Click({
        $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $folderDialog.SelectedPath = if ($appDirTextBox.Text) { $appDirTextBox.Text } else { "C:\" }
        if ($folderDialog.ShowDialog() -eq "OK") {
            $appDirTextBox.Text = $folderDialog.SelectedPath
        }
    })
    $appTab.Controls.Add($appBrowseButton)
    
    # Application File Selection
    $appFileLabel = New-Object System.Windows.Forms.Label
    $appFileLabel.Location = New-Object System.Drawing.Point(20, 110)
    $appFileLabel.Size = New-Object System.Drawing.Size(150, 25)
    $appFileLabel.Text = "🎯 Select Application:"
    $appFileLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $appTab.Controls.Add($appFileLabel)
    
    $appFileSelectButton = New-Object System.Windows.Forms.Button
    $appFileSelectButton.Location = New-Object System.Drawing.Point(180, 108)
    $appFileSelectButton.Size = New-Object System.Drawing.Size(120, 27)
    $appFileSelectButton.Text = "Browse for EXE..."
    $appFileSelectButton.BackColor = $global:Theme.Primary
    $appFileSelectButton.ForeColor = [System.Drawing.Color]::White
    $appFileSelectButton.FlatStyle = "Flat"
    $appFileSelectButton.Add_Click({
        $fileDialog = New-Object System.Windows.Forms.OpenFileDialog
        $fileDialog.Filter = "Applications (*.exe)|*.exe|Installers (*.msi)|*.msi|All files (*.*)|*.*"
        $fileDialog.InitialDirectory = if ($appDirTextBox.Text) { $appDirTextBox.Text } else { "C:\" }
        
        if ($fileDialog.ShowDialog() -eq "OK") {
            $selectedFile = $fileDialog.FileName
            $fileInfo = Get-Item $selectedFile
            
            # Auto-populate fields
            $appNameTextBox.Text = [System.IO.Path]::GetFileNameWithoutExtension($selectedFile)
            $appDirTextBox.Text = $fileInfo.DirectoryName
            $appExtensionCombo.SelectedItem = $fileInfo.Extension
        }
    })
    $appTab.Controls.Add($appFileSelectButton)
    
    # Application Validation Panel
    $appValidationPanel = New-Object System.Windows.Forms.Panel
    $appValidationPanel.Location = New-Object System.Drawing.Point(20, 150)
    $appValidationPanel.Size = New-Object System.Drawing.Size(490, 120)
    $appValidationPanel.BorderStyle = "FixedSingle"
    $appValidationPanel.BackColor = [System.Drawing.Color]::FromArgb(248, 249, 250)
    $appTab.Controls.Add($appValidationPanel)
    
    $appValidationLabel = New-Object System.Windows.Forms.Label
    $appValidationLabel.Location = New-Object System.Drawing.Point(10, 10)
    $appValidationLabel.Size = New-Object System.Drawing.Size(470, 20)
    $appValidationLabel.Text = "🔍 Application Validation Results"
    $appValidationLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $appValidationPanel.Controls.Add($appValidationLabel)
    
    $appValidationTextBox = New-Object System.Windows.Forms.TextBox
    $appValidationTextBox.Location = New-Object System.Drawing.Point(10, 35)
    $appValidationTextBox.Size = New-Object System.Drawing.Size(470, 75)
    $appValidationTextBox.Multiline = $true
    $appValidationTextBox.ScrollBars = "Vertical"
    $appValidationTextBox.ReadOnly = $true
    $appValidationTextBox.BackColor = [System.Drawing.Color]::White
    $appValidationTextBox.Font = New-Object System.Drawing.Font("Consolas", 8)
    $appValidationTextBox.Text = "💡 Select an application to see validation results..."
    $appValidationPanel.Controls.Add($appValidationTextBox)
    
    # Real-time app validation
    $validateApp = {
        if ($appNameTextBox.Text -and $appDirTextBox.Text) {
            $fullPath = Join-Path $appDirTextBox.Text "$($appNameTextBox.Text)$($appExtensionCombo.SelectedItem)"
            $validation = Test-ExecutableApp $fullPath
            
            $validationText = "📊 Validation Score: $($validation.Score)/100`r`n"
            $validationText += "Status: $(if ($validation.IsValid) { '✅ Valid' } else { '❌ Issues Found' })`r`n`r`n"
            
            if ($validation.Errors) {
                $validationText += "❌ Errors:`r`n" + ($validation.Errors -join "`r`n") + "`r`n`r`n"
            }
            if ($validation.Warnings) {
                $validationText += "⚠️ Warnings:`r`n" + ($validation.Warnings -join "`r`n") + "`r`n`r`n"
            }
            if ($validation.Suggestions) {
                $validationText += "💡 Info:`r`n" + ($validation.Suggestions -join "`r`n")
            }
            
            $appValidationTextBox.Text = $validationText
        }
    }
    
    $appNameTextBox.Add_TextChanged($validateApp)
    $appDirTextBox.Add_TextChanged($validateApp)
    
    # ═══════════════════════════════════════════════════════════════════════════
    # 🎯 DIALOG BUTTONS
    # ═══════════════════════════════════════════════════════════════════════════
    
    $buttonPanel = New-Object System.Windows.Forms.Panel
    $buttonPanel.Location = New-Object System.Drawing.Point(20, 470)
    $buttonPanel.Size = New-Object System.Drawing.Size(560, 50)
    $buttonPanel.BackColor = $global:Theme.Light
    $addForm.Controls.Add($buttonPanel)
    
    $addButton = New-Object System.Windows.Forms.Button
    $addButton.Location = New-Object System.Drawing.Point(400, 10)
    $addButton.Size = New-Object System.Drawing.Size(75, 30)
    $addButton.Text = "Add"
    $addButton.BackColor = $global:Theme.Secondary
    $addButton.ForeColor = [System.Drawing.Color]::White
    $addButton.FlatStyle = "Flat"
    $addButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $addButton.DialogResult = "OK"
    $buttonPanel.Controls.Add($addButton)
    
    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Location = New-Object System.Drawing.Point(485, 10)
    $cancelButton.Size = New-Object System.Drawing.Size(75, 30)
    $cancelButton.Text = "Cancel"
    $cancelButton.BackColor = $global:Theme.TextMuted
    $cancelButton.ForeColor = [System.Drawing.Color]::White
    $cancelButton.FlatStyle = "Flat"
    $cancelButton.DialogResult = "Cancel"
    $buttonPanel.Controls.Add($cancelButton)
    
    $addForm.AcceptButton = $addButton
    $addForm.CancelButton = $cancelButton
    
    # Show dialog and process result
    $result = $addForm.ShowDialog()
    
    if ($result -eq "OK") {
        $isScript = ($tabControl.SelectedTab -eq $scriptTab)
        
        if ($isScript) {
            # Process Script
            $fullPath = Join-Path $dirTextBox.Text "$($fileNameTextBox.Text)$($extensionCombo.SelectedItem)"
            $validation = Test-PowerShellScript $fullPath
            
            if (-not $validation.IsValid) {
                $errorMsg = "Script validation failed:`n`n" + ($validation.Errors -join "`n")
                [System.Windows.Forms.MessageBox]::Show($errorMsg, "Validation Error", "OK", "Error")
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
            # Process Application
            $fullPath = Join-Path $appDirTextBox.Text "$($appNameTextBox.Text)$($appExtensionCombo.SelectedItem)"
            $validation = Test-ExecutableApp $fullPath
            
            if (-not $validation.IsValid) {
                $errorMsg = "Application validation failed:`n`n" + ($validation.Errors -join "`n")
                [System.Windows.Forms.MessageBox]::Show($errorMsg, "Validation Error", "OK", "Error")
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
        
        # Add to config
        $config.scripts = @($config.scripts) + $newItem
        
        if (Save-ScriptConfig $config) {
            Add-LogEntry "Successfully added: $($newItem.name)" "Success"
            [System.Windows.Forms.MessageBox]::Show(
                "✅ Item added successfully!`n`n$($newItem.name)`n`nRestart ServerManager to see the new button.", 
                "Success", "OK", "Information")
            $addForm.Dispose()
            return $true
        } else {
            [System.Windows.Forms.MessageBox]::Show("Failed to save configuration.", "Save Error", "OK", "Error")
        }
    }
    
    $addForm.Dispose()
    return $false
}

# ═══════════════════════════════════════════════════════════════════════════════
# ⚙️ REVOLUTIONARY SETTINGS SYSTEM
# ═══════════════════════════════════════════════════════════════════════════════

function Show-SettingsDialog {
    param($settings)
    
    $settingsForm = New-Object System.Windows.Forms.Form
    $settingsForm.Text = "⚙️ ServerManager V2 Settings"
    $settingsForm.Size = New-Object System.Drawing.Size(500, 400)
    $settingsForm.StartPosition = "CenterParent"
    $settingsForm.FormBorderStyle = "FixedDialog"
    $settingsForm.MaximizeBox = $false
    $settingsForm.BackColor = $global:Theme.Light
    
    # Settings categories using tabs
    $settingsTabControl = New-Object System.Windows.Forms.TabControl
    $settingsTabControl.Location = New-Object System.Drawing.Point(20, 20)
    $settingsTabControl.Size = New-Object System.Drawing.Size(450, 300)
    $settingsForm.Controls.Add($settingsTabControl)
    
    # General Settings Tab
    $generalTab = New-Object System.Windows.Forms.TabPage
    $generalTab.Text = "⚙️ General"
    $generalTab.BackColor = $global:Theme.Surface
    $settingsTabControl.TabPages.Add($generalTab)
    
    # ServiceManager Path
    $pathLabel = New-Object System.Windows.Forms.Label
    $pathLabel.Location = New-Object System.Drawing.Point(20, 30)
    $pathLabel.Size = New-Object System.Drawing.Size(150, 25)
    $pathLabel.Text = "🎯 ServiceManager Path:"
    $pathLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $generalTab.Controls.Add($pathLabel)
    
    $pathTextBox = New-Object System.Windows.Forms.TextBox
    $pathTextBox.Location = New-Object System.Drawing.Point(20, 60)
    $pathTextBox.Size = New-Object System.Drawing.Size(350, 25)
    $pathTextBox.Text = $settings.serviceManagerPath
    $pathTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
    $generalTab.Controls.Add($pathTextBox)
    
    $pathBrowseButton = New-Object System.Windows.Forms.Button
    $pathBrowseButton.Location = New-Object System.Drawing.Point(380, 59)
    $pathBrowseButton.Size = New-Object System.Drawing.Size(50, 27)
    $pathBrowseButton.Text = "..."
    $pathBrowseButton.BackColor = $global:Theme.Primary
    $pathBrowseButton.ForeColor = [System.Drawing.Color]::White
    $pathBrowseButton.FlatStyle = "Flat"
    $pathBrowseButton.Add_Click({
        $fileDialog = New-Object System.Windows.Forms.OpenFileDialog
        $fileDialog.Filter = "PowerShell Scripts (*.ps1)|*.ps1"
        $fileDialog.InitialDirectory = (Get-Location).Path
        if ($fileDialog.ShowDialog() -eq "OK") {
            $pathTextBox.Text = $fileDialog.FileName
        }
    })
    $generalTab.Controls.Add($pathBrowseButton)
    
    # Default Script Location
    $scriptLocationLabel = New-Object System.Windows.Forms.Label
    $scriptLocationLabel.Location = New-Object System.Drawing.Point(20, 100)
    $scriptLocationLabel.Size = New-Object System.Drawing.Size(150, 25)
    $scriptLocationLabel.Text = "📁 Default Script Location:"
    $scriptLocationLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $generalTab.Controls.Add($scriptLocationLabel)
    
    $scriptLocationTextBox = New-Object System.Windows.Forms.TextBox
    $scriptLocationTextBox.Location = New-Object System.Drawing.Point(20, 130)
    $scriptLocationTextBox.Size = New-Object System.Drawing.Size(350, 25)
    $scriptLocationTextBox.Text = $settings.defaultScriptLocation
    $scriptLocationTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
    $generalTab.Controls.Add($scriptLocationTextBox)
    
    # Auto-organize scripts checkbox
    $autoOrganizeCheckBox = New-Object System.Windows.Forms.CheckBox
    $autoOrganizeCheckBox.Location = New-Object System.Drawing.Point(20, 170)
    $autoOrganizeCheckBox.Size = New-Object System.Drawing.Size(300, 25)
    $autoOrganizeCheckBox.Text = "🗂️ Auto-organize scripts into start/stop folders"
    $autoOrganizeCheckBox.Checked = $settings.autoOrganizeScripts
    $autoOrganizeCheckBox.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $generalTab.Controls.Add($autoOrganizeCheckBox)
    
    # Show advanced options checkbox
    $advancedCheckBox = New-Object System.Windows.Forms.CheckBox
    $advancedCheckBox.Location = New-Object System.Drawing.Point(20, 200)
    $advancedCheckBox.Size = New-Object System.Drawing.Size(300, 25)
    $advancedCheckBox.Text = "🔧 Show advanced options in interface"
    $advancedCheckBox.Checked = $settings.showAdvancedOptions
    $advancedCheckBox.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $generalTab.Controls.Add($advancedCheckBox)
    
    # Buttons
    $saveButton = New-Object System.Windows.Forms.Button
    $saveButton.Location = New-Object System.Drawing.Point(300, 340)
    $saveButton.Size = New-Object System.Drawing.Size(75, 30)
    $saveButton.Text = "Save"
    $saveButton.BackColor = $global:Theme.Secondary
    $saveButton.ForeColor = [System.Drawing.Color]::White
    $saveButton.FlatStyle = "Flat"
    $saveButton.DialogResult = "OK"
    $settingsForm.Controls.Add($saveButton)
    
    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Location = New-Object System.Drawing.Point(385, 340)
    $cancelButton.Size = New-Object System.Drawing.Size(75, 30)
    $cancelButton.Text = "Cancel"
    $cancelButton.BackColor = $global:Theme.TextMuted
    $cancelButton.ForeColor = [System.Drawing.Color]::White
    $cancelButton.FlatStyle = "Flat"
    $cancelButton.DialogResult = "Cancel"
    $settingsForm.Controls.Add($cancelButton)
    
    $result = $settingsForm.ShowDialog()
    
    if ($result -eq "OK") {
        # Update settings
        $settings.serviceManagerPath = $pathTextBox.Text
        $settings.defaultScriptLocation = $scriptLocationTextBox.Text
        $settings.autoOrganizeScripts = $autoOrganizeCheckBox.Checked
        $settings.showAdvancedOptions = $advancedCheckBox.Checked
        
        if (Save-AppSettings $settings) {
            Add-LogEntry "Settings saved successfully" "Success"
            [System.Windows.Forms.MessageBox]::Show("✅ Settings saved successfully!", "Settings", "OK", "Information")
        } else {
            [System.Windows.Forms.MessageBox]::Show("❌ Failed to save settings.", "Error", "OK", "Error")
        }
    }
    
    $settingsForm.Dispose()
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🚀 ENHANCED EXECUTION ENGINE
# ═══════════════════════════════════════════════════════════════════════════════

function Execute-EnhancedService {
    param($service, $showPopup = $true)
    
    if ($service.mode -eq "Application") {
        # Execute Application
        $fullPath = Join-Path $service.directory "$($service.fileName)$($service.extension)"
        
        Add-LogEntry "Launching application: $($service.name)" "Info"
        Add-LogEntry "Path: $fullPath" "Info"
        
        if (-not (Test-Path $fullPath)) {
            $errorMsg = "Application not found: $fullPath"
            Add-LogEntry $errorMsg "Error"
            if ($showPopup) {
                [System.Windows.Forms.MessageBox]::Show($errorMsg, "Application Missing", "OK", "Error")
            }
            return $false
        }
        
        try {
            # Change to application directory and launch
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
        # Execute PowerShell Script (Enhanced from V1)
        $fullPath = Join-Path $service.directory "$($service.fileName)$($service.extension)"
        
        Add-LogEntry "Executing script: $($service.name)" "Info"
        Add-LogEntry "Path: $fullPath" "Info"
        
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
                # For Start All - use tabs in current window
                $tabId = [System.Guid]::NewGuid().ToString("N")[0..7] -join ""
                $global:ActiveTabs[$service.name] = $tabId
                
                Start-Process -FilePath "wt" -ArgumentList @(
                    "new-tab",
                    "--title", "`"$($service.name)`"",
                    "PowerShell", "-NoExit", 
                    "-Command", "Set-Location '$($service.directory)'; Write-Host '[SCRIPT] $($service.name)' -ForegroundColor Green; & '.\$($service.fileName)$($service.extension)'"
                )
            } else {
                # Individual service - separate window
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
# 🎮 MAIN APPLICATION INTERFACE
# ═══════════════════════════════════════════════════════════════════════════════

# Initialization
Write-Host "╔═══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║              🚀 SERVER MANAGER V2 - REVOLUTIONARY EDITION 🚀                ║" -ForegroundColor Cyan
Write-Host "║                          ⚡ Initializing... ⚡                              ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

# Check Windows Terminal
$global:HasWindowsTerminal = $false
try {
    $null = Get-Command wt -ErrorAction Stop
    $global:HasWindowsTerminal = $true
    Write-Host "✅ Windows Terminal detected" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Windows Terminal not found - using standard PowerShell" -ForegroundColor Yellow
}

# Load configurations
$config = Load-ScriptConfig
$settings = Load-AppSettings

# Create Revolutionary Main Form
$form = New-Object System.Windows.Forms.Form
$form.Text = "🚀 ServerManager V2 - Revolutionary Edition"
$form.Size = New-Object System.Drawing.Size(900, 700)
$form.MinimumSize = New-Object System.Drawing.Size(800, 600)
$form.StartPosition = "CenterScreen"
$form.BackColor = $global:Theme.Light
$form.Font = New-Object System.Drawing.Font("Segoe UI", 9)

# Modern Header with Gradient Effect
$headerPanel = New-Object System.Windows.Forms.Panel
$headerPanel.Location = New-Object System.Drawing.Point(0, 0)
$headerPanel.Size = New-Object System.Drawing.Size(900, 80)
$headerPanel.BackColor = $global:Theme.Primary
$headerPanel.Anchor = "Top,Left,Right"
$form.Controls.Add($headerPanel)

$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Location = New-Object System.Drawing.Point(30, 15)
$titleLabel.Size = New-Object System.Drawing.Size(600, 35)
$titleLabel.Text = "🚀 ServerManager V2 - Revolutionary Edition"
$titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
$titleLabel.ForeColor = [System.Drawing.Color]::White
$titleLabel.BackColor = [System.Drawing.Color]::Transparent
$headerPanel.Controls.Add($titleLabel)

$subtitleLabel = New-Object System.Windows.Forms.Label
$subtitleLabel.Location = New-Object System.Drawing.Point(30, 50)
$subtitleLabel.Size = New-Object System.Drawing.Size(600, 20)
$subtitleLabel.Text = "⚡ Professional Application & Service Launcher ⚡"
$subtitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$subtitleLabel.ForeColor = [System.Drawing.Color]::LightGray
$subtitleLabel.BackColor = [System.Drawing.Color]::Transparent
$headerPanel.Controls.Add($subtitleLabel)

# Settings Dropdown (3-line menu) - REVOLUTIONARY FEATURE!
$settingsMenuButton = New-Object System.Windows.Forms.Button
$settingsMenuButton.Location = New-Object System.Drawing.Point(820, 20)
$settingsMenuButton.Size = New-Object System.Drawing.Size(50, 40)
$settingsMenuButton.Text = "☰"
$settingsMenuButton.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$settingsMenuButton.BackColor = [System.Drawing.Color]::FromArgb(255, 255, 255, 30)
$settingsMenuButton.ForeColor = [System.Drawing.Color]::White
$settingsMenuButton.FlatStyle = "Flat"
$settingsMenuButton.FlatAppearance.BorderSize = 1
$settingsMenuButton.FlatAppearance.BorderColor = [System.Drawing.Color]::White
$settingsMenuButton.Anchor = "Top,Right"
$settingsMenuButton.Add_Click({
    $menu = New-Object System.Windows.Forms.ContextMenuStrip
    $menu.BackColor = $global:Theme.Surface
    $menu.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    
    $settingsItem = New-Object System.Windows.Forms.ToolStripMenuItem
    $settingsItem.Text = "⚙️  Settings"
    $settingsItem.Add_Click({ Show-SettingsDialog $settings })
    $menu.Items.Add($settingsItem)
    
    $restartItem = New-Object System.Windows.Forms.ToolStripMenuItem
    $restartItem.Text = "🔄 Restart Application"
    $restartItem.Add_Click({
        $result = [System.Windows.Forms.MessageBox]::Show("Restart ServerManager V2?", "Restart", "YesNo", "Question")
        if ($result -eq "Yes") {
            $form.Close()
            Start-Process -FilePath "powershell" -ArgumentList "-ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`""
        }
    })
    $menu.Items.Add($restartItem)
    
    $menu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))
    
    $scriptsItem = New-Object System.Windows.Forms.ToolStripMenuItem
    $scriptsItem.Text = "📁 Open Script Folders"
    $scriptsItem.Add_Click({
        if (Test-Path ".\scripts") {
            Start-Process "explorer.exe" -ArgumentList ".\scripts"
        } else {
            [System.Windows.Forms.MessageBox]::Show("Scripts folder not found", "Info", "OK", "Information")
        }
    })
    $menu.Items.Add($scriptsItem)
    
    $exportItem = New-Object System.Windows.Forms.ToolStripMenuItem
    $exportItem.Text = "📋 Export Configuration"
    $exportItem.Add_Click({
        $saveDialog = New-Object System.Windows.Forms.SaveFileDialog
        $saveDialog.Filter = "JSON files (*.json)|*.json"
        $saveDialog.DefaultExt = "json"
        $saveDialog.FileName = "servermanager-config-$(Get-Date -Format 'yyyyMMdd').json"
        if ($saveDialog.ShowDialog() -eq "OK") {
            Copy-Item $global:ConfigFile $saveDialog.FileName
            [System.Windows.Forms.MessageBox]::Show("Configuration exported successfully!", "Export", "OK", "Information")
        }
    })
    $menu.Items.Add($exportItem)
    
    $menu.Show($settingsMenuButton, 0, $settingsMenuButton.Height)
})
$headerPanel.Controls.Add($settingsMenuButton)

# Enhanced Management Panel
$managementPanel = New-Object System.Windows.Forms.Panel
$managementPanel.Location = New-Object System.Drawing.Point(20, 90)
$managementPanel.Size = New-Object System.Drawing.Size(860, 50)
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
    if (Show-EnhancedAddDialog $config) {
        Add-LogEntry "Item added - restart to see changes" "Info"
    }
})
$managementPanel.Controls.Add($addButton)

$removeButton = New-Object System.Windows.Forms.Button
$removeButton.Location = New-Object System.Drawing.Point(145, 12)
$removeButton.Size = New-Object System.Drawing.Size(100, 28)
$removeButton.Text = "🗑️ Remove"
$removeButton.BackColor = $global:Theme.Danger
$removeButton.ForeColor = [System.Drawing.Color]::White
$removeButton.FlatStyle = "Flat"
$removeButton.Add_Click({
    # Enhanced remove dialog (implementation would go here)
    [System.Windows.Forms.MessageBox]::Show("Remove functionality - Enhanced version coming soon!", "Info", "OK", "Information")
})
$managementPanel.Controls.Add($removeButton)

$refreshButton = New-Object System.Windows.Forms.Button
$refreshButton.Location = New-Object System.Drawing.Point(255, 12)
$refreshButton.Size = New-Object System.Drawing.Size(100, 28)
$refreshButton.Text = "🔄 Refresh"
$refreshButton.BackColor = $global:Theme.Accent
$refreshButton.ForeColor = [System.Drawing.Color]::White
$refreshButton.FlatStyle = "Flat"
$refreshButton.Add_Click({
    $global:LogTextBox.Clear()
    $global:LogEntries.Clear()
    Add-LogEntry "Interface refreshed" "Success"
    Add-LogEntry "Loaded $($config.scripts.Count) items" "Info"
})
$managementPanel.Controls.Add($refreshButton)

# Revolutionary Services Panel with Categories
$servicesPanel = New-Object System.Windows.Forms.Panel
$servicesPanel.Location = New-Object System.Drawing.Point(20, 150)
$servicesPanel.Size = New-Object System.Drawing.Size(860, 280)
$servicesPanel.BorderStyle = "FixedSingle"
$servicesPanel.BackColor = $global:Theme.Surface
$servicesPanel.AutoScroll = $true
$servicesPanel.Anchor = "Top,Left,Right"
$form.Controls.Add($servicesPanel)

# Create service buttons with enhanced styling
$buttonY = 15
$buttonHeight = 40
$buttonSpacing = 5
$categorySpacing = 25

# Group by category for better organization
$groupedServices = $config.scripts | Group-Object category

foreach ($categoryGroup in $groupedServices) {
    # Category header
    $categoryLabel = New-Object System.Windows.Forms.Label
    $categoryLabel.Location = New-Object System.Drawing.Point(15, $buttonY)
    $categoryLabel.Size = New-Object System.Drawing.Size(820, 20)
    $categoryLabel.Text = "📁 $($categoryGroup.Name)"
    $categoryLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
    $categoryLabel.ForeColor = $global:Theme.Primary
    $categoryLabel.Anchor = "Top,Left,Right"
    $servicesPanel.Controls.Add($categoryLabel)
    
    $buttonY += $categorySpacing
    
    foreach ($service in $categoryGroup.Group) {
        $button = New-Object System.Windows.Forms.Button
        $button.Location = New-Object System.Drawing.Point(15, $buttonY)
        $button.Size = New-Object System.Drawing.Size(820, $buttonHeight)
        $button.Text = "$($service.icon) $($service.name) $(if ($service.mode -eq 'Application') { '⚙️' } else { '📜' })"
        $button.BackColor = [System.Drawing.Color]::$($service.color)
        $button.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
        $button.FlatStyle = "Flat"
        $button.FlatAppearance.BorderSize = 0
        $button.Tag = $service
        $button.Anchor = "Top,Left,Right"
        $button.TextAlign = "MiddleLeft"
        $button.Padding = New-Object System.Windows.Forms.Padding(20, 0, 0, 0)
        
        # Enhanced hover effects
        $button.Add_MouseEnter({
            $this.BackColor = [System.Drawing.Color]::FromArgb(220, $this.BackColor.R, $this.BackColor.G, $this.BackColor.B)
        })
        $button.Add_MouseLeave({
            $this.BackColor = [System.Drawing.Color]::$($this.Tag.color)
        })
        
        # Click event with enhanced execution
        $button.Add_Click({
            $svc = $this.Tag
            
            # Handle built-in services with special logic
            if ($svc.isBuiltIn -and $svc.type -eq "mcp-stop") {
                # Keep existing MCP stop logic
                Add-LogEntry "Stopping MCP Server (port 4000)..." "Info"
                $portProcesses = netstat -ano | findstr ":4000"
                if ($portProcesses) {
                    $processIds = $portProcesses | ForEach-Object { ($_ -split '\s+')[-1] } | Select-Object -Unique
                    foreach ($processId in $processIds) {
                        if ($processId -and $processId -ne "0") {
                            try {
                                taskkill /PID $processId /F 2>$null
                                Add-LogEntry "Killed MCP process PID $processId" "Success"
                            } catch {
                                Add-LogEntry "Could not kill PID $processId" "Warning"
                            }
                        }
                    }
                } else {
                    Add-LogEntry "No MCP processes found on port 4000" "Info"
                }
            } elseif ($svc.isBuiltIn -and $svc.type -eq "n8n-stop") {
                # Keep existing n8n stop logic
                Add-LogEntry "Stopping n8n environment..." "Info"
                try {
                    $n8nDir = "C:\aiMain\Zoe\Dockern8n"
                    if (Test-Path $n8nDir) {
                        Push-Location $n8nDir
                        docker-compose down 2>&1
                        Pop-Location
                        Add-LogEntry "Docker compose down completed" "Success"
                    }
                } catch {
                    Add-LogEntry "Could not stop containers" "Warning"
                }
            } else {
                # Use enhanced execution for all other services
                Execute-EnhancedService $svc $true
            }
        })
        
        $servicesPanel.Controls.Add($button)
        $buttonY += ($buttonHeight + $buttonSpacing)
    }
    
    $buttonY += 10  # Extra spacing between categories
}

# Enhanced Control Panel
$controlPanel = New-Object System.Windows.Forms.Panel
$controlPanel.Location = New-Object System.Drawing.Point(20, 440)
$controlPanel.Size = New-Object System.Drawing.Size(860, 60)
$controlPanel.BackColor = $global:Theme.Dark
$controlPanel.BorderStyle = "FixedSingle"
$controlPanel.Anchor = "Top,Left,Right"
$form.Controls.Add($controlPanel)

# Quick action buttons with modern styling
$startAllButton = New-Object System.Windows.Forms.Button
$startAllButton.Location = New-Object System.Drawing.Point(15, 15)
$startAllButton.Size = New-Object System.Drawing.Size(100, 30)
$startAllButton.Text = "🚀 Start All"
$startAllButton.BackColor = $global:Theme.Secondary
$startAllButton.ForeColor = [System.Drawing.Color]::White
$startAllButton.FlatStyle = "Flat"
$startAllButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$startAllButton.Add_Click({
    Add-LogEntry "Starting all services..." "Info"
    $startServices = $config.scripts | Where-Object { $_.type -like "*start*" -or $_.mode -eq "Application" }
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
    
    $message = "Start All Results:`n`n" + ($results -join "`n")
    [System.Windows.Forms.MessageBox]::Show($message, "Start All Complete", "OK", "Information")
    Add-LogEntry "Start All completed" "Success"
})
$controlPanel.Controls.Add($startAllButton)

$stopAllButton = New-Object System.Windows.Forms.Button
$stopAllButton.Location = New-Object System.Drawing.Point(125, 15)
$stopAllButton.Size = New-Object System.Drawing.Size(100, 30)
$stopAllButton.Text = "🛑 Stop All"
$stopAllButton.BackColor = $global:Theme.Danger
$stopAllButton.ForeColor = [System.Drawing.Color]::White
$stopAllButton.FlatStyle = "Flat"
$stopAllButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$stopAllButton.Add_Click({
    Add-LogEntry "Stopping all services..." "Info"
    [System.Windows.Forms.MessageBox]::Show("Enhanced Stop All functionality - Implementation in progress!", "Info", "OK", "Information")
})
$controlPanel.Controls.Add($stopAllButton)

$testButton = New-Object System.Windows.Forms.Button
$testButton.Location = New-Object System.Drawing.Point(235, 15)
$testButton.Size = New-Object System.Drawing.Size(120, 30)
$testButton.Text = "🔍 Validate All"
$testButton.BackColor = $global:Theme.Accent
$testButton.ForeColor = [System.Drawing.Color]::White
$testButton.FlatStyle = "Flat"
$testButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$testButton.Add_Click({
    Add-LogEntry "Validating all items..." "Info"
    $results = @()
    
    foreach ($service in $config.scripts) {
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
    
    $message = "Validation Results:`n`n" + ($results -join "`n")
    [System.Windows.Forms.MessageBox]::Show($message, "Validation Complete", "OK", "Information")
})
$controlPanel.Controls.Add($testButton)

$clearLogsButton = New-Object System.Windows.Forms.Button
$clearLogsButton.Location = New-Object System.Drawing.Point(365, 15)
$clearLogsButton.Size = New-Object System.Drawing.Size(100, 30)
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

# Enhanced Logs Section
$logsLabel = New-Object System.Windows.Forms.Label
$logsLabel.Location = New-Object System.Drawing.Point(20, 510)
$logsLabel.Size = New-Object System.Drawing.Size(200, 25)
$logsLabel.Text = "📋 Activity Logs & System Status"
$logsLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$logsLabel.ForeColor = $global:Theme.Text
$logsLabel.Anchor = "Top,Left"
$form.Controls.Add($logsLabel)

$global:LogTextBox = New-Object System.Windows.Forms.RichTextBox
$global:LogTextBox.Location = New-Object System.Drawing.Point(20, 540)
$global:LogTextBox.Size = New-Object System.Drawing.Size(860, 130)
$global:LogTextBox.Multiline = $true
$global:LogTextBox.ScrollBars = "Vertical"
$global:LogTextBox.ReadOnly = $true
$global:LogTextBox.BackColor = [System.Drawing.Color]::Black
$global:LogTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
$global:LogTextBox.Anchor = "Top,Bottom,Left,Right"
$form.Controls.Add($global:LogTextBox)

# Initialize startup logs
Add-LogEntry "🚀 ServerManager V2 Revolutionary Edition started" "Success"
Add-LogEntry "Loaded $($config.scripts.Count) items from configuration" "Info"
Add-LogEntry "Windows Terminal: $(if ($global:HasWindowsTerminal) { 'Available ✅' } else { 'Not found ⚠️' })" "Info"
Add-LogEntry "Configuration version: $($config.version)" "Info"
Add-LogEntry "Ready for action! 🎯" "Success"

Write-Host "✅ Showing ServerManager V2 Revolutionary Edition..." -ForegroundColor Green

# Show the revolutionary form
[System.Windows.Forms.Application]::Run($form)

Write-Host "🎯 ServerManager V2 Revolutionary Edition closed" -ForegroundColor Cyan