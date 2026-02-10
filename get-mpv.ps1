param(
    [string]$InstallPath = $PWD.Path
)

$ErrorActionPreference = "Stop"
$ToolName = "mpv"
$TempDir  = Join-Path $env:TEMP "atomic_bootstrap_$ToolName"

# --- 7zr dependency resolution ---
function Find-7zr {
    # Check install path first (user may have run get-7zr.ps1 already)
    $local = Join-Path $InstallPath "7zr.exe"
    if (Test-Path $local) { return $local }

    # Check PATH for 7zr.exe
    $cmd = Get-Command 7zr -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }

    # Also accept 7za.exe or 7z.exe (full 7-Zip install) as alternatives
    $local = Join-Path $InstallPath "7za.exe"
    if (Test-Path $local) { return $local }
    $cmd = Get-Command 7za -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $cmd = Get-Command 7z -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }

    return $null
}

function Bootstrap-7zr {
    Write-Host "Downloading 7zr.exe (required to extract mpv)..." -ForegroundColor Yellow
    $dest = Join-Path $InstallPath "7zr.exe"
    Invoke-WebRequest -Uri "https://7-zip.org/a/7zr.exe" -OutFile $dest

    # Legal
    $LegalDir = Join-Path $InstallPath "7zr-legal"
    if (!(Test-Path $LegalDir)) { New-Item -ItemType Directory -Path $LegalDir -Force | Out-Null }
    Set-Content -Path (Join-Path $LegalDir "SOURCE.txt") -Value @"
7zr.exe - 7-Zip Reduced Standalone Console
Downloaded from: https://7-zip.org/a/7zr.exe
Project: https://7-zip.org/
License: GNU LGPL + BSD 3-clause (see https://7-zip.org/license.txt)
"@

    Write-Host "7zr.exe bootstrapped -> $InstallPath" -ForegroundColor Green
    return $dest
}

# --- Main ---

if (Test-Path $TempDir) { Remove-Item $TempDir -Recurse -Force }
New-Item -ItemType Directory -Path $TempDir -Force | Out-Null

try {
    # Resolve 7z extractor
    $7zExe = Find-7zr
    if (!$7zExe) {
        Write-Host "mpv is distributed as .7z and requires a 7-Zip extractor." -ForegroundColor Yellow
        $response = Read-Host "Download 7zr.exe to current directory? [Y/n]"
        if ($response -match '^[Nn]') {
            throw "Cannot proceed without 7-Zip. Run get-7zr.ps1 first, or install 7-Zip."
        }
        $7zExe = Bootstrap-7zr
    }
    Write-Host "Using: $7zExe" -ForegroundColor Gray

    # 1. Query GitHub for latest release
    Write-Host "Checking GitHub for latest mpv build..." -ForegroundColor Cyan
    $Latest = Invoke-RestMethod -Uri "https://api.github.com/repos/shinchiro/mpv-winbuild-cmake/releases/latest"
    $Version = $Latest.tag_name

    # Filter for the standard x86_64 build (no -dev, no -v3)
    $Asset = $Latest.assets | Where-Object {
        $_.name -match '^mpv-x86_64-\d{8}-git-[0-9a-f]+\.7z$'
    } | Select-Object -First 1
    if (!$Asset) { throw "Could not find mpv x86_64 .7z asset in release $Version." }

    # 2. Download
    $ArchiveFile = Join-Path $TempDir "mpv.7z"
    Write-Host "Downloading mpv ($Version)..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $Asset.browser_download_url -OutFile $ArchiveFile

    # 3. Extract
    $ExtractDir = Join-Path $TempDir "extracted"
    Write-Host "Extracting..." -ForegroundColor Cyan
    & $7zExe x $ArchiveFile "-o$ExtractDir" -y | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Extraction failed with exit code $LASTEXITCODE" }

    # 4. Copy mpv.exe
    $mpvExe = Get-ChildItem $ExtractDir -Recurse -Filter "mpv.exe" | Select-Object -First 1
    if (!$mpvExe) { throw "mpv.exe not found in extracted archive." }
    Copy-Item $mpvExe.FullName -Destination $InstallPath -Force

    # 5. Legal files
    $LegalDir = Join-Path $InstallPath "mpv-legal"
    if (!(Test-Path $LegalDir)) { New-Item -ItemType Directory -Path $LegalDir -Force | Out-Null }
    Get-ChildItem $ExtractDir -Recurse -File | Where-Object { $_.Name -match '^(LICENSE|COPYING|README|CREDITS)' } | ForEach-Object {
        Copy-Item $_.FullName -Destination $LegalDir -Force
    }

    Write-Host "mpv $Version installed: mpv.exe -> $InstallPath" -ForegroundColor Green
}
finally {
    Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue
}
