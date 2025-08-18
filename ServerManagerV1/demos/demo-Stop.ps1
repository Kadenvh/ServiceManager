# Demo Service Stop - Example Script
# Purpose: Demonstrates proper stop script structure

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptPath

Write-Host "[*] Stopping Demo Service" -ForegroundColor Red
Write-Host "=========================" -ForegroundColor Red

Write-Host "`n[INFO] Working Directory: $scriptPath" -ForegroundColor Cyan

# Demo stop logic
try {
    Write-Host "`n[INFO] Looking for demo service processes..." -ForegroundColor Yellow
    
    # In a real script, you'd look for your actual service processes
    # For demo, we'll look for PowerShell processes running our demo script
    $demoProcesses = Get-Process -Name "powershell" -ErrorAction SilentlyContinue | Where-Object {
        $_.CommandLine -like "*Demo-Start.ps1*"
    }
    
    if ($demoProcesses) {
        Write-Host "[INFO] Found demo service processes:" -ForegroundColor Yellow
        $demoProcesses | ForEach-Object {
            Write-Host "  PID: $($_.Id) - $($_.ProcessName)" -ForegroundColor Gray
            Write-Host "[INFO] Stopping demo process PID $($_.Id)" -ForegroundColor Yellow
            Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
            Write-Host "[OK] Stopped demo process PID $($_.Id)" -ForegroundColor Green
        }
    } else {
        Write-Host "[INFO] No demo service processes found" -ForegroundColor Gray
    }
    
    # Example: Stop processes by port (if your service uses a specific port)
    $portProcesses = netstat -ano | findstr ":8080"
    if ($portProcesses) {
        Write-Host "`n[INFO] Processes using port 8080:" -ForegroundColor Yellow
        $portProcesses | ForEach-Object { Write-Host $_ -ForegroundColor Gray }
        
        $processIds = $portProcesses | ForEach-Object { 
            ($_ -split '\s+')[-1] 
        } | Select-Object -Unique
        
        foreach ($processId in $processIds) {
            if ($processId -and $processId -ne "0") {
                try {
                    taskkill /PID $processId /F 2>$null
                    Write-Host "[OK] Killed process PID $processId" -ForegroundColor Green
                } catch {
                    Write-Host "[WARN] Could not kill PID $processId" -ForegroundColor Yellow
                }
            }
        }
    } else {
        Write-Host "[INFO] No processes found using port 8080" -ForegroundColor Gray
    }
    
    # Clean up demo files
    $logFile = Join-Path $scriptPath "demo.log"
    if (Test-Path $logFile) {
        Write-Host "[INFO] Cleaning up demo log file..." -ForegroundColor Yellow
        Remove-Item $logFile -Force
        Write-Host "[OK] Demo log file removed" -ForegroundColor Green
    }
    
    Write-Host "`n[*] Demo Service shutdown complete" -ForegroundColor Green
    Write-Host "=================================" -ForegroundColor Green
    Write-Host "[INFO] This demo shows proper stop script structure" -ForegroundColor Cyan
    
} catch {
    Write-Host "[ERROR] Error during demo service shutdown: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nPress Enter to close..." -ForegroundColor Gray
Read-Host