# Check if running as a standalone setup or integrated check
param(
    [switch]$IntegratedSetup = $false
)

# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║                         🚀 SERVICE MANAGER SETUP 🚀                         ║
# ║                     ⚡ Initial Configuration Wizard ⚡                      ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Windows.Forms.Application]::EnableVisualStyles()
[System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "❌ This script must be run as Administrator" -ForegroundColor Red
    [System.Windows.Forms.MessageBox]::Show(
        "This script must be run as Administrator.`n`nPlease right-click the script and select 'Run as Administrator'",
        "Administrator Required",
        "OK",
        "Error"
    )
    exit 1
}

# Detect ServiceManager folder
$scriptPath = $MyInvocation.MyCommand.Path
$defaultServiceManagerPath = Split-Path -Parent $scriptPath

# Function to prompt for ServiceManager folder if not detected
function Get-ServiceManagerFolder {
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowser.Description = "Select the ServiceManager folder"
    $folderBrowser.SelectedPath = $defaultServiceManagerPath
    
    if ($folderBrowser.ShowDialog() -eq "OK") {
        return $folderBrowser.SelectedPath
    }
    return $null
}

# Verify or prompt for ServiceManager folder
$serviceManagerPath = $defaultServiceManagerPath
if (-not (Test-Path (Join-Path $serviceManagerPath "ServiceManager.ps1"))) {
    Write-Host "❌ ServiceManager.ps1 not found in the current directory" -ForegroundColor Red
    $serviceManagerPath = Get-ServiceManagerFolder
    
    if (-not $serviceManagerPath) {
        Write-Host "❌ Setup cancelled - ServiceManager folder not selected" -ForegroundColor Red
        exit 1
    }
    
    if (-not (Test-Path (Join-Path $serviceManagerPath "ServiceManager.ps1"))) {
        Write-Host "❌ Invalid ServiceManager folder selected" -ForegroundColor Red
        [System.Windows.Forms.MessageBox]::Show(
            "The selected folder does not contain ServiceManager.ps1.`n`nPlease select the correct ServiceManager folder.",
            "Invalid Folder",
            "OK",
            "Error"
        )
        exit 1
    }
}

Write-Host "✅ ServiceManager folder found: $serviceManagerPath" -ForegroundColor Green

# Set up permissions
Write-Host "🔒 Setting up permissions..." -ForegroundColor Cyan
$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

try {
    # Set permissions for the ServiceManager directory and all subdirectories
    $acl = Get-Acl $serviceManagerPath
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        $currentUser,
        "FullControl",
        "ContainerInherit,ObjectInherit",
        "None",
        "Allow"
    )
    $acl.SetAccessRule($rule)
    Set-Acl $serviceManagerPath $acl
    Write-Host "✅ Permissions set successfully" -ForegroundColor Green
}
catch {
    Write-Host "❌ Failed to set permissions: $($_.Exception.Message)" -ForegroundColor Red
    [System.Windows.Forms.MessageBox]::Show(
        "Failed to set permissions:`n`n$($_.Exception.Message)`n`nPlease ensure you have administrative rights.",
        "Permission Error",
        "OK",
        "Error"
    )
    exit 1
}

# Update global paths
$global:UserConfigPath = Join-Path $serviceManagerPath "user_config"
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

# Global Setup Variables
$global:SetupServices = @()

Write-Host "🚀 ServiceManager Setup Starting..." -ForegroundColor Cyan

# ═══════════════════════════════════════════════════════════════════════════════
# 🔧 SETUP FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

function Test-PowerShellScript {
    param($FilePath)
    
    if (-not (Test-Path $FilePath)) {
        return @{ IsValid = $false; Errors = @("File not found") }
    }
    
    try {
        $content = Get-Content $FilePath -Raw -ErrorAction Stop
        $null = [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$null, [ref]$null)
        return @{ IsValid = $true; Errors = @() }
    } catch {
        return @{ IsValid = $false; Errors = @("PowerShell syntax error: $($_.Exception.Message)") }
    }
}

function Test-ExecutableApp {
    param($FilePath)
    
    if (-not (Test-Path $FilePath)) {
        return @{ IsValid = $false; Errors = @("Application not found") }
    }
    
    $fileInfo = Get-Item $FilePath
    if ($fileInfo.Extension -notin @('.exe', '.msi')) {
        return @{ IsValid = $false; Errors = @("Not a valid executable file") }
    }
    
    return @{ IsValid = $true; Errors = @() }
}

