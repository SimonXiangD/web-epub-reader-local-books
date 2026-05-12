<#
  Convenience launcher: opens two new PowerShell windows, one for each server.
  Close those windows to stop the servers.
#>
$ErrorActionPreference = "Stop"
$root = $PSScriptRoot

if (-not (Test-Path (Join-Path $root "tools\readium\readium.exe"))) {
  Write-Host "Setup hasn't been run yet. Execute ./setup.ps1 first." -ForegroundColor Red
  exit 1
}
if (-not (Test-Path (Join-Path $root "thorium-web"))) {
  Write-Host "Setup hasn't been run yet. Execute ./setup.ps1 first." -ForegroundColor Red
  exit 1
}

$pwshPath = "powershell.exe"
Start-Process $pwshPath -ArgumentList "-NoExit", "-ExecutionPolicy", "Bypass", "-File", (Join-Path $root "start-server.ps1")
Start-Sleep -Seconds 1
Start-Process $pwshPath -ArgumentList "-NoExit", "-ExecutionPolicy", "Bypass", "-File", (Join-Path $root "start-thorium.ps1")

Write-Host "Launched in two new windows." -ForegroundColor Green
Write-Host "  publication-server : http://localhost:15080"
Write-Host "  Thorium Web        : http://localhost:3000"
Write-Host ""
Write-Host "Run  ./open-book.ps1 -List  to get URLs for books in ./books/"
