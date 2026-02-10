param(
    [string]$InstallPath = $PWD.Path
)

$ErrorActionPreference = "Stop"
$ToolName = "ffmpeg"
$TempDir  = Join-Path $env:TEMP "atomic_bootstrap_$ToolName"

if (Test-Path $TempDir) { Remove-Item $TempDir -Recurse -Force }
New-Item -ItemType Directory -Path $TempDir -Force | Out-Null

try {
    # 1. Download from gyan.dev stable URL (always points to latest release)
    $ZipFile = Join-Path $TempDir "ffmpeg.zip"
    Write-Host "Downloading FFmpeg essentials build from gyan.dev..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri "https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip" -OutFile $ZipFile

    # 2. Extract — zip contains a nested subfolder like ffmpeg-{ver}-essentials_build/
    $ExtractDir = Join-Path $TempDir "extracted"
    Write-Host "Extracting (this may take a moment)..." -ForegroundColor Cyan
    Expand-Archive -Path $ZipFile -DestinationPath $ExtractDir -Force

    $SubFolder = Get-ChildItem $ExtractDir -Directory | Select-Object -First 1
    if (!$SubFolder) { throw "Unexpected archive structure: no subfolder found." }

    # Derive version from subfolder name (e.g., "ffmpeg-7.1.1-essentials_build")
    $Version = "unknown"
    if ($SubFolder.Name -match 'ffmpeg-([\d.]+)-') { $Version = $Matches[1] }

    # 3. Copy binaries from bin/ subfolder
    $BinDir = Join-Path $SubFolder.FullName "bin"
    foreach ($exe in @("ffmpeg.exe", "ffprobe.exe", "ffplay.exe")) {
        $src = Join-Path $BinDir $exe
        if (Test-Path $src) { Copy-Item $src -Destination $InstallPath -Force }
    }

    # 4. Legal files
    $LegalDir = Join-Path $InstallPath "ffmpeg-legal"
    if (!(Test-Path $LegalDir)) { New-Item -ItemType Directory -Path $LegalDir -Force | Out-Null }
    Get-ChildItem $SubFolder.FullName -File | Where-Object { $_.Name -match '^(LICENSE|COPYING|README|CREDITS)' } | ForEach-Object {
        Copy-Item $_.FullName -Destination $LegalDir -Force
    }

    Write-Host "FFmpeg $Version installed: ffmpeg.exe, ffprobe.exe, ffplay.exe -> $InstallPath" -ForegroundColor Green
}
finally {
    Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue
}