function Show-AddServiceDialog {
    $addForm = New-Object System.Windows.Forms.Form
    $addForm.Text = "Add Service - Setup"
    $addForm.Size = New-Object System.Drawing.Size(600, 500)
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
    $headerLabel.Text = "🚀 Add Script or Application"
    $headerLabel.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
    $headerLabel.ForeColor = [System.Drawing.Color]::White
    $headerPanel.Controls.Add($headerLabel)
    
    # Tab Control
    $tabControl = New-Object System.Windows.Forms.TabControl
    $tabControl.Location = New-Object System.Drawing.Point(20, 80)
    $tabControl.Size = New-Object System.Drawing.Size(560, 330)
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
    $categoryCombo.Items.AddRange(@("AI Services", "Automation", "Development", "System", "Applications", "Custom"))
    $categoryCombo.SelectedIndex = 5  # Default to Custom
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
    $addButton.Location = New-Object System.Drawing.Point(420, 430)
    $addButton.Size = New-Object System.Drawing.Size(75, 30)
    $addButton.Text = "Add"
    $addButton.BackColor = $global:Theme.Secondary
    $addButton.ForeColor = [System.Drawing.Color]::White
    $addButton.FlatStyle = "Flat"
    $addButton.DialogResult = "OK"
    $addForm.Controls.Add($addButton)
    
    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Location = New-Object System.Drawing.Point(505, 430)
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
                return $null
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
                return $null
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
        
        $addForm.Dispose()
        return $newItem
    }
    
    $addForm.Dispose()
    return $null
}

