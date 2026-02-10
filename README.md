# zero-install-tool-drops

One-liner PowerShell scripts that drop portable CLI tools into your current directory. No installers, no PATH changes, no admin required.

## Usage

Open PowerShell, `cd` to where you want the tool, and run:

```powershell
# File transfer
irm https://raw.githubusercontent.com/signrescue/zero-install-tool-drops/main/get-croc.ps1 | iex
irm https://raw.githubusercontent.com/signrescue/zero-install-tool-drops/main/get-rclone.ps1 | iex

# Media
irm https://raw.githubusercontent.com/signrescue/zero-install-tool-drops/main/get-ffmpeg.ps1 | iex
irm https://raw.githubusercontent.com/signrescue/zero-install-tool-drops/main/get-mpv.ps1 | iex

# Scripting
irm https://raw.githubusercontent.com/signrescue/zero-install-tool-drops/main/get-lua.ps1 | iex

# Compression
irm https://raw.githubusercontent.com/signrescue/zero-install-tool-drops/main/get-7zr.ps1 | iex
irm https://raw.githubusercontent.com/signrescue/zero-install-tool-drops/main/get-7z.ps1 | iex
```

Each script downloads the latest version, extracts only the binaries, and cleans up after itself.

## What You Get

| Script | Drops | Source |
| --- | --- | --- |
| `get-croc.ps1` | `croc.exe` | [schollz/croc](https://github.com/schollz/croc) |
| `get-rclone.ps1` | `rclone.exe` | [rclone/rclone](https://github.com/rclone/rclone) |
| `get-ffmpeg.ps1` | `ffmpeg.exe`, `ffprobe.exe`, `ffplay.exe` | [gyan.dev](https://www.gyan.dev/ffmpeg/builds/) |
| `get-mpv.ps1` | `mpv.exe` | [shinchiro/mpv-winbuild-cmake](https://github.com/shinchiro/mpv-winbuild-cmake) |
| `get-lua.ps1` | `lua54.exe`, `luac54.exe`, `lua54.dll` | [LuaBinaries](https://luabinaries.sourceforge.net/) |
| `get-7zr.ps1` | `7zr.exe` | [7-zip.org](https://7-zip.org/) |
| `get-7z.ps1` | `7za.exe`, `7za.dll` | [7-zip.org](https://7-zip.org/) |

License files for each tool are placed in a `[tool]-legal/` subfolder alongside the binaries.

## Dependencies

- **PowerShell 5.1+** (ships with Windows 10/11)
- **curl.exe** (ships with Windows 10/11) — used only by `get-lua.ps1` for SourceForge downloads
- **mpv** requires a `.7z` extractor. `get-mpv.ps1` will look for `7zr.exe` in the current directory or PATH, and offer to download it if not found.

All other scripts use `Expand-Archive` (built into PowerShell) and have zero external dependencies.

## How It Works

Each script:

1. Creates a temp folder in `%TEMP%\atomic_bootstrap_[tool]`
2. Downloads the latest release archive
3. Extracts binaries into your current directory (or `-InstallPath`)
4. Copies license/legal files into `[tool]-legal/`
5. Removes the temp folder in a `finally` block — always cleans up, even on failure

## Custom Install Path

Every script accepts an `-InstallPath` parameter:

```powershell
.\get-croc.ps1 -InstallPath "C:\Tools"
```

When using `irm | iex`, the default is your current directory (`$PWD`).
