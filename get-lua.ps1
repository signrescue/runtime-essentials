param(
    [string]$InstallPath = $PWD.Path
)

$ErrorActionPreference = "Stop"
$ToolName    = "lua"
$LuaVersion  = "5.4.8"
$TempDir     = Join-Path $env:TEMP "atomic_bootstrap_$ToolName"

if (Test-Path $TempDir) { Remove-Item $TempDir -Recurse -Force }
New-Item -ItemType Directory -Path $TempDir -Force | Out-Null

try {
    # 1. Download from SourceForge LuaBinaries
    #    SourceForge redirects rely on JavaScript, which Invoke-WebRequest cannot follow.
    #    curl.exe (ships with Windows 10+) handles the redirect chain correctly.
    $Url = "https://sourceforge.net/projects/luabinaries/files/$LuaVersion/Tools%20Executables/lua-${LuaVersion}_Win64_bin.zip/download"
    $ZipFile = Join-Path $TempDir "lua.zip"

    Write-Host "Downloading Lua $LuaVersion from SourceForge..." -ForegroundColor Cyan
    & curl.exe -L -o $ZipFile -s -S --max-redirs 10 --retry 2 $Url
    if ($LASTEXITCODE -ne 0) { throw "Download failed (curl exit code $LASTEXITCODE)." }

    # 2. Extract — flat archive, no subfolder
    $ExtractDir = Join-Path $TempDir "extracted"
    Expand-Archive -Path $ZipFile -DestinationPath $ExtractDir -Force

    # 3. Copy binaries (version-suffixed names: lua54.exe, luac54.exe, lua54.dll)
    Get-ChildItem $ExtractDir -File | Where-Object { $_.Extension -in '.exe', '.dll' } | ForEach-Object {
        Copy-Item $_.FullName -Destination $InstallPath -Force
    }

    # 4. Legal files
    $LegalDir = Join-Path $InstallPath "lua-legal"
    if (!(Test-Path $LegalDir)) { New-Item -ItemType Directory -Path $LegalDir -Force | Out-Null }
    Get-ChildItem $ExtractDir -File | Where-Object { $_.Name -match '^(LICENSE|COPYING|README|CREDITS)' } | ForEach-Object {
        Copy-Item $_.FullName -Destination $LegalDir -Force
    }

    # List what was installed
    $Binaries = Get-ChildItem $InstallPath -File | Where-Object {
        $_.Extension -in '.exe', '.dll' -and $_.Name -match '^lua'
    } | ForEach-Object { $_.Name }
    Write-Host "Lua $LuaVersion installed: $($Binaries -join ', ') -> $InstallPath" -ForegroundColor Green
}
finally {
    Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue
}
