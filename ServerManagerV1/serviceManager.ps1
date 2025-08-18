# AI Service Manager - Advanced with Script Management & Log Tracking
# Dynamic script management, log tracking, and improved Windows Terminal integration

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Initialize Windows Forms FIRST
[System.Windows.Forms.Application]::EnableVisualStyles()
[System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)

Write-Host "[*] AI Service Manager Advanced Starting..." -ForegroundColor Green

# Verify directory
if (!(Test-Path ".\Zoe")) {
    Write-Host "[ERROR] Please run from aiMain directory" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Configuration file for custom scripts
$global:ConfigFile = ".\ai-service-scripts-config.json"
$global:LogEntries = [System.Collections.ArrayList]::new()
$global:ActiveTabs = @{}  # Track active tabs for cleanup

# Check if Windows Terminal is available
$global:HasWindowsTerminal = $false
try {
    $null = Get-Command wt -ErrorAction Stop
    $global:HasWindowsTerminal = $true
    Write-Host "[OK] Windows Terminal detected" -ForegroundColor Green
} catch {
    Write-Host "[INFO] Windows Terminal not found" -ForegroundColor Gray
}

# Load or create script configuration
function Load-ScriptConfig {
    if (Test-Path $global:ConfigFile) {
        try {
            $config = Get-Content $global:ConfigFile -Raw | ConvertFrom-Json
            return $config
        } catch {
            Add-LogEntry "[WARN] Config file corrupted, creating new one"
            return Create-DefaultConfig
        }
    } else {
        return Create-DefaultConfig
    }
}

function Create-DefaultConfig {
    $defaultConfig = @{
        version = "1.0"
        scripts = @(
            @{
                name = "[*] Start MCP Server"
                type = "mcp-start"
                color = "LightGreen"
                directory = "Zoe\DockerMCP"
                scriptFile = "MCP-Startup.ps1"
                isBuiltIn = $true
            },
            @{
                name = "[X] Stop MCP Server"
                type = "mcp-stop"
                color = "LightCoral"
                directory = "Zoe\DockerMCP"
                scriptFile = "MCP-Kill.ps1"
                isBuiltIn = $true
            },
            @{
                name = "[*] Start n8n"
                type = "n8n-start"
                color = "LightBlue"
                directory = "Zoe\Dockern8n"
                scriptFile = "n8nStartup.ps1"
                isBuiltIn = $true
            },
            @{
                name = "[X] Stop n8n"
                type = "n8n-stop"
                color = "LightCoral"
                directory = "Zoe\Dockern8n"
                scriptFile = "n8nKill.ps1"
                isBuiltIn = $true
            }
        )
    }
    Save-ScriptConfig $defaultConfig
    return $defaultConfig
}

function Save-ScriptConfig {
    param($config)
    try {
        $config | ConvertTo-Json -Depth 10 | Set-Content $global:ConfigFile
        return $true
    } catch {
        Add-LogEntry "[ERROR] Failed to save configuration: $($_.Exception.Message)"
        return $false
    }
}

function Add-LogEntry {
    param($message)
    $timestamp = Get-Date -Format "HH:mm:ss"
    $logMessage = "[$timestamp] $message"
    [void]$global:LogEntries.Add($logMessage)
    
    # Update log display if it exists
    if ($global:LogTextBox) {
        $global:LogTextBox.AppendText("$logMessage`r`n")
        $global:LogTextBox.SelectionStart = $global:LogTextBox.Text.Length
        $global:LogTextBox.ScrollToCaret()
    }
    
    # Also write to console
    Write-Host $logMessage -ForegroundColor Gray
}

function Validate-ScriptFile {
    param($scriptPath, $scriptName)
    
    # Check if name ends with .ps1
    if (-not $scriptName.EndsWith('.ps1')) {
        return "Script name '$scriptName' isn't a valid PowerShell Script! (must end with .ps1)"
    }
    
    # Check if file exists
    if (-not (Test-Path $scriptPath)) {
        return "Script file not found at: $scriptPath"
    }
    
    # Check if it's actually a .ps1 file
    $extension = [System.IO.Path]::GetExtension($scriptPath)
    if ($extension -ne '.ps1') {
        return "File '$scriptPath' isn't a valid PowerShell Script! (extension: $extension)"
    }
    
    return $null  # No error
}

function Show-AddScriptDialog {
    param($config)
    
    $addForm = New-Object System.Windows.Forms.Form
    $addForm.Text = "Add Custom Script"
    $addForm.Size = New-Object System.Drawing.Size(500, 400)
    $addForm.StartPosition = "CenterParent"
    $addForm.FormBorderStyle = "FixedDialog"
    $addForm.MaximizeBox = $false
    $addForm.MinimizeBox = $false
    
    # Script Name
    $nameLabel = New-Object System.Windows.Forms.Label
    $nameLabel.Location = New-Object System.Drawing.Point(10, 20)
    $nameLabel.Size = New-Object System.Drawing.Size(100, 20)
    $nameLabel.Text = "Display Name:"
    $addForm.Controls.Add($nameLabel)
    
    $nameTextBox = New-Object System.Windows.Forms.TextBox
    $nameTextBox.Location = New-Object System.Drawing.Point(120, 18)
    $nameTextBox.Size = New-Object System.Drawing.Size(350, 20)
    $nameTextBox.Text = "[*] My Custom Script"
    $addForm.Controls.Add($nameTextBox)
    
    $nameDesc = New-Object System.Windows.Forms.Label
    $nameDesc.Location = New-Object System.Drawing.Point(120, 40)
    $nameDesc.Size = New-Object System.Drawing.Size(350, 15)
    $nameDesc.Text = "The name shown on the button (e.g., '[*] Start My Service')"
    $nameDesc.ForeColor = [System.Drawing.Color]::DarkGray
    $nameDesc.Font = New-Object System.Drawing.Font("Segoe UI", 8)
    $addForm.Controls.Add($nameDesc)
    
    # Directory
    $dirLabel = New-Object System.Windows.Forms.Label
    $dirLabel.Location = New-Object System.Drawing.Point(10, 70)
    $dirLabel.Size = New-Object System.Drawing.Size(100, 20)
    $dirLabel.Text = "Directory Path:"
    $addForm.Controls.Add($dirLabel)
    
    $dirTextBox = New-Object System.Windows.Forms.TextBox
    $dirTextBox.Location = New-Object System.Drawing.Point(120, 68)
    $dirTextBox.Size = New-Object System.Drawing.Size(300, 20)
    $addForm.Controls.Add($dirTextBox)
    
    $browseButton = New-Object System.Windows.Forms.Button
    $browseButton.Location = New-Object System.Drawing.Point(430, 67)
    $browseButton.Size = New-Object System.Drawing.Size(40, 22)
    $browseButton.Text = "..."
    $browseButton.Add_Click({
        $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $folderDialog.SelectedPath = (Get-Location).Path
        if ($folderDialog.ShowDialog() -eq "OK") {
            $dirTextBox.Text = $folderDialog.SelectedPath
        }
    })
    $addForm.Controls.Add($browseButton)
    
    $dirDesc = New-Object System.Windows.Forms.Label
    $dirDesc.Location = New-Object System.Drawing.Point(120, 90)
    $dirDesc.Size = New-Object System.Drawing.Size(350, 15)
    $dirDesc.Text = "Full path to directory containing the script (e.g., C:\Users\Kaden\Desktop\aiMain\MyScripts)"
    $dirDesc.ForeColor = [System.Drawing.Color]::DarkGray
    $dirDesc.Font = New-Object System.Drawing.Font("Segoe UI", 8)
    $addForm.Controls.Add($dirDesc)
    
    # Script File
    $scriptLabel = New-Object System.Windows.Forms.Label
    $scriptLabel.Location = New-Object System.Drawing.Point(10, 120)
    $scriptLabel.Size = New-Object System.Drawing.Size(100, 20)
    $scriptLabel.Text = "Script Filename:"
    $addForm.Controls.Add($scriptLabel)
    
    $scriptTextBox = New-Object System.Windows.Forms.TextBox
    $scriptTextBox.Location = New-Object System.Drawing.Point(120, 118)
    $scriptTextBox.Size = New-Object System.Drawing.Size(350, 20)
    $scriptTextBox.Text = "MyScript.ps1"
    $addForm.Controls.Add($scriptTextBox)
    
    $scriptDesc = New-Object System.Windows.Forms.Label
    $scriptDesc.Location = New-Object System.Drawing.Point(120, 140)
    $scriptDesc.Size = New-Object System.Drawing.Size(350, 15)
    $scriptDesc.Text = "Filename with .ps1 extension (e.g., 'MyStartup.ps1')"
    $scriptDesc.ForeColor = [System.Drawing.Color]::DarkGray
    $scriptDesc.Font = New-Object System.Drawing.Font("Segoe UI", 8)
    $addForm.Controls.Add($scriptDesc)
    
    # Script Type
    $typeLabel = New-Object System.Windows.Forms.Label
    $typeLabel.Location = New-Object System.Drawing.Point(10, 170)
    $typeLabel.Size = New-Object System.Drawing.Size(100, 20)
    $typeLabel.Text = "Script Type:"
    $addForm.Controls.Add($typeLabel)
    
    $typeComboBox = New-Object System.Windows.Forms.ComboBox
    $typeComboBox.Location = New-Object System.Drawing.Point(120, 168)
    $typeComboBox.Size = New-Object System.Drawing.Size(150, 20)
    $typeComboBox.DropDownStyle = "DropDownList"
    $typeComboBox.Items.AddRange(@("startup", "shutdown", "utility"))
    $typeComboBox.SelectedIndex = 0
    $addForm.Controls.Add($typeComboBox)
    
    # Button Color
    $colorLabel = New-Object System.Windows.Forms.Label
    $colorLabel.Location = New-Object System.Drawing.Point(280, 170)
    $colorLabel.Size = New-Object System.Drawing.Size(80, 20)
    $colorLabel.Text = "Button Color:"
    $addForm.Controls.Add($colorLabel)
    
    $colorComboBox = New-Object System.Windows.Forms.ComboBox
    $colorComboBox.Location = New-Object System.Drawing.Point(370, 168)
    $colorComboBox.Size = New-Object System.Drawing.Size(100, 20)
    $colorComboBox.DropDownStyle = "DropDownList"
    $colorComboBox.Items.AddRange(@("LightGreen", "LightCoral", "LightBlue", "LightYellow", "LightPink", "LightGray"))
    $colorComboBox.SelectedIndex = 0
    $addForm.Controls.Add($colorComboBox)
    
    # Test button
    $testButton = New-Object System.Windows.Forms.Button
    $testButton.Location = New-Object System.Drawing.Point(120, 200)
    $testButton.Size = New-Object System.Drawing.Size(100, 30)
    $testButton.Text = "Test Path"
    $testButton.BackColor = [System.Drawing.Color]::LightYellow
    $testButton.Add_Click({
        $fullPath = Join-Path $dirTextBox.Text $scriptTextBox.Text
        $error = Validate-ScriptFile $fullPath $scriptTextBox.Text
        if ($error) {
            [System.Windows.Forms.MessageBox]::Show($error, "Validation Error", "OK", "Error")
        } else {
            [System.Windows.Forms.MessageBox]::Show("✅ Script validation successful!`n`nPath: $fullPath", "Validation Success", "OK", "Information")
        }
    })
    $addForm.Controls.Add($testButton)
    
    # Help text
    $helpLabel = New-Object System.Windows.Forms.Label
    $helpLabel.Location = New-Object System.Drawing.Point(10, 250)
    $helpLabel.Size = New-Object System.Drawing.Size(460, 60)
    $helpLabel.Text = @"
Requirements for compatible scripts:
• Must be a .ps1 PowerShell script
• Should include these lines at the top:
  `$scriptPath = Split-Path -Parent `$MyInvocation.MyCommand.Path
  Set-Location `$scriptPath
• Use Write-Host for status messages
• Test your script manually first
"@
    $helpLabel.ForeColor = [System.Drawing.Color]::DarkBlue
    $helpLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $addForm.Controls.Add($helpLabel)
    
    # Buttons
    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Location = New-Object System.Drawing.Point(300, 330)
    $okButton.Size = New-Object System.Drawing.Size(75, 23)
    $okButton.Text = "Add Script"
    $okButton.DialogResult = "OK"
    $addForm.Controls.Add($okButton)
    
    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Location = New-Object System.Drawing.Point(395, 330)
    $cancelButton.Size = New-Object System.Drawing.Size(75, 23)
    $cancelButton.Text = "Cancel"
    $cancelButton.DialogResult = "Cancel"
    $addForm.Controls.Add($cancelButton)
    
    $addForm.AcceptButton = $okButton
    $addForm.CancelButton = $cancelButton
    
    $result = $addForm.ShowDialog()
    
    if ($result -eq "OK") {
        $fullPath = Join-Path $dirTextBox.Text $scriptTextBox.Text
        $error = Validate-ScriptFile $fullPath $scriptTextBox.Text
        
        if ($error) {
            [System.Windows.Forms.MessageBox]::Show($error, "Validation Error", "OK", "Error")
            $addForm.Dispose()
            return $false
        }
        
        # Convert absolute path to relative if possible
        $relativePath = try {
            $currentDir = Get-Location
            if ($dirTextBox.Text.StartsWith($currentDir.Path)) {
                $dirTextBox.Text.Replace($currentDir.Path, ".").Replace("\", "\")
            } else {
                $dirTextBox.Text
            }
        } catch {
            $dirTextBox.Text
        }
        
        $newScript = @{
            name = $nameTextBox.Text
            type = "custom-$($typeComboBox.SelectedItem)"
            color = $colorComboBox.SelectedItem
            directory = $relativePath
            scriptFile = $scriptTextBox.Text
            isBuiltIn = $false
        }
        
        # Add to config
        $config.scripts = @($config.scripts) + $newScript
        
        if (Save-ScriptConfig $config) {
            Add-LogEntry "[OK] Added script: $($newScript.name)"
            [System.Windows.Forms.MessageBox]::Show("✅ Script added successfully!`n`nRestart the AI Service Manager to see the new button.", 
                "Script Added", "OK", "Information")
            $addForm.Dispose()
            return $true
        } else {
            [System.Windows.Forms.MessageBox]::Show("Failed to save script configuration.", "Save Error", "OK", "Error")
        }
    }
    
    $addForm.Dispose()
    return $false
}

function Show-RemoveScriptDialog {
    param($config)
    
    $customScripts = $config.scripts | Where-Object { -not $_.isBuiltIn }
    if ($customScripts.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("No custom scripts to remove.`n(Built-in scripts cannot be removed)", 
            "No Custom Scripts", "OK", "Information")
        return $false
    }
    
    $removeForm = New-Object System.Windows.Forms.Form
    $removeForm.Text = "Remove Custom Script"
    $removeForm.Size = New-Object System.Drawing.Size(450, 300)
    $removeForm.StartPosition = "CenterParent"
    $removeForm.FormBorderStyle = "FixedDialog"
    $removeForm.MaximizeBox = $false
    $removeForm.MinimizeBox = $false
    
    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(10, 20)
    $label.Size = New-Object System.Drawing.Size(420, 20)
    $label.Text = "Select script to remove:"
    $removeForm.Controls.Add($label)
    
    $listBox = New-Object System.Windows.Forms.ListBox
    $listBox.Location = New-Object System.Drawing.Point(10, 50)
    $listBox.Size = New-Object System.Drawing.Size(420, 150)
    
    foreach ($script in $customScripts) {
        $displayText = "$($script.name) - $($script.directory)\$($script.scriptFile)"
        $listBox.Items.Add($displayText)
    }
    
    $removeForm.Controls.Add($listBox)
    
    $removeButton = New-Object System.Windows.Forms.Button
    $removeButton.Location = New-Object System.Drawing.Point(270, 220)
    $removeButton.Size = New-Object System.Drawing.Size(75, 23)
    $removeButton.Text = "Remove"
    $removeButton.DialogResult = "OK"
    $removeForm.Controls.Add($removeButton)
    
    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Location = New-Object System.Drawing.Point(355, 220)
    $cancelButton.Size = New-Object System.Drawing.Size(75, 23)
    $cancelButton.Text = "Cancel"
    $cancelButton.DialogResult = "Cancel"
    $removeForm.Controls.Add($cancelButton)
    
    $result = $removeForm.ShowDialog()
    
    if ($result -eq "OK" -and $listBox.SelectedIndex -ge 0) {
        $selectedScript = $customScripts[$listBox.SelectedIndex]
        $confirm = [System.Windows.Forms.MessageBox]::Show(
            "Remove script '$($selectedScript.name)'?`n`nThis cannot be undone.", 
            "Confirm Removal", "YesNo", "Question")
        
        if ($confirm -eq "Yes") {
            $config.scripts = $config.scripts | Where-Object { 
                -not (($_.name -eq $selectedScript.name) -and ($_.directory -eq $selectedScript.directory) -and ($_.scriptFile -eq $selectedScript.scriptFile))
            }
            
            if (Save-ScriptConfig $config) {
                Add-LogEntry "[OK] Removed script: $($selectedScript.name)"
                [System.Windows.Forms.MessageBox]::Show("✅ Script removed successfully!`n`nRestart the AI Service Manager to update the interface.", 
                    "Script Removed", "OK", "Information")
                $removeForm.Dispose()
                return $true
            }
        }
    }
    
    $removeForm.Dispose()
    return $false
}

