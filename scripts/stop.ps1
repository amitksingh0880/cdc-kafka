# PowerShell script to stop and clean up CDC infrastructure

param(
    [switch]$RemoveVolumes,
    [switch]$Force
)

Write-Host "Stopping CDC + Kafka Infrastructure..." -ForegroundColor Yellow

if ($RemoveVolumes) {
    Write-Host "WARNING: This will remove all data volumes!" -ForegroundColor Red
    if (-not $Force) {
        $confirm = Read-Host "Are you sure? (y/N)"
        if ($confirm -ne 'y' -and $confirm -ne 'Y') {
            Write-Host "Aborted." -ForegroundColor Yellow
            exit 0
        }
    }
    docker compose down -v
    Write-Host "[OK] All containers and volumes removed" -ForegroundColor Green
}
else {
    docker compose down
    Write-Host "[OK] All containers stopped (data preserved)" -ForegroundColor Green
}

Write-Host "`nTo restart, run: .\scripts\start.ps1" -ForegroundColor Cyan