function Show-SetupWizard {
    $setupForm = New-Object System.Windows.Forms.Form
    $setupForm.Text = "🚀 ServiceManager Setup Wizard"
    $setupForm.Size = New-Object System.Drawing.Size(800, 600)
    $setupForm.StartPosition = "CenterScreen"
    $setupForm.FormBorderStyle = "FixedDialog"
    $setupForm.MaximizeBox = $false
    $setupForm.MinimizeBox = $false
    $setupForm.BackColor = $global:Theme.Light
    
    # Header Panel
    $headerPanel = New-Object System.Windows.Forms.Panel
    $headerPanel.Location = New-Object System.Drawing.Point(0, 0)
    $headerPanel.Size = New-Object System.Drawing.Size(800, 80)
    $headerPanel.BackColor = $global:Theme.Primary
    $setupForm.Controls.Add($headerPanel)
    
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Location = New-Object System.Drawing.Point(30, 15)
    $titleLabel.Size = New-Object System.Drawing.Size(700, 30)
    $titleLabel.Text = "🚀 Welcome to ServiceManager Setup"
    $titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
    $titleLabel.ForeColor = [System.Drawing.Color]::White
    $headerPanel.Controls.Add($titleLabel)
    
    $subtitleLabel = New-Object System.Windows.Forms.Label
    $subtitleLabel.Location = New-Object System.Drawing.Point(30, 50)
    $subtitleLabel.Size = New-Object System.Drawing.Size(700, 20)
    $subtitleLabel.Text = "⚡ Configure your initial scripts and applications ⚡"
    $subtitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $subtitleLabel.ForeColor = [System.Drawing.Color]::LightGray
    $headerPanel.Controls.Add($subtitleLabel)
    
    # Welcome Message
    $welcomeLabel = New-Object System.Windows.Forms.Label
    $welcomeLabel.Location = New-Object System.Drawing.Point(30, 100)
    $welcomeLabel.Size = New-Object System.Drawing.Size(740, 60)
    $welcomeLabel.Text = @"
Welcome to ServiceManager! This setup wizard will help you configure your initial scripts and applications.

You can add PowerShell scripts (.ps1) and applications (.exe) that you want to manage. If you don't have any scripts ready, that's okay - you can skip this step and add them later through the main application.
"@
    $welcomeLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11)
    $welcomeLabel.ForeColor = $global:Theme.Text
    $setupForm.Controls.Add($welcomeLabel)
    
    # Services List
    $servicesLabel = New-Object System.Windows.Forms.Label
    $servicesLabel.Location = New-Object System.Drawing.Point(30, 170)
    $servicesLabel.Size = New-Object System.Drawing.Size(200, 25)
    $servicesLabel.Text = "📋 Configured Services:"
    $servicesLabel.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $servicesLabel.ForeColor = $global:Theme.Text
    $setupForm.Controls.Add($servicesLabel)
    
    $servicesListBox = New-Object System.Windows.Forms.ListBox
    $servicesListBox.Location = New-Object System.Drawing.Point(30, 200)
    $servicesListBox.Size = New-Object System.Drawing.Size(500, 200)
    $servicesListBox.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $servicesListBox.BackColor = $global:Theme.Surface
    $setupForm.Controls.Add($servicesListBox)
    
    # Buttons Panel
    $buttonPanel = New-Object System.Windows.Forms.Panel
    $buttonPanel.Location = New-Object System.Drawing.Point(550, 200)
    $buttonPanel.Size = New-Object System.Drawing.Size(220, 200)
    $buttonPanel.BackColor = $global:Theme.Light
    $setupForm.Controls.Add($buttonPanel)
    
    $addServiceButton = New-Object System.Windows.Forms.Button
    $addServiceButton.Location = New-Object System.Drawing.Point(10, 10)
    $addServiceButton.Size = New-Object System.Drawing.Size(200, 35)
    $addServiceButton.Text = "➕ Add Script/App"
    $addServiceButton.BackColor = $global:Theme.Secondary
    $addServiceButton.ForeColor = [System.Drawing.Color]::White
    $addServiceButton.FlatStyle = "Flat"
    $addServiceButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $addServiceButton.Add_Click({
        $newService = Show-AddServiceDialog
        if ($newService) {
            $global:SetupServices += $newService
            $servicesListBox.Items.Add("$($newService.icon) $($newService.name)")
        }
    })
    $buttonPanel.Controls.Add($addServiceButton)
    
    $removeServiceButton = New-Object System.Windows.Forms.Button
    $removeServiceButton.Location = New-Object System.Drawing.Point(10, 55)
    $removeServiceButton.Size = New-Object System.Drawing.Size(200, 35)
    $removeServiceButton.Text = "🗑️ Remove Selected"
    $removeServiceButton.BackColor = $global:Theme.Danger
    $removeServiceButton.ForeColor = [System.Drawing.Color]::White
    $removeServiceButton.FlatStyle = "Flat"
    $removeServiceButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $removeServiceButton.Add_Click({
        if ($servicesListBox.SelectedIndex -ge 0) {
            $global:SetupServices = $global:SetupServices | Where-Object { $_ -ne $global:SetupServices[$servicesListBox.SelectedIndex] }
            $servicesListBox.Items.RemoveAt($servicesListBox.SelectedIndex)
        }
    })
    $buttonPanel.Controls.Add($removeServiceButton)
    
    $skipButton = New-Object System.Windows.Forms.Button
    $skipButton.Location = New-Object System.Drawing.Point(10, 110)
    $skipButton.Size = New-Object System.Drawing.Size(200, 35)
    $skipButton.Text = "⏭️ Skip (Add Later)"
    $skipButton.BackColor = $global:Theme.TextMuted
    $skipButton.ForeColor = [System.Drawing.Color]::White
    $skipButton.FlatStyle = "Flat"
    $skipButton.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $skipButton.Add_Click({
        $global:SetupServices = @()
        $setupForm.DialogResult = "OK"
        $setupForm.Close()
    })
    $buttonPanel.Controls.Add($skipButton)
    
    # Bottom buttons
    $finishButton = New-Object System.Windows.Forms.Button
    $finishButton.Location = New-Object System.Drawing.Point(600, 520)
    $finishButton.Size = New-Object System.Drawing.Size(100, 35)
    $finishButton.Text = "✅ Finish Setup"
    $finishButton.BackColor = $global:Theme.Secondary
    $finishButton.ForeColor = [System.Drawing.Color]::White
    $finishButton.FlatStyle = "Flat"
    $finishButton.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
    $finishButton.DialogResult = "OK"
    $setupForm.Controls.Add($finishButton)
    
    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Location = New-Object System.Drawing.Point(710, 520)
    $cancelButton.Size = New-Object System.Drawing.Size(70, 35)
    $cancelButton.Text = "Cancel"
    $cancelButton.BackColor = $global:Theme.Danger
    $cancelButton.ForeColor = [System.Drawing.Color]::White
    $cancelButton.FlatStyle = "Flat"
    $cancelButton.DialogResult = "Cancel"
    $setupForm.Controls.Add($cancelButton)
    
    $setupForm.AcceptButton = $finishButton
    $setupForm.CancelButton = $cancelButton
    
    $result = $setupForm.ShowDialog()
    $setupForm.Dispose()
    
    return ($result -eq "OK")
}

