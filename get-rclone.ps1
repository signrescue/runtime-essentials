param(
    [string]$InstallPath = $PWD.Path
)

$ErrorActionPreference = "Stop"
$ToolName = "rclone"
$TempDir  = Join-Path $env:TEMP "atomic_bootstrap_$ToolName"

if (Test-Path $TempDir) { Remove-Item $TempDir -Recurse -Force }
New-Item -ItemType Directory -Path $TempDir -Force | Out-Null

try {
    # 1. Query GitHub for latest release
    Write-Host "Checking GitHub for latest rclone version..." -ForegroundColor Cyan
    $Latest = Invoke-RestMethod -Uri "https://api.github.com/repos/rclone/rclone/releases/latest"
    $Version = $Latest.tag_name

    $Asset = $Latest.assets | Where-Object { $_.name -like "rclone-*-windows-amd64.zip" } | Select-Object -First 1
    if (!$Asset) { throw "Could not find Windows amd64 asset in rclone $Version release." }

    # 2. Download
    $ZipFile = Join-Path $TempDir "rclone.zip"
    Write-Host "Downloading rclone $Version..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $Asset.browser_download_url -OutFile $ZipFile

    # 3. Extract to temp — zip contains a nested subfolder
    $ExtractDir = Join-Path $TempDir "extracted"
    Expand-Archive -Path $ZipFile -DestinationPath $ExtractDir -Force
    $SubFolder = Get-ChildItem $ExtractDir -Directory | Select-Object -First 1
    if (!$SubFolder) { throw "Unexpected archive structure: no subfolder found." }

    # 4. Copy binary
    Copy-Item (Join-Path $SubFolder.FullName "rclone.exe") -Destination $InstallPath -Force

    # 5. Legal files
    $LegalDir = Join-Path $InstallPath "rclone-legal"
    if (!(Test-Path $LegalDir)) { New-Item -ItemType Directory -Path $LegalDir -Force | Out-Null }
    Get-ChildItem $SubFolder.FullName -File | Where-Object { $_.Name -match '^(LICENSE|COPYING|README|CREDITS)' } | ForEach-Object {
        Copy-Item $_.FullName -Destination $LegalDir -Force
    }

    Write-Host "rclone $Version installed: rclone.exe -> $InstallPath" -ForegroundColor Green
}
finally {
    Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue
}