# Enhanced service execution with log tracking
function Execute-ServiceScript {
    param($service, $showPopup = $true)
    
    $scriptPath = Join-Path $service.directory $service.scriptFile
    $fullPath = if ([System.IO.Path]::IsPathRooted($service.directory)) {
        $scriptPath
    } else {
        Join-Path (Get-Location) $scriptPath
    }
    
    Add-LogEntry "[INFO] Executing: $($service.name)"
    Add-LogEntry "[INFO] Script: $fullPath"
    
    if (-not (Test-Path $fullPath)) {
        $errorMsg = "Script not found: $fullPath"
        Add-LogEntry "[ERROR] $errorMsg"
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
                "-Command", "Set-Location '$($service.directory)'; Write-Host '[TAB] $($service.name)' -ForegroundColor Cyan; & '.\$($service.scriptFile)'"
            )
        } else {
            # Individual service - separate window
            Start-Process -FilePath "powershell" -ArgumentList @(
                "-NoExit",
                "-Command",
                "Set-Location '$($service.directory)'; Write-Host '[GUI] $($service.name)' -ForegroundColor Green; & '.\$($service.scriptFile)'"
            ) -WorkingDirectory $service.directory
        }
        
        Add-LogEntry "[OK] Started: $($service.name)"
        if ($showPopup) {
            [System.Windows.Forms.MessageBox]::Show("$($service.name) initiated successfully", "Service Started", "OK", "Information")
        }
        return $true
    } catch {
        $errorMsg = "Failed to execute $($service.name): $($_.Exception.Message)"
        Add-LogEntry "[ERROR] $errorMsg"
        if ($showPopup) {
            [System.Windows.Forms.MessageBox]::Show($errorMsg, "Execution Error", "OK", "Error")
        }
        return $false
    }
}

