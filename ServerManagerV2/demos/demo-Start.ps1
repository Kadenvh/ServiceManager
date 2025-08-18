# Demo Service Startup - Example Script
# Purpose: Demonstrates proper script structure for AI Service Manager

# REQUIRED: Directory navigation (must be at top)
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptPath

Write-Host "[*] Starting Demo Service" -ForegroundColor Green
Write-Host "=========================" -ForegroundColor Green

Write-Host "`n[INFO] Working Directory: $scriptPath" -ForegroundColor Cyan

# Demo service logic
try {
    Write-Host "`n[INFO] Checking demo service requirements..." -ForegroundColor Yellow
    
    # Simulate service startup
    Write-Host "[INFO] Initializing demo service..." -ForegroundColor Yellow
    Start-Sleep 2
    
    Write-Host "[OK] Demo service started successfully!" -ForegroundColor Green
    Write-Host "[INFO] Demo service running on http://localhost:8080" -ForegroundColor Cyan
    Write-Host "[INFO] Demo logs available at: $scriptPath\demo.log" -ForegroundColor Cyan
    
    # Create a demo log file
    $logFile = Join-Path $scriptPath "demo.log"
    "$(Get-Date): Demo service started by AI Service Manager" | Set-Content $logFile
    
    Write-Host "`n[*] Demo Service Ready!" -ForegroundColor Green
    Write-Host "================================" -ForegroundColor Green
    Write-Host "[INFO] This is a demo script showing proper structure" -ForegroundColor Cyan
    Write-Host "[INFO] Press Ctrl+C to stop the demo service" -ForegroundColor Gray
    
    # Keep the service "running" (demo only)
    while ($true) {
        Start-Sleep 5
        "$(Get-Date): Demo service heartbeat" | Add-Content $logFile
    }
    
} catch {
    Write-Host "[ERROR] Failed to start demo service: $($_.Exception.Message)" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "`nPress any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")