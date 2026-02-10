param(
    [string]$InstallPath = $PWD.Path
)

$ErrorActionPreference = "Stop"
$ToolName = "7zip"
$TempDir  = Join-Path $env:TEMP "atomic_bootstrap_$ToolName"

if (Test-Path $TempDir) { Remove-Item $TempDir -Recurse -Force }
New-Item -ItemType Directory -Path $TempDir -Force | Out-Null

try {
    # 1. Discover latest version by scraping the download page
    Write-Host "Checking 7-zip.org for latest version..." -ForegroundColor Cyan
    $Page = Invoke-WebRequest -Uri "https://7-zip.org/download.html" -UseBasicParsing
    if ($Page.Content -match '7z(\d+)-extra\.7z') {
        $VerCode = $Matches[1]
    } else {
        throw "Could not determine latest 7-Zip version from download page."
    }
    $VerDisplay = $VerCode.Insert($VerCode.Length - 2, '.')
    Write-Host "Latest version: $VerDisplay" -ForegroundColor Cyan

    # 2. Download 7zr.exe (bootstrap extractor) and the Extra package
    $7zrPath   = Join-Path $TempDir "7zr.exe"
    $ExtraPath = Join-Path $TempDir "7z-extra.7z"

    Write-Host "Downloading 7zr.exe (bootstrap extractor)..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri "https://7-zip.org/a/7zr.exe" -OutFile $7zrPath

    Write-Host "Downloading 7z Extra package ($VerCode)..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri "https://7-zip.org/a/7z${VerCode}-extra.7z" -OutFile $ExtraPath

    # 3. Extract using 7zr.exe
    $ExtractDir = Join-Path $TempDir "extracted"
    Write-Host "Extracting..." -ForegroundColor Cyan
    & $7zrPath x $ExtraPath "-o$ExtractDir" -y | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "7zr.exe extraction failed with exit code $LASTEXITCODE" }

    # 4. Copy 64-bit binaries to install path
    Copy-Item (Join-Path $ExtractDir "x64\7za.exe") -Destination $InstallPath -Force
    Copy-Item (Join-Path $ExtractDir "x64\7za.dll") -Destination $InstallPath -Force

    # 5. Legal files
    $LegalDir = Join-Path $InstallPath "7zip-legal"
    if (!(Test-Path $LegalDir)) { New-Item -ItemType Directory -Path $LegalDir -Force | Out-Null }
    $LegalFiles = @("License.txt", "readme.txt")
    foreach ($f in $LegalFiles) {
        $src = Join-Path $ExtractDir $f
        if (Test-Path $src) { Copy-Item $src -Destination $LegalDir -Force }
    }

    Write-Host "7-Zip $VerDisplay installed: 7za.exe, 7za.dll -> $InstallPath" -ForegroundColor Green
}
finally {
    Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue
}
