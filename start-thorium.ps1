$ErrorActionPreference = "Stop"
$thorium = Join-Path $PSScriptRoot "thorium-web"
if (-not (Test-Path $thorium)) {
  Write-Host "thorium-web not found. Run ./setup.ps1 first." -ForegroundColor Red
  exit 1
}
Write-Host "Starting Thorium Web dev server on http://localhost:3000" -ForegroundColor Green
Write-Host ""
Set-Location $thorium
pnpm dev