# Built-in stop actions (port-based)
function Stop-MCPServer {
    param($showPopup = $true)
    
    Add-LogEntry "[INFO] Stopping MCP Server (port 4000)..."
    $portProcesses = netstat -ano | findstr ":4000"
    $killedCount = 0
    
    if ($portProcesses) {
        $processIds = $portProcesses | ForEach-Object { ($_ -split '\s+')[-1] } | Select-Object -Unique
        foreach ($processId in $processIds) {
            if ($processId -and $processId -ne "0") {
                try {
                    $process = Get-Process -Id $processId -ErrorAction SilentlyContinue
                    if ($process) {
                        taskkill /PID $processId /F 2>$null
                        if ($LASTEXITCODE -eq 0) {
                            Add-LogEntry "[OK] Killed process $($process.ProcessName) (PID: $processId)"
                            $killedCount++
                        }
                    }
                } catch {
                    Add-LogEntry "[WARN] Could not kill PID $processId"
                }
            }
        }
        
        # Close corresponding tab if it exists
        if ($global:ActiveTabs.ContainsKey("[*] Start MCP Server")) {
            Add-LogEntry "[INFO] Attempting to close MCP tab..."
        }
        
        if ($showPopup) {
            [System.Windows.Forms.MessageBox]::Show("MCP Server stopped ($killedCount processes killed)", "Success", "OK", "Information")
        }
        return $killedCount -gt 0
    } else {
        Add-LogEntry "[INFO] No MCP processes found on port 4000"
        if ($showPopup) {
            [System.Windows.Forms.MessageBox]::Show("No MCP processes found on port 4000", "Info", "OK", "Information")
        }
        return $false
    }
}

