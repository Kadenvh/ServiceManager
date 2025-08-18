# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║                    🚀 SERVER MANAGER V2 - FINAL EDITION 🚀                  ║
# ║                          ⚡ Built for Power Users ⚡                         ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Windows.Forms.Application]::EnableVisualStyles()
[System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)

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

# Global Configuration
$global:ConfigFile = ".\scripts_storage.json"
$global:SettingsFile = ".\app_settings.json"
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
        serviceManagerPath = ".\ServerManager-V2.ps1"
        defaultScriptLocation = ".\scripts\"
        autoOrganizeScripts = $true
        theme = "Modern"
        enableNotifications = $true
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
        categories = @("AI Services", "Automation", "Development", "System", "Applications")
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

function Show-EnhancedAddDialog {
    param($config)
    
    $addForm = New-Object System.Windows.Forms.Form
    $addForm.Text = "Add New Item - ServerManager V2"
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
    $appNameTextBox.Text = "Syncthing"
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
    $appDirTextBox.Text = "C:\Syncthing"
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
            [System.Windows.Forms.MessageBox]::Show("✅ Item added successfully!`n`nRestart ServerManager to see the new button.", "Success", "OK", "Information")
            $addForm.Dispose()
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
    $settingsForm.Text = "⚙️ ServerManager V2 Settings"
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
    
    # Buttons
    $saveButton = New-Object System.Windows.Forms.Button
    $saveButton.Location = New-Object System.Drawing.Point(280, 250)
    $saveButton.Size = New-Object System.Drawing.Size(75, 30)
    $saveButton.Text = "Save"
    $saveButton.BackColor = $global:Theme.Secondary
    $saveButton.ForeColor = [System.Drawing.Color]::White
    $saveButton.FlatStyle = "Flat"
    $saveButton.DialogResult = "OK"
    $settingsForm.Controls.Add($saveButton)
    
    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Location = New-Object System.Drawing.Point(365, 250)
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
    param($config)
    
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
                [System.Windows.Forms.MessageBox]::Show("✅ Service removed successfully!`n`nRestart to update interface.", "Removed", "OK", "Information")
                $removeForm.Dispose()
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
    
    # Stop built-in services with enhanced detection
    $builtInStops = $config.scripts | Where-Object { $_.isBuiltIn -and ($_.type -like "*stop*" -or $_.type -eq "mcp-stop" -or $_.type -eq "n8n-stop") }
    foreach ($service in $builtInStops) {
        $success = $false
        $processCount = 0
        
        if ($service.type -eq "mcp-stop") {
            # Enhanced MCP Server stopping
            $portProcesses = netstat -ano 2>$null | findstr ":4000"
            if ($portProcesses) {
                $processIds = $portProcesses | ForEach-Object { ($_ -split '\s+')[-1] } | Select-Object -Unique | Where-Object { $_ -and $_ -ne "0" }
                foreach ($processId in $processIds) {
                    try {
                        $process = Get-Process -Id $processId -ErrorAction SilentlyContinue
                        if ($process) {
                            Stop-Process -Id $processId -Force -ErrorAction SilentlyContinue
                            Add-LogEntry "Killed MCP process: $($process.ProcessName) (PID: $processId)" "Success"
                            $processCount++
                            $success = $true
                        }
                    } catch {
                        Add-LogEntry "Could not kill PID $processId" "Warning"
                    }
                }
            }
            
            # Also check for processes by name
            $mcpProcesses = Get-Process | Where-Object { $_.ProcessName -like "*mcp*" -or $_.MainWindowTitle -like "*mcp*" } -ErrorAction SilentlyContinue
            foreach ($process in $mcpProcesses) {
                try {
                    Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
                    Add-LogEntry "Killed MCP-related process: $($process.ProcessName)" "Success"
                    $processCount++
                    $success = $true
                } catch { }
            }
            
        } elseif ($service.type -eq "n8n-stop") {
            # Enhanced n8n stopping
            try {
                # Stop Docker containers
                $n8nDir = "C:\aiMain\Zoe\Dockern8n"
                if (Test-Path $n8nDir) {
                    Push-Location $n8nDir
                    $dockerResult = docker-compose down 2>&1
                    Pop-Location
                    Add-LogEntry "Docker compose down completed" "Success"
                    $processCount++
                    $success = $true
                }
            } catch {
                Add-LogEntry "Could not stop Docker containers" "Warning"
            }
            
            # Stop processes on port 5678
            $portProcesses = netstat -ano 2>$null | findstr ":5678"
            if ($portProcesses) {
                $processIds = $portProcesses | ForEach-Object { ($_ -split '\s+')[-1] } | Select-Object -Unique | Where-Object { $_ -and $_ -ne "0" }
                foreach ($processId in $processIds) {
                    try {
                        $process = Get-Process -Id $processId -ErrorAction SilentlyContinue
                        if ($process) {
                            Stop-Process -Id $processId -Force -ErrorAction SilentlyContinue
                            Add-LogEntry "Killed n8n process: $($process.ProcessName) (PID: $processId)" "Success"
                            $processCount++
                            $success = $true
                        }
                    } catch { }
                }
            }
            
            # Stop ngrok processes
            $ngrokProcesses = Get-Process -Name "ngrok" -ErrorAction SilentlyContinue
            foreach ($process in $ngrokProcesses) {
                try {
                    Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
                    Add-LogEntry "Stopped ngrok process" "Success"
                    $processCount++
                    $success = $true
                } catch { }
            }
        }
        
        if ($success) {
            $results += "✅ $($service.name) ($processCount processes stopped)"
        } else {
            $results += "ℹ️ $($service.name) (no processes found)"
        }
        Start-Sleep 1
    }
    
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

Write-Host "🚀 ServerManager V2 - Final Edition Starting..." -ForegroundColor Cyan

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
$config = Load-ScriptConfig
$settings = Load-AppSettings

# Create Optimized Main Form
$form = New-Object System.Windows.Forms.Form
$form.Text = "🚀 ServerManager V2 - Final Edition"
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
$titleLabel.Text = "🚀 ServerManager V2 - Final Edition"
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
    $settingsItem.Add_Click({ Show-SettingsDialog $settings })
    $menu.Items.Add($settingsItem)
    
    $restartItem = New-Object System.Windows.Forms.ToolStripMenuItem
    $restartItem.Text = "🔄 Restart Application"
    $restartItem.Add_Click({
        if ([System.Windows.Forms.MessageBox]::Show("Restart ServerManager V2?", "Restart", "YesNo", "Question") -eq "Yes") {
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
        }
    })
    $menu.Items.Add($scriptsItem)
    
    $exportItem = New-Object System.Windows.Forms.ToolStripMenuItem
    $exportItem.Text = "📋 Export Configuration"
    $exportItem.Add_Click({
        $saveDialog = New-Object System.Windows.Forms.SaveFileDialog
        $saveDialog.Filter = "JSON files (*.json)|*.json"
        $saveDialog.FileName = "servermanager-config-$(Get-Date -Format 'yyyyMMdd').json"
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
    if (Show-RemoveDialog $config) {
        Add-LogEntry "Service removed - restart to see changes" "Info"
    }
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

# OPTIMIZED HORIZONTAL LAYOUT - Services on Left, Logs on Right
$servicesPanel = New-Object System.Windows.Forms.Panel
$servicesPanel.Location = New-Object System.Drawing.Point(20, 140)
$servicesPanel.Size = New-Object System.Drawing.Size(480, 350)
$servicesPanel.BorderStyle = "FixedSingle"
$servicesPanel.BackColor = $global:Theme.Surface
$servicesPanel.AutoScroll = $true
$servicesPanel.Anchor = "Top,Left,Bottom"
$form.Controls.Add($servicesPanel)

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
        $button = New-Object System.Windows.Forms.Button
        $button.Location = New-Object System.Drawing.Point(15, $buttonY)
        $button.Size = New-Object System.Drawing.Size(440, $buttonHeight)
        $button.Text = "$($service.icon) $($service.name) $(if ($service.mode -eq 'Application') { '⚙️' } else { '📜' })"
        $button.BackColor = [System.Drawing.Color]::$($service.color)
        $button.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $button.FlatStyle = "Flat"
        $button.Tag = $service
        $button.TextAlign = "MiddleLeft"
        $button.Padding = New-Object System.Windows.Forms.Padding(15, 0, 0, 0)
        
        # Enhanced hover effects
        $button.Add_MouseEnter({
            $this.BackColor = [System.Drawing.Color]::FromArgb(220, $this.BackColor.R, $this.BackColor.G, $this.BackColor.B)
        })
        $button.Add_MouseLeave({
            $this.BackColor = [System.Drawing.Color]::$($this.Tag.color)
        })
        
        # Click event
        $button.Add_Click({
            $svc = $this.Tag
            
            if ($svc.isBuiltIn -and $svc.type -eq "mcp-stop") {
                # MCP stop logic
                Add-LogEntry "Stopping MCP Server..." "Info"
                $portProcesses = netstat -ano 2>$null | findstr ":4000"
                if ($portProcesses) {
                    $processIds = $portProcesses | ForEach-Object { ($_ -split '\s+')[-1] } | Select-Object -Unique
                    foreach ($processId in $processIds) {
                        if ($processId -and $processId -ne "0") {
                            try {
                                Stop-Process -Id $processId -Force -ErrorAction SilentlyContinue
                                Add-LogEntry "Killed MCP process PID $processId" "Success"
                            } catch { }
                        }
                    }
                }
            } elseif ($svc.isBuiltIn -and $svc.type -eq "n8n-stop") {
                # n8n stop logic
                Add-LogEntry "Stopping n8n..." "Info"
                try {
                    $n8nDir = "C:\aiMain\Zoe\Dockern8n"
                    if (Test-Path $n8nDir) {
                        Push-Location $n8nDir
                        docker-compose down 2>&1
                        Pop-Location
                        Add-LogEntry "Docker compose down completed" "Success"
                    }
                } catch { }
            } else {
                Execute-EnhancedService $svc $true
            }
        })
        
        $servicesPanel.Controls.Add($button)
        $buttonY += ($buttonHeight + $buttonSpacing)
    }
    
    $buttonY += 10
}

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
    Stop-AllServices $config
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
Add-LogEntry "🚀 ServerManager V2 Final Edition started" "Success"
Add-LogEntry "Loaded $($config.scripts.Count) items from configuration" "Info"
Add-LogEntry "Windows Terminal: $(if ($global:HasWindowsTerminal) { 'Available ✅' } else { 'Not found ⚠️' })" "Info"
Add-LogEntry "Ready for action! 🎯" "Success"

Write-Host "✅ Showing ServerManager V2 Final Edition..." -ForegroundColor Green

# Show the form
[System.Windows.Forms.Application]::Run($form)

Write-Host "🎯 ServerManager V2 Final Edition closed" -ForegroundColor Cyan