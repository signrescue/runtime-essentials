param(
    [string]$InstallPath = $PWD.Path
)

$ErrorActionPreference = "Stop"
$ToolName = "7zr"
$TempDir  = Join-Path $env:TEMP "atomic_bootstrap_$ToolName"

if (Test-Path $TempDir) { Remove-Item $TempDir -Recurse -Force }
New-Item -ItemType Directory -Path $TempDir -Force | Out-Null

try {
    # 7zr.exe is a direct download — single standalone executable, no extraction needed.
    # It handles .7z archives and requires no DLLs.
    Write-Host "Downloading 7zr.exe from 7-zip.org..." -ForegroundColor Cyan
    $TempFile = Join-Path $TempDir "7zr.exe"
    Invoke-WebRequest -Uri "https://7-zip.org/a/7zr.exe" -OutFile $TempFile

    Copy-Item $TempFile -Destination $InstallPath -Force

    # Legal — 7zr.exe is part of the 7-Zip project (LGPL + BSD 3-clause + unRAR restriction)
    # The license is embedded in the download page; we fetch it from the Extra package readme.
    # Since 7zr.exe is a direct binary with no accompanying license file, we note the source.
    $LegalDir = Join-Path $InstallPath "7zr-legal"
    if (!(Test-Path $LegalDir)) { New-Item -ItemType Directory -Path $LegalDir -Force | Out-Null }
    Set-Content -Path (Join-Path $LegalDir "SOURCE.txt") -Value @"
7zr.exe - 7-Zip Reduced Standalone Console
Downloaded from: https://7-zip.org/a/7zr.exe
Project: https://7-zip.org/
License: GNU LGPL + BSD 3-clause (see https://7-zip.org/license.txt)
"@

    Write-Host "7zr.exe installed -> $InstallPath" -ForegroundColor Green
}
finally {
    Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue
}
