# Shortcut-Generator

## Game Shortcut Generator

This PowerShell script scans a game installation directory and automatically creates `.lnk` shortcuts
for all detected games, filtering out junk executables and selecting the best match per folder.

Useful for frontend launchers like Kodi + Advanced Kodi Launcher or Playnite-style setups.

### Features
- Recursively finds `.exe` files
- Filters out config, patch, and setup junk
- Fuzzy-matches folder name to game executable
- Supports `-DryRun` for safe preview

### Example
```powershell
.\generate-game-shortcuts.ps1 -GameRoot "D:\Games" -ShortcutDir "$env:USERPROFILE\Desktop\GameShortcuts" -DryRun
