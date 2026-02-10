## Spec: The "Atomic-Get" Portable Toolkit (v4)

This specification codifies the system for building a high-performance, lean utility toolkit. Every script is a "clean-room" operation: it fetches the tool, strips away everything but the essentials, and leaves the system exactly as it found it — save for the new binaries and legal docs.

Each script is designed to be run as a one-liner via `irm | iex`, dropping portable executables directly into the user's current directory.

---

### 1. The Core Utility Stack

The repository contains dedicated atomic scripts for the following:

| Script | Tool | Source | Format |
| --- | --- | --- | --- |
| `get-7z.ps1` | **7-Zip** (standalone console) | 7-zip.org | `.7z` (self-bootstraps via `7zr.exe`) |
| `get-croc.ps1` | **croc** (peer-to-peer file transfer) | GitHub `schollz/croc` | `.zip` |
| `get-rclone.ps1` | **rclone** (cloud storage Swiss army knife) | GitHub `rclone/rclone` | `.zip` |
| `get-ffmpeg.ps1` | **FFmpeg Suite** (ffmpeg, ffprobe, ffplay) | gyan.dev essentials build | `.zip` |
| `get-mpv.ps1` | **mpv** (minimalist media player) | GitHub `shinchiro/mpv-winbuild-cmake` | `.7z` (requires 7-Zip) |
| `get-lua.ps1` | **Lua** (interpreter + compiler) | SourceForge LuaBinaries | `.zip` |

---

### 2. Standardized Extraction & Shredding Logic

Each script adheres to the **"Temp Staging"** protocol:

1. **Stage:** Create a unique directory at `$env:TEMP\atomic_bootstrap_[toolname]`.
2. **Download:** Fetch the archive into the temp directory.
3. **Extract:** Unpack the archive within the temp directory.
4. **Filter:** Copy only what matters to the install path (defaults to current directory):
   * **Binaries:** `*.exe`, `*.dll` — placed directly in the install path.
   * **Legal:** `LICENSE*`, `COPYING*`, `README*`, `CREDITS*` — placed in a `[tool]-legal/` subfolder.
5. **Shred:** The `finally` block executes `Remove-Item -Recurse -Force` on the temp directory, regardless of success or failure. Uses `-ErrorAction SilentlyContinue` so cleanup never masks real errors.

All scripts accept an `-InstallPath` parameter (defaults to `$PWD.Path`).

---

### 3. Legal File Handling

Each tool's license and legal files are placed in a dedicated subfolder (`[tool]-legal/`) within the install path. Files are copied with their original names — no renaming or concatenation. If a tool ships multiple legal files, they all go into the folder.

Examples: `croc-legal/LICENSE`, `ffmpeg-legal/LICENSE`, `rclone-legal/README.txt`

---

### 4. The 7-Zip Bootstrap

7-Zip has a unique bootstrapping challenge: the Extra package (containing the standalone `7za.exe`) is distributed as a `.7z` file.

**Resolution:** 7-zip.org provides `7zr.exe` as a direct-download standalone executable that can extract `.7z` archives. The `get-7z.ps1` script:

1. Downloads `7zr.exe` from `https://7-zip.org/a/7zr.exe`
2. Scrapes the download page to discover the latest version code
3. Downloads the Extra package (`7z{VVVV}-extra.7z`)
4. Uses `7zr.exe` to extract the 64-bit binaries from the `x64/` subfolder
5. Cleans up `7zr.exe` (it lives only in the temp directory)

### 5. The mpv / 7-Zip Dependency

mpv is only distributed as `.7z`. The `get-mpv.ps1` script resolves this by:

1. Checking for `7za.exe` in the current directory
2. Checking for `7za.exe` or `7z.exe` on PATH
3. If not found: prompting the user to auto-download 7-Zip (runs the same bootstrap inline)

If the user accepts, `7za.exe` and `7za.dll` are placed in the install path alongside `mpv.exe` — since 7-Zip is a useful toolkit member anyway.

---

### 6. Summary of Output

Running individual scripts into the same directory produces this structure:

| Script | Resulting Files |
| --- | --- |
| `get-7z.ps1` | `7za.exe`, `7za.dll`, `7zip-legal/` |
| `get-croc.ps1` | `croc.exe`, `croc-legal/` |
| `get-rclone.ps1` | `rclone.exe`, `rclone-legal/` |
| `get-ffmpeg.ps1` | `ffmpeg.exe`, `ffprobe.exe`, `ffplay.exe`, `ffmpeg-legal/` |
| `get-mpv.ps1` | `mpv.exe`, `mpv-legal/` |
| `get-lua.ps1` | `lua54.exe`, `luac54.exe`, `lua54.dll`, `lua-legal/` |

**Note on Lua:** LuaBinaries uses version-suffixed filenames (`lua54.exe`, not `lua.exe`). The original names are preserved.

---

### 7. Version Discovery

| Tool | Method |
| --- | --- |
| 7-Zip | Scrape `https://7-zip.org/download.html` for version pattern |
| croc | GitHub API `/repos/schollz/croc/releases/latest` |
| rclone | GitHub API `/repos/rclone/rclone/releases/latest` |
| FFmpeg | gyan.dev stable URL (always latest; version derived from archive subfolder name) |
| mpv | GitHub API `/repos/shinchiro/mpv-winbuild-cmake/releases/latest` |
| Lua | Hardcoded version (`$LuaVersion` variable at top of script) |

---

### 8. Future: The "Get-All" Orchestrator

A `get-all.ps1` master script may be added later to run all individual scripts in sequence with dependency awareness (downloading 7-Zip first, then passing it to mpv). This is not yet implemented.
