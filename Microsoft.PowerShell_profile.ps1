# ── Prompt ────────────────────────────────────────────────────────────────────

# Initialize Oh My Posh with a custom theme
oh-my-posh init pwsh --config "C:\Users\g.lafon\.config\ohmyposh\config.omp.toml" | Invoke-Expression
# oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH/jandedobbeleer.omp.json" | Invoke-Expression
$env:POSH_GIT_ENABLED = $true

# ── PSReadLine ────────────────────────────────────────────────────────────────

# Install if needed: Install-Module -Scope CurrentUser PSReadLine -Force
Import-Module PSReadLine

# Show a navigable menu of all options when pressing Tab
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete

# # Navigate history with arrow keys, matching the current input
Set-PSReadLineOption -HistorySearchCursorMovesToEnd
Set-PSReadLineKeyHandler -Key UpArrow   -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

# # Inline suggestions and tooltips
Set-PSReadLineOption -ShowToolTips

# ── PSFzf ─────────────────────────────────────────────────────────────────────

# Ctrl+T → fuzzy file search | Ctrl+R → fuzzy history search
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'

# ── Aliases ───────────────────────────────────────────────────────────────────

Set-Alias ll   ls
Set-Alias grep findstr

# ── Environment ───────────────────────────────────────────────────────────────

$ENV:EDITOR = "$env:USERPROFILE\AppData\Local\Programs\Microsoft VS Code\Code.exe"

# ── Functions ─────────────────────────────────────────────────────────────────

# List all JSON filenames in a folder and write them to json_file_list.txt
function Get-JsonFileList {
    param(
        [Parameter(Mandatory = $false)]
        [string]$Path = "."
    )
    Get-ChildItem -Path $Path -Filter "*.json" | ForEach-Object {
        $_.BaseName >> json_file_list.txt
    }
}

# Equivalent of Unix `which` — returns the full path of a command
function which ($command) {
    Get-Command -Name $command -ErrorAction SilentlyContinue |
        Select-Object -ExpandProperty Path -ErrorAction SilentlyContinue
}

# Quick navigation shortcuts
function ds         { Set-Location "$HOME\Documents\02-Dev\01-DataScience" }
function Ftest      { Set-Location "$HOME\Documents\02-Dev\02-Tests" }
function TestsAutos { Set-Location "$HOME\source\repos\TestsAutos" }

# ── Git Worktree Helpers ──────────────────────────────────────────────────────

. "$HOME\.config\WindowsPowerShell\gw-helpers.ps1"