#Requires -Version 5.1
<#
  One-shot setup for web-epub-reader-local-books.

  - Clones edrlab/thorium-web into ./thorium-web
  - Runs pnpm install inside it
  - Downloads readium CLI for Windows into ./tools/readium

  Re-running is safe: existing components are skipped.
#>
param(
  [string]$ThoriumRepo  = "https://github.com/edrlab/thorium-web.git",
  [string]$ReadiumVersion = "v0.6.6"
)

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot

function Test-Command([string]$name) {
  return [bool](Get-Command $name -ErrorAction SilentlyContinue)
}

function Require-Command([string]$name, [string]$hint) {
  if (-not (Test-Command $name)) {
    Write-Host "Missing required tool: $name" -ForegroundColor Red
    Write-Host "  $hint" -ForegroundColor Yellow
    exit 1
  }
}

Write-Host "==> Checking prerequisites" -ForegroundColor Cyan
Require-Command "git"  "Install Git: https://git-scm.com/download/win"
Require-Command "node" "Install Node.js >=20 (Thorium .nvmrc asks for v22): https://nodejs.org/"
Require-Command "pnpm" "Install pnpm:  npm install -g pnpm"

$nodeMajor = ([Version](node --version).TrimStart('v')).Major
if ($nodeMajor -lt 20) {
  Write-Host "Node $nodeMajor detected; need >= 20." -ForegroundColor Red
  exit 1
}
Write-Host "  git, node v$nodeMajor, pnpm $(pnpm --version) — OK" -ForegroundColor Green

# --- thorium-web ---
$thoriumDir = Join-Path $root "thorium-web"
if (Test-Path $thoriumDir) {
  Write-Host "==> thorium-web already cloned, pulling latest" -ForegroundColor Cyan
  git -C $thoriumDir pull --ff-only
} else {
  Write-Host "==> Cloning thorium-web" -ForegroundColor Cyan
  git clone --depth 1 $ThoriumRepo $thoriumDir
}

Write-Host "==> Installing thorium-web dependencies (pnpm install)" -ForegroundColor Cyan
Push-Location $thoriumDir
try {
  pnpm install
} finally {
  Pop-Location
}

# --- readium CLI ---
$toolsDir   = Join-Path $root "tools"
$readiumDir = Join-Path $toolsDir "readium"
$readiumExe = Join-Path $readiumDir "readium.exe"

if (Test-Path $readiumExe) {
  Write-Host "==> readium.exe already present, skipping download" -ForegroundColor Cyan
} else {
  Write-Host "==> Downloading readium CLI $ReadiumVersion" -ForegroundColor Cyan
  New-Item -ItemType Directory -Force $toolsDir | Out-Null
  $arch = if ([Environment]::Is64BitOperatingSystem) { "x86_64" } else { "i386" }
  $asset = "readium_windows_$arch.zip"
  $url = "https://github.com/readium/cli/releases/download/$ReadiumVersion/$asset"
  $zip = Join-Path $toolsDir "readium.zip"

  Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing
  Expand-Archive -Path $zip -DestinationPath $readiumDir -Force
  Remove-Item $zip

  if (-not (Test-Path $readiumExe)) {
    Write-Host "Download succeeded but readium.exe is missing in archive." -ForegroundColor Red
    exit 1
  }
}

# --- books/ ---
$booksDir = Join-Path $root "books"
if (-not (Test-Path $booksDir)) {
  New-Item -ItemType Directory -Force $booksDir | Out-Null
}

Write-Host ""
Write-Host "==> Setup complete." -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Drop .epub files into  $booksDir"
Write-Host "  2. Start both servers     ./start.ps1"
Write-Host "  3. Get book URLs          ./open-book.ps1 -List"
