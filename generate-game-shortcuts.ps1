<#
.SYNOPSIS
    Scans a specified games directory and creates Windows shortcut (.lnk) files
    for each detected game executable in a target shortcut folder.

.DESCRIPTION
    This script is designed for use with frontends like Kodi (via Advanced Kodi Launcher)
    where games are stored in folders and launched from .exe files.

    It intelligently skips junk executables (e.g., uninstallers, config tools) and tries to
    find the main game executable by fuzzy matching the folder name.

.PARAMETER GameRoot
    The root directory containing individual game folders.

.PARAMETER ShortcutDir
    The directory where shortcut (.lnk) files will be created.

.PARAMETER DryRun
    Optional switch. If used, the script will only print what it *would* do
    without actually creating shortcuts.

.EXAMPLE
    .\generate-game-shortcuts.ps1 -GameRoot "D:\Games" -ShortcutDir "$env:USERPROFILE\Desktop\Playnite" -DryRun
#>

param (
    [string]$GameRoot = "D:\Games",
    [string]$ShortcutDir = "$env:USERPROFILE\Desktop\GameShortcuts",
    [switch]$DryRun
)

# Patterns of executables to skip
$bannedPatterns = @(
    "unins", "setup", "install", "support", "config", "patch", "readme", "update",
    "crashhandler", "vcredist", "redistributable", "dotnet", "dxweb", "epicwebhelper",
    "pip", "python", "qtwebengine", "scriptinterpreter", "crashreport", "swstub",
    "steamclient_loader", "protoc", "compiler", "archive2"
)

# Create shortcut directory if needed
if (-not (Test-Path $ShortcutDir)) {
    New-Item -Path $ShortcutDir -ItemType Directory | Out-Null
}

$WshShell = New-Object -ComObject WScript.Shell

function IsBannedExe($exePath) {
    $basename = [System.IO.Path]::GetFileNameWithoutExtension($exePath).ToLower()
    return $bannedPatterns | Where-Object { $basename -like "*$_*" }
}

function IsProbableMainExe($folderName, $exeFile) {
    $base = $exeFile.BaseName.ToLower()
    $folder = $folderName.ToLower()
    $normalizedBase = $base -replace '[^a-z0-9]', ''
    $normalizedFolder = $folder -replace '[^a-z0-9]', ''
    return $normalizedFolder -like "*$normalizedBase*"
}

# Scan top-level game folders only
Get-ChildItem -Path $GameRoot -Directory | ForEach-Object {
    $folder = $_.FullName
    $folderName = $_.Name

    $exeFiles = Get-ChildItem -Path $folder -Filter *.exe -File -Recurse -ErrorAction SilentlyContinue |
        Where-Object { -not (IsBannedExe $_.FullName) }

    $mainExe = $exeFiles | Where-Object { IsProbableMainExe $folderName $_ } | Select-Object -First 1

    if (-not $mainExe) {
        # fallback to first non-banned exe in root
        $mainExe = Get-ChildItem -Path $folder -Filter *.exe -File -ErrorAction SilentlyContinue |
            Where-Object { -not (IsBannedExe $_.FullName) } |
            Select-Object -First 1
    }

    if ($mainExe) {
        $exePath = $mainExe.FullName
        $shortcutName = ($folderName -replace '[\\/:*?"<>|]', '') + ".lnk"
        $shortcutPath = Join-Path $ShortcutDir $shortcutName

        if (-not (Test-Path $shortcutPath)) {
            if ($DryRun) {
                Write-Host "[DRY RUN] Would create shortcut: $shortcutName -> $exePath"
            } else {
                Write-Host "Creating shortcut: $shortcutName -> $exePath"
                $Shortcut = $WshShell.CreateShortcut($shortcutPath)
                $Shortcut.TargetPath = $exePath
                $Shortcut.WorkingDirectory = Split-Path $exePath
                $Shortcut.IconLocation = "$exePath,0"
                $Shortcut.WindowStyle = 1
                $Shortcut.Save()
            }
        } else {
            Write-Host "Skipping (already exists): $shortcutName"
        }
    }
}