function Stop-N8nServer {
    param($showPopup = $true)
    
    Add-LogEntry "[INFO] Stopping n8n environment..."
    $killedCount = 0
    
    # Stop Docker containers
    try {
        $n8nDir = Join-Path (Get-Location) "Zoe\Dockern8n"
        Push-Location $n8nDir
        $result = docker-compose down 2>&1
        Pop-Location
        Add-LogEntry "[OK] Docker compose down completed"
        $killedCount++
    } catch {
        Add-LogEntry "[WARN] Could not stop containers: $_"
    }
    
    # Kill processes on port 5678
    $portProcesses = netstat -ano | findstr ":5678"
    if ($portProcesses) {
        $processIds = $portProcesses | ForEach-Object { ($_ -split '\s+')[-1] } | Select-Object -Unique
        foreach ($processId in $processIds) {
            if ($processId -and $processId -ne "0") {
                try {
                    taskkill /PID $processId /F 2>$null
                    if ($LASTEXITCODE -eq 0) {
                        Add-LogEntry "[OK] Killed process PID $processId"
                        $killedCount++
                    }
                } catch {
                    Add-LogEntry "[WARN] Could not kill PID $processId"
                }
            }
        }
    }
    
    # Kill ngrok
    try {
        $ngrokProcesses = Get-Process -Name "ngrok" -ErrorAction SilentlyContinue
        if ($ngrokProcesses) {
            $ngrokProcesses | Stop-Process -Force
            Add-LogEntry "[OK] Stopped ngrok processes"
            $killedCount++
        }
    } catch {
        Add-LogEntry "[INFO] No ngrok processes found"
    }
    
    # Close corresponding tab if it exists
    if ($global:ActiveTabs.ContainsKey("[*] Start n8n")) {
        Add-LogEntry "[INFO] Attempting to close n8n tab..."
    }
    
    if ($showPopup) {
        [System.Windows.Forms.MessageBox]::Show("n8n environment stopped ($killedCount items)", "Success", "OK", "Information")
    }
    return $killedCount -gt 0
}

