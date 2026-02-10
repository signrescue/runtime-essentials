# zero-install-tool-drops

One-liner PowerShell scripts that drop portable CLI tools into your current directory. No installers, no PATH changes, no admin required.

Open PowerShell, `cd` to where you want the tool, and paste:

### croc — secure peer-to-peer file transfer

```
irm https://raw.githubusercontent.com/signrescue/zero-install-tool-drops/main/get-croc.ps1 | iex
```

### rclone — cloud storage Swiss army knife

```
irm https://raw.githubusercontent.com/signrescue/zero-install-tool-drops/main/get-rclone.ps1 | iex
```

### FFmpeg — video/audio encoding, conversion, streaming

```
irm https://raw.githubusercontent.com/signrescue/zero-install-tool-drops/main/get-ffmpeg.ps1 | iex
```

### mpv — minimalist media player

```
irm https://raw.githubusercontent.com/signrescue/zero-install-tool-drops/main/get-mpv.ps1 | iex
```

### Lua — lightweight scripting language

```
irm https://raw.githubusercontent.com/signrescue/zero-install-tool-drops/main/get-lua.ps1 | iex
```

### 7zr — standalone .7z extractor (single file, no DLL)

```
irm https://raw.githubusercontent.com/signrescue/zero-install-tool-drops/main/get-7zr.ps1 | iex
```

### 7-Zip — full standalone console (7za.exe + 7za.dll)

```
irm https://raw.githubusercontent.com/signrescue/zero-install-tool-drops/main/get-7z.ps1 | iex
```

---

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

## Notes

- **PowerShell 5.1+** and **Windows 10/11** required (all dependencies ship with the OS)
- **mpv** needs a `.7z` extractor — `get-mpv.ps1` will offer to download `7zr.exe` if not found
- Every script accepts `-InstallPath` to override the target directory
- Each script cleans up its temp files in a `finally` block, even on failure
