# PowerShell Configuration

This guide will help you configure PowerShell inspired by [this blog post](https://hamidmosalla.com/2022/12/26/how-to-customize-windows-terminal-and-powershell-using-fzf-neovim-and-beautify-it-with-oh-my-posh/).
## Install Zoxide
```powershell
winget install ajeetdsouza.zoxide
````

## install oh-my-posh
```powershell
winget install JanDeDobbeleer.OhMyPosh -s winget
````

## install nerd font
```powershell
oh-my-posh font install 
````
## select cascady cove and change the font in powershell

## edit powershell profile to use oh-my-posh
```powershell
notepad $PROFILE
````

## Initialize Oh My Posh with the theme which we chosen
```powershell
oh-my-posh init pwsh --config ""$env:POSH_THEMES_PATH\kushal.omp.json" | Invoke-Expression
````

## Install terminal file manager
```powershell
winget install --id=antonmedv.walk  -e
````
## Edit Your Profile to Look Like This
```powershell
# Initialize Oh My Posh with the theme which we chosen
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\kushal.omp.json" | Invoke-Expression

# Set some useful Alias to shorten typing and save some key stroke 
Set-Alias ll ls 
Set-Alias grep findstr

# Set Some Option for PSReadLine to show the history of our typed commands
Set-PSReadLineOption -PredictionSource History 
Set-PSReadLineOption -PredictionViewStyle ListView 
Set-PSReadLineOption -EditMode Windows 


# replace 'Ctrl+t' and 'Ctrl+r' with your preferred bindings:
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'

# Utility Command that tells you where the absolute path of commandlets are 
function which ($command) { 
 Get-Command -Name $command -ErrorAction SilentlyContinue | 
 Select-Object -ExpandProperty Path -ErrorAction SilentlyContinue 
} 

# ----------------------------------------Functions ----------------------------------------------

# move in selected directory using walk
function lk() {cd $(walk --icons $args)}

# list json files in a folder
function Get-JsonFileList {
    param(
        [Parameter(Mandatory=$false)]
        [string]$Path = "."
    )

    Get-ChildItem -Path $Path -Filter "*.json" | ForEach-Object {
        $_.BaseName >> json_file_list.txt
    }
}

````