# Enhanced Start All function
function Start-AllServices {
    param($services)
    
    Add-LogEntry "[*] Starting all services..."
    $results = @()
    
    $startupServices = $services | Where-Object { $_.type -like "*start*" }
    
    foreach ($service in $startupServices) {
        $success = Execute-ServiceScript $service $false
        if ($success) {
            $results += "[OK] $($service.name)"
        } else {
            $results += "[ERROR] $($service.name)"
        }
        Start-Sleep 1
    }
    
    $message = "Start All Results:`n`n" + ($results -join "`n")
    [System.Windows.Forms.MessageBox]::Show($message, "Start All Complete", "OK", "Information")
    Add-LogEntry "[*] Start All completed"
}

# Enhanced Stop All function
function Stop-AllServices {
    param($services)
    
    Add-LogEntry "[X] Stopping all services..."
    $results = @()
    
    # Handle built-in stop services
    $builtInStops = $services | Where-Object { $_.isBuiltIn -and $_.type -like "*stop*" }
    foreach ($service in $builtInStops) {
        $success = $false
        if ($service.type -eq "mcp-stop") {
            $success = Stop-MCPServer $false
        } elseif ($service.type -eq "n8n-stop") {
            $success = Stop-N8nServer $false
        }
        
        if ($success) {
            $results += "[OK] $($service.name)"
        } else {
            $results += "[INFO] $($service.name) (no processes found)"
        }
        Start-Sleep 1
    }
    
    # Handle custom stop services (run their scripts)
    $customStops = $services | Where-Object { -not $_.isBuiltIn -and $_.type -like "*stop*" }
    foreach ($service in $customStops) {
        $success = Execute-ServiceScript $service $false
        if ($success) {
            $results += "[OK] $($service.name)"
        } else {
            $results += "[ERROR] $($service.name)"
        }
        Start-Sleep 1
    }
    
    $message = "Stop All Results:`n`n" + ($results -join "`n")
    [System.Windows.Forms.MessageBox]::Show($message, "Stop All Complete", "OK", "Information")
    Add-LogEntry "[X] Stop All completed"
}