function Show-CompletionDialog {
    $completionForm = New-Object System.Windows.Forms.Form
    $completionForm.Text = "🎉 Setup Complete!"
    $completionForm.Size = New-Object System.Drawing.Size(500, 300)
    $completionForm.StartPosition = "CenterScreen"
    $completionForm.FormBorderStyle = "FixedDialog"
    $completionForm.MaximizeBox = $false
    $completionForm.MinimizeBox = $false
    $completionForm.BackColor = $global:Theme.Light
    
    # Header Panel
    $headerPanel = New-Object System.Windows.Forms.Panel
    $headerPanel.Location = New-Object System.Drawing.Point(0, 0)
    $headerPanel.Size = New-Object System.Drawing.Size(500, 80)
    $headerPanel.BackColor = $global:Theme.Secondary
    $completionForm.Controls.Add($headerPanel)
    
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Location = New-Object System.Drawing.Point(30, 15)
    $titleLabel.Size = New-Object System.Drawing.Size(440, 30)
    $titleLabel.Text = "🎉 Setup Complete!"
    $titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
    $titleLabel.ForeColor = [System.Drawing.Color]::White
    $headerPanel.Controls.Add($titleLabel)
    
    $subtitleLabel = New-Object System.Windows.Forms.Label
    $subtitleLabel.Location = New-Object System.Drawing.Point(30, 50)
    $subtitleLabel.Size = New-Object System.Drawing.Size(440, 20)
    $subtitleLabel.Text = "✅ ServiceManager is now ready to use!"
    $subtitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $subtitleLabel.ForeColor = [System.Drawing.Color]::White
    $headerPanel.Controls.Add($subtitleLabel)
    
    # Message
    $messageLabel = New-Object System.Windows.Forms.Label
    $messageLabel.Location = New-Object System.Drawing.Point(30, 100)
    $messageLabel.Size = New-Object System.Drawing.Size(440, 80)
    $messageLabel.Text = @"
Your ServiceManager configuration has been created successfully!

✅ User configuration saved to: user_config\
✅ $($global:SetupServices.Count) services configured
✅ Ready for immediate use

Click 'Start' to launch ServiceManager now, or 'Close' to exit setup.
"@
    $messageLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11)
    $messageLabel.ForeColor = $global:Theme.Text
    $completionForm.Controls.Add($messageLabel)
    
    # Buttons
    $startButton = New-Object System.Windows.Forms.Button
    $startButton.Location = New-Object System.Drawing.Point(250, 200)
    $startButton.Size = New-Object System.Drawing.Size(100, 40)
    $startButton.Text = "🚀 Start"
    $startButton.BackColor = $global:Theme.Primary
    $startButton.ForeColor = [System.Drawing.Color]::White
    $startButton.FlatStyle = "Flat"
    $startButton.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $startButton.DialogResult = "Yes"
    $completionForm.Controls.Add($startButton)
    
    $closeButton = New-Object System.Windows.Forms.Button
    $closeButton.Location = New-Object System.Drawing.Point(360, 200)
    $closeButton.Size = New-Object System.Drawing.Size(100, 40)
    $closeButton.Text = "Close"
    $closeButton.BackColor = $global:Theme.TextMuted
    $closeButton.ForeColor = [System.Drawing.Color]::White
    $closeButton.FlatStyle = "Flat"
    $closeButton.Font = New-Object System.Drawing.Font("Segoe UI", 12)
    $closeButton.DialogResult = "No"
    $completionForm.Controls.Add($closeButton)
    
    $completionForm.AcceptButton = $startButton
    $completionForm.CancelButton = $closeButton
    
    $result = $completionForm.ShowDialog()
    $completionForm.Dispose()
    
    return ($result -eq "Yes")
}

