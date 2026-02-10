param(
    [string]$InstallPath = $PWD.Path
)

$ErrorActionPreference = "Stop"
$ToolName = "croc"
$TempDir  = Join-Path $env:TEMP "atomic_bootstrap_$ToolName"

if (Test-Path $TempDir) { Remove-Item $TempDir -Recurse -Force }
New-Item -ItemType Directory -Path $TempDir -Force | Out-Null

try {
    # 1. Query GitHub for latest release
    Write-Host "Checking GitHub for latest croc version..." -ForegroundColor Cyan
    $Latest = Invoke-RestMethod -Uri "https://api.github.com/repos/schollz/croc/releases/latest"
    $Version = $Latest.tag_name

    $Asset = $Latest.assets | Where-Object { $_.name -like "*Windows-64bit.zip" } | Select-Object -First 1
    if (!$Asset) { throw "Could not find Windows 64-bit asset in croc $Version release." }

    # 2. Download
    $ZipFile = Join-Path $TempDir "croc.zip"
    Write-Host "Downloading croc $Version..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $Asset.browser_download_url -OutFile $ZipFile

    # 3. Extract to temp
    $ExtractDir = Join-Path $TempDir "extracted"
    Expand-Archive -Path $ZipFile -DestinationPath $ExtractDir -Force

    # 4. Copy binary
    Copy-Item (Join-Path $ExtractDir "croc.exe") -Destination $InstallPath -Force

    # 5. Legal files
    $LegalDir = Join-Path $InstallPath "croc-legal"
    if (!(Test-Path $LegalDir)) { New-Item -ItemType Directory -Path $LegalDir -Force | Out-Null }
    Get-ChildItem $ExtractDir -File | Where-Object { $_.Name -match '^(LICENSE|COPYING|README|CREDITS)' } | ForEach-Object {
        Copy-Item $_.FullName -Destination $LegalDir -Force
    }

    Write-Host "croc $Version installed: croc.exe -> $InstallPath" -ForegroundColor Green
}
finally {
    Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue
}