# Load configuration
$config = Load-ScriptConfig
Add-LogEntry "[OK] Loaded configuration with $($config.scripts.Count) scripts"

# Create main form (resizable!)
$form = New-Object System.Windows.Forms.Form
$form.Text = "[*] AI Service Manager Advanced"
$form.Size = New-Object System.Drawing.Size(700, 600)  # Larger for logs
$form.MinimumSize = New-Object System.Drawing.Size(600, 500)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::FromArgb(240, 248, 255)

# Title
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Location = New-Object System.Drawing.Point(20, 20)
$titleLabel.Size = New-Object System.Drawing.Size(660, 40)
$titleLabel.Text = "[*] AI Service Control Center - Advanced"
$titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$titleLabel.ForeColor = [System.Drawing.Color]::DarkBlue
$titleLabel.TextAlign = "MiddleCenter"
$titleLabel.Anchor = "Top,Left,Right"
$form.Controls.Add($titleLabel)

# Script management buttons
$scriptPanel = New-Object System.Windows.Forms.Panel
$scriptPanel.Location = New-Object System.Drawing.Point(20, 70)
$scriptPanel.Size = New-Object System.Drawing.Size(660, 40)
$scriptPanel.BackColor = [System.Drawing.Color]::FromArgb(250, 250, 250)
$scriptPanel.BorderStyle = "FixedSingle"
$scriptPanel.Anchor = "Top,Left,Right"
$form.Controls.Add($scriptPanel)

$addScriptButton = New-Object System.Windows.Forms.Button
$addScriptButton.Location = New-Object System.Drawing.Point(10, 8)
$addScriptButton.Size = New-Object System.Drawing.Size(100, 25)
$addScriptButton.Text = "[+] Add Script"
$addScriptButton.BackColor = [System.Drawing.Color]::LightGreen
$addScriptButton.Add_Click({
    if (Show-AddScriptDialog $config) {
        Add-LogEntry "[INFO] Script added - restart to see changes"
    }
})
$scriptPanel.Controls.Add($addScriptButton)

