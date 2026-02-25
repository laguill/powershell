# PowerShell Configuration

> A step-by-step guide to set up a modern, productive PowerShell environment — inspired by [this blog post](https://hamidmosalla.com/2022/12/26/how-to-customize-windows-terminal-and-powershell-using-fzf-neovim-and-beautify-it-with-oh-my-posh/).

---

## Prerequisites

- [Windows Terminal](https://aka.ms/terminal)
- [winget](https://learn.microsoft.com/en-us/windows/package-manager/winget/)

---

## Installation

### 1. Oh My Posh

Install Oh My Posh via winget:

```powershell
winget install JanDeDobbeleer.OhMyPosh -s winget
```

### 2. Nerd Font

Install a Nerd Font so that icons render correctly in your terminal:

```powershell
oh-my-posh font install
```

Select **JetBrainsMono NF** (Cove variant), then set it as the font in Windows Terminal:
`Settings → Profiles → Defaults → Appearance → Font face`.

### 4. tldr Pages

Community-maintained, simplified man pages:

```powershell
winget install tldr
```

---

## Profile Configuration

The full profile is available in [`Microsoft.PowerShell_profile.ps1`](./Microsoft.PowerShell_profile.ps1) — copy its content directly into your profile:

```powershell
code $PROFILE
```

Or apply it in one command:

```powershell
Invoke-WebRequest -Uri "<RAW_FILE_URL>" -OutFile $PROFILE
```

---

### Profile contents

```powershell
# ── Prompt ────────────────────────────────────────────────────────────────────

# Initialize Oh My Posh with a custom theme
oh-my-posh init pwsh --config ~/.config/ohmyposh/config.omp.toml | Invoke-Expression

# ── PSReadLine ────────────────────────────────────────────────────────────────

# Install if needed: Install-Module -Scope CurrentUser PSReadLine -Force
Import-Module PSReadLine

# Show a navigable menu of all options when pressing Tab
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete

# Navigate history with arrow keys, matching the current input
Set-PSReadLineOption -HistorySearchCursorMovesToEnd
Set-PSReadLineKeyHandler -Key UpArrow   -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

# Inline suggestions and tooltips
Set-PSReadLineOption -ShowToolTips
Set-PSReadLineOption -PredictionSource History

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
```

---

## Recommended Modules

| Module       | Purpose                         | Install command                                       |
|--------------|---------------------------------|-------------------------------------------------------|
| `PSReadLine` | Enhanced line editing & history | `Install-Module -Scope CurrentUser PSReadLine -Force` |
| `PSFzf`      | Fuzzy finder integration        | `Install-Module -Scope CurrentUser PSFzf -Force`      |

---

See [ohmyposh Configurator](https://jamesmontemagno.github.io/ohmyposh-configurator/) to edit your theme.

## Result

Once configured, your terminal will feature:

- **A custom prompt** powered by Oh My Posh
- **Fuzzy search** over files and command history (`Ctrl+T` / `Ctrl+R`)
- **Intelligent autocompletion** with Tab and arrow-key history navigation
- **Inline suggestions** based on your history
- **Quick navigation aliases** to your most-used directories
