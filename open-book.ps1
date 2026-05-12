#Requires -Version 5.1
<#
  Build the Thorium Web reader URL for a publication that lives in ./books/.

  Usage:
    ./open-book.ps1 -List                        # print URLs for every book
    ./open-book.ps1 -Name "book.epub"            # print one URL
    ./open-book.ps1 -Name "book.epub" -Open      # open it in the default browser
#>
param(
  [string]$Name,
  [switch]$List,
  [switch]$Open,
  [int]$ServerPort  = 15080,
  [int]$ThoriumPort = 3000
)

$ErrorActionPreference = "Stop"
$booksDir = Join-Path $PSScriptRoot "books"

function ToBase64Url([string]$s) {
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($s)
  $b64 = [Convert]::ToBase64String($bytes)
  return $b64.TrimEnd('=').Replace('+','-').Replace('/','_')
}

function Get-ThoriumUrl([string]$filename) {
  $inner = ToBase64Url $filename
  $manifestUrl = "http://localhost:$ServerPort/webpub/$inner/manifest.json"
  $encoded = [System.Uri]::EscapeDataString($manifestUrl)
  return "http://localhost:$ThoriumPort/read/manifest/$encoded"
}

if (-not (Test-Path $booksDir)) {
  Write-Host "books folder not found at $booksDir" -ForegroundColor Red
  Write-Host "Run ./setup.ps1 first, or create the folder manually." -ForegroundColor Yellow
  exit 1
}

if ($List -or -not $Name) {
  $items = Get-ChildItem $booksDir -File | Where-Object { $_.Extension -match '^\.(epub|pdf|cbz)$' }
  if ($items.Count -eq 0) {
    Write-Host "No publications found in $booksDir" -ForegroundColor Yellow
    exit 0
  }
  foreach ($f in $items) {
    $url = Get-ThoriumUrl $f.Name
    Write-Host ""
    Write-Host $f.Name -ForegroundColor Cyan
    Write-Host "  $url"
  }
  exit 0
}

$candidate = Join-Path $booksDir $Name
if (-not (Test-Path $candidate)) {
  Write-Host "File not found: $candidate" -ForegroundColor Red
  exit 1
}

$url = Get-ThoriumUrl (Split-Path $candidate -Leaf)
Write-Host $url

if ($Open) {
  Start-Process $url
}