$removeScriptButton = New-Object System.Windows.Forms.Button
$removeScriptButton.Location = New-Object System.Drawing.Point(120, 8)
$removeScriptButton.Size = New-Object System.Drawing.Size(110, 25)
$removeScriptButton.Text = "[-] Remove Script"
$removeScriptButton.BackColor = [System.Drawing.Color]::LightCoral
$removeScriptButton.Add_Click({
    if (Show-RemoveScriptDialog $config) {
        Add-LogEntry "[INFO] Script removed - restart to see changes"
    }
})
$scriptPanel.Controls.Add($removeScriptButton)

$restartButton = New-Object System.Windows.Forms.Button
$restartButton.Location = New-Object System.Drawing.Point(240, 8)
$restartButton.Size = New-Object System.Drawing.Size(90, 25)
$restartButton.Text = "[R] Restart GUI"
$restartButton.BackColor = [System.Drawing.Color]::LightYellow
$restartButton.Add_Click({
    $result = [System.Windows.Forms.MessageBox]::Show("Restart the AI Service Manager to reload scripts?", 
        "Restart Manager", "YesNo", "Question")
    if ($result -eq "Yes") {
        $form.Close()
        Start-Process -FilePath "powershell" -ArgumentList "-ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`""
    }
})
$scriptPanel.Controls.Add($restartButton)

# Services panel (scrollable)
$servicesPanel = New-Object System.Windows.Forms.Panel
$servicesPanel.Location = New-Object System.Drawing.Point(20, 120)
$servicesPanel.Size = New-Object System.Drawing.Size(660, 200)
$servicesPanel.BorderStyle = "FixedSingle"
$servicesPanel.BackColor = [System.Drawing.Color]::White
$servicesPanel.AutoScroll = $true
$servicesPanel.Anchor = "Top,Left,Right"
$form.Controls.Add($servicesPanel)

# Create service buttons dynamically
$y = 10
foreach ($service in $config.scripts) {
    $button = New-Object System.Windows.Forms.Button
    $button.Location = New-Object System.Drawing.Point(10, $y)
    $button.Size = New-Object System.Drawing.Size(620, 35)
    $button.Text = $service.name
    $button.BackColor = [System.Drawing.Color]::$($service.color)
    $button.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $button.FlatStyle = "Flat"
    $button.Tag = $service
    $button.Anchor = "Top,Left,Right"
    
    # Add click event
    $button.Add_Click({
        $svc = $this.Tag
        
        if ($svc.isBuiltIn -and $svc.type -eq "mcp-stop") {
            Stop-MCPServer $true
        } elseif ($svc.isBuiltIn -and $svc.type -eq "n8n-stop") {
            Stop-N8nServer $true
        } else {
            Execute-ServiceScript $svc $true
        }
    })
    
    $servicesPanel.Controls.Add($button)
    $y += 40
}

# Control panel
$controlPanel = New-Object System.Windows.Forms.Panel
$controlPanel.Location = New-Object System.Drawing.Point(20, 330)
$controlPanel.Size = New-Object System.Drawing.Size(660, 50)
$controlPanel.BackColor = [System.Drawing.Color]::FromArgb(230, 230, 250)
$controlPanel.BorderStyle = "FixedSingle"
$controlPanel.Anchor = "Top,Left,Right"
$form.Controls.Add($controlPanel)

# Quick Actions buttons
$startAllButton = New-Object System.Windows.Forms.Button
$startAllButton.Location = New-Object System.Drawing.Point(10, 10)
$startAllButton.Size = New-Object System.Drawing.Size(80, 30)
$startAllButton.Text = "[*] Start All"
$startAllButton.BackColor = [System.Drawing.Color]::LightGreen
$startAllButton.Add_Click({
    Start-AllServices $config.scripts
})
$controlPanel.Controls.Add($startAllButton)

$stopAllButton = New-Object System.Windows.Forms.Button
$stopAllButton.Location = New-Object System.Drawing.Point(100, 10)
$stopAllButton.Size = New-Object System.Drawing.Size(80, 30)
$stopAllButton.Text = "[X] Stop All"
$stopAllButton.BackColor = [System.Drawing.Color]::LightCoral
$stopAllButton.Add_Click({
    Stop-AllServices $config.scripts
})
$controlPanel.Controls.Add($stopAllButton)