function Create-UserConfig {
    try {
        # Create user_config directory if it doesn't exist
        if (-not (Test-Path $global:UserConfigPath)) {
            New-Item -Path $global:UserConfigPath -ItemType Directory -Force | Out-Null
            Write-Host "✅ Created user_config directory: $global:UserConfigPath" -ForegroundColor Green
        }
        
        # Load initial configurations with proper error handling
        try {
            $initScriptsPath = Join-Path $serviceManagerPath "init.scripts_storage.json"
            $initSettingsPath = Join-Path $serviceManagerPath "init.app_settings.json"
            
            if (-not (Test-Path $initScriptsPath) -or -not (Test-Path $initSettingsPath)) {
                Write-Host "❌ Initial configuration files not found" -ForegroundColor Red
                [System.Windows.Forms.MessageBox]::Show(
                    "Initial configuration files are missing.`n`nPlease ensure init.scripts_storage.json and init.app_settings.json exist in the ServiceManager folder.",
                    "Configuration Error",
                    "OK",
                    "Error"
                )
                return $false
            }
            
            $scriptsConfig = Get-Content $initScriptsPath -Raw -ErrorAction Stop | ConvertFrom-Json
            $appSettings = Get-Content $initSettingsPath -Raw -ErrorAction Stop | ConvertFrom-Json
        }
        catch {
            Write-Host "❌ Failed to load initial configuration files: $($_.Exception.Message)" -ForegroundColor Red
            [System.Windows.Forms.MessageBox]::Show(
                "Failed to load initial configuration files. Please ensure the files exist and are valid JSON.",
                "Configuration Error",
                "OK",
                "Error"
            )
            return $false
        }
        
        # Create new configuration objects with proper structure
        $newScriptsConfig = @{
            version = $scriptsConfig.version
            lastModified = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
            scripts = @()
            categories = $scriptsConfig.categories
            statistics = $scriptsConfig.statistics
        }

        # Add setup services to configuration if any were added
        if ($global:SetupServices.Count -gt 0) {
            $newScriptsConfig.scripts = @($global:SetupServices)
            Write-Host "✅ Added $($global:SetupServices.Count) services to configuration" -ForegroundColor Green
        }
        
        # Create user_config files with proper error handling
        $scriptsConfigPath = Join-Path $global:UserConfigPath "scripts_storage.json"
        $appSettingsPath = Join-Path $global:UserConfigPath "app_settings.json"
        
        try {
            # Save user configurations with proper formatting
            $newScriptsConfig | ConvertTo-Json -Depth 10 | Set-Content $scriptsConfigPath -Encoding UTF8
            $appSettings | ConvertTo-Json -Depth 10 | Set-Content $appSettingsPath -Encoding UTF8
            
            Write-Host "✅ Configuration files created in: $global:UserConfigPath" -ForegroundColor Green
        }
        catch {
            Write-Host "❌ Failed to save configuration files: $($_.Exception.Message)" -ForegroundColor Red
            [System.Windows.Forms.MessageBox]::Show(
                "Failed to save configuration files to $global:UserConfigPath`n`nError: $($_.Exception.Message)",
                "Configuration Error",
                "OK",
                "Error"
            )
            return $false
        }
        
        return $true
        
    } catch {
        Write-Host "❌ Failed to create user configuration: $($_.Exception.Message)" -ForegroundColor Red
        [System.Windows.Forms.MessageBox]::Show(
            "Failed to create user configuration in $global:UserConfigPath`n`nError: $($_.Exception.Message)",
            "Setup Error",
            "OK",
            "Error"
        )
        return $false
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🚀 MAIN SETUP EXECUTION
# ═══════════════════════════════════════════════════════════════════════════════

if (-not $IntegratedSetup) {
    Write-Host "🚀 ServiceManager Setup - Standalone Mode" -ForegroundColor Cyan
}

# Check if user_config already exists
if (Test-Path $global:UserConfigPath) {
    if (-not $IntegratedSetup) {
        [System.Windows.Forms.MessageBox]::Show("ServiceManager is already configured!`n`nUser configuration found at: $global:UserConfigPath`n`nRun ServiceManager.ps1 to start the application.", "Already Configured", "OK", "Information")
    }
    return $false
}

Write-Host "📁 User configuration not found - starting setup wizard..." -ForegroundColor Yellow

# Show setup wizard
$setupCompleted = Show-SetupWizard

if ($setupCompleted) {
    Write-Host "✅ Setup wizard completed" -ForegroundColor Green
    
    # Create user configuration
    if (Create-UserConfig) {
        Write-Host "🎉 Setup completed successfully!" -ForegroundColor Green
        
        if (-not $IntegratedSetup) {
            # Show completion dialog
            $startApp = Show-CompletionDialog
            
            if ($startApp) {
                Write-Host "🚀 Starting ServiceManager..." -ForegroundColor Green
                Start-Process -FilePath "powershell" -ArgumentList "-ExecutionPolicy Bypass -File `".\ServiceManager.ps1`""
            }
        }
        
        return $true
    }
} else {
    Write-Host "❌ Setup was cancelled" -ForegroundColor Red
    if (-not $IntegratedSetup) {
        [System.Windows.Forms.MessageBox]::Show("Setup was cancelled.`n`nYou can run this setup again anytime.", "Setup Cancelled", "OK", "Information")
    }
}

return $false