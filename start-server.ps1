$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$exe = Join-Path $root "tools\readium\readium.exe"
$books = Join-Path $root "books"

if (-not (Test-Path $exe)) {
  Write-Host "readium.exe not found. Run ./setup.ps1 first." -ForegroundColor Red
  exit 1
}
if (-not (Test-Path $books)) {
  New-Item -ItemType Directory -Force $books | Out-Null
}

Write-Host "Serving $books on http://localhost:15080" -ForegroundColor Green
Write-Host "Drop .epub files into $books and run ./open-book.ps1 -List for URLs." -ForegroundColor Green
Write-Host ""
& $exe serve --file-directory $books --address localhost --port 15080