$testButton = New-Object System.Windows.Forms.Button
$testButton.Location = New-Object System.Drawing.Point(190, 10)
$testButton.Size = New-Object System.Drawing.Size(90, 30)
$testButton.Text = "[?] Test Scripts"
$testButton.BackColor = [System.Drawing.Color]::LightYellow
$testButton.Add_Click({
    $results = @()
    
    foreach ($script in $config.scripts) {
        $scriptPath = if ([System.IO.Path]::IsPathRooted($script.directory)) {
            Join-Path $script.directory $script.scriptFile
        } else {
            Join-Path (Get-Location) (Join-Path $script.directory $script.scriptFile)
        }
        
        if (Test-Path $scriptPath) {
            $results += "[OK] $($script.name)"
        } else {
            $results += "[ERROR] $($script.name) - Script not found"
        }
    }
    
    if ($global:HasWindowsTerminal) {
        $results += "[OK] Windows Terminal available"
    } else {
        $results += "[INFO] Windows Terminal not found"
    }
    
    $message = "Script Status:`n`n" + ($results -join "`n")
    [System.Windows.Forms.MessageBox]::Show($message, "Script Test Results", "OK", "Information")
})
$controlPanel.Controls.Add($testButton)

$clearLogsButton = New-Object System.Windows.Forms.Button
$clearLogsButton.Location = New-Object System.Drawing.Point(290, 10)
$clearLogsButton.Size = New-Object System.Drawing.Size(80, 30)
$clearLogsButton.Text = "[C] Clear Logs"
$clearLogsButton.BackColor = [System.Drawing.Color]::LightGray
$clearLogsButton.Add_Click({
    $global:LogEntries.Clear()
    $global:LogTextBox.Clear()
    Add-LogEntry "[INFO] Logs cleared"
})
$controlPanel.Controls.Add($clearLogsButton)

$exitButton = New-Object System.Windows.Forms.Button
$exitButton.Location = New-Object System.Drawing.Point(580, 10)
$exitButton.Size = New-Object System.Drawing.Size(70, 30)
$exitButton.Text = "[X] Exit"
$exitButton.BackColor = [System.Drawing.Color]::LightPink
$exitButton.Anchor = "Top,Right"
$exitButton.Add_Click({ $form.Close() })
$controlPanel.Controls.Add($exitButton)

# Logs section
$logsLabel = New-Object System.Windows.Forms.Label
$logsLabel.Location = New-Object System.Drawing.Point(20, 390)
$logsLabel.Size = New-Object System.Drawing.Size(200, 20)
$logsLabel.Text = "Activity Logs:"
$logsLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$logsLabel.Anchor = "Top,Left"
$form.Controls.Add($logsLabel)

$global:LogTextBox = New-Object System.Windows.Forms.TextBox
$global:LogTextBox.Location = New-Object System.Drawing.Point(20, 415)
$global:LogTextBox.Size = New-Object System.Drawing.Size(660, 150)
$global:LogTextBox.Multiline = $true
$global:LogTextBox.ScrollBars = "Vertical"
$global:LogTextBox.ReadOnly = $true
$global:LogTextBox.BackColor = [System.Drawing.Color]::Black
$global:LogTextBox.ForeColor = [System.Drawing.Color]::LightGreen
$global:LogTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
$global:LogTextBox.Anchor = "Top,Bottom,Left,Right"
$form.Controls.Add($global:LogTextBox)

# Initialize logs
Add-LogEntry "[*] AI Service Manager Advanced started"
Add-LogEntry "[INFO] Loaded $($config.scripts.Count) scripts"
Add-LogEntry "[INFO] Windows Terminal: $(if ($global:HasWindowsTerminal) { 'Available' } else { 'Not found' })"
Add-LogEntry "[READY] Click service buttons or use Start All/Stop All"

# MCP log monitoring (if MCP is running)
$logTimer = New-Object System.Windows.Forms.Timer
$logTimer.Interval = 5000  # Check every 5 seconds
$logTimer.Add_Tick({
    # Check if MCP server is running and log activity
    try {
        $mcpResponse = Invoke-WebRequest -Uri "http://localhost:4000/health" -TimeoutSec 2 -UseBasicParsing -ErrorAction SilentlyContinue
        if ($mcpResponse.StatusCode -eq 200) {
            # MCP is running - could add more detailed monitoring here
        }
    } catch {
        # MCP not running or not accessible
    }
})
$logTimer.Start()

Write-Host "[OK] Showing AI Service Manager Advanced..." -ForegroundColor Green

# Show the form
[System.Windows.Forms.Application]::Run($form)

$logTimer.Stop()
$logTimer.Dispose()
Write-Host "[*] AI Service Manager Advanced closed" -ForegroundColor Cyan