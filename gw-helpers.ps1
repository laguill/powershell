# ==============================================================
#  Git Worktree helpers -- structure catégorisée
#
#  Categories supportées :
#    feature  -> features/[nom]
#    fix      -> fixes/[nom]
#    hotfix   -> hotfixes/[nom]
#    docs     -> docs/[nom]
#    release  -> releases/[nom]
#    (aucune) -> directement a la racine (ex: master, develop)
# ==============================================================

$GW_CATEGORIES = @{
    "feature" = "features"
    "fix"     = "fixes"
    "hotfix"  = "hotfixes"
    "docs"    = "docs"
    "release" = "releases"
}

function _gw_root {
    $gitDir = git rev-parse --git-common-dir 2>$null
    if (-not $gitDir) { throw "Pas dans un depot git." }
    Split-Path (Resolve-Path $gitDir) -Parent
}

function _gw_path {
    param(
        [string]$Name,
        [string]$Category = ""
    )
    $root = _gw_root
    if ($Category -and $GW_CATEGORIES.ContainsKey($Category)) {
        Join-Path (Join-Path $root $GW_CATEGORIES[$Category]) $Name
    }
    else {
        Join-Path $root $Name
    }
}

function _gw_detect_category {
    param([string]$Branch)
    foreach ($key in $GW_CATEGORIES.Keys) {
        if ($Branch -match "^$key[/-]") { return $key }
    }
    return ""
}

# gwnew [branche] [-From [ref]] [-NoInstall]
# Cree un worktree. La catégorie est déduite du préfixe de branche.
# Lance automatiquement "uv run just install-dev" apres creation.
# Utiliser -NoInstall pour sauter cette etape.
# Exemples :
#   gwnew feature/auth           -> features/feature-auth/  + install-dev
#   gwnew fix/bug-123            -> fixes/fix-bug-123/       + install-dev
#   gwnew hotfix/security        -> hotfixes/hotfix-security/ + install-dev
#   gwnew develop -NoInstall     -> develop/  (sans installer)
function gwnew {
    param(
        [Parameter(Mandatory)][string]$Branch,
        [string]$From = "develop",
        [switch]$NoInstall
    )

    $category = _gw_detect_category $Branch
    $safeName = $Branch -replace '[/\\]', '-'
    $path = _gw_path $safeName $category

    if (Test-Path $path) {
        Write-Error "Le dossier existe deja : $path"
        return
    }

    $parent = Split-Path $path -Parent
    New-Item -ItemType Directory -Force -Path $parent | Out-Null

    $branchExists = git branch --list $Branch
    if ($branchExists) {
        git worktree add $path $Branch
    }
    else {
        git worktree add -b $Branch $path $From
        Write-Host "  Branche creee depuis : $From" -ForegroundColor DarkGray
    }

    $worktreeOk = $LASTEXITCODE   # sauvegarder avant que --set-upstream l'ecrase

    # Configurer le tracking (peut echouer si branche pas encore sur remote, c'est normal)
    git -C $path branch --set-upstream-to=origin/$Branch $Branch 2>$null

    if ($worktreeOk -ne 0) { return }   # verifier le resultat de worktree add, pas du tracking

    Write-Host "Worktree cree : $path" -ForegroundColor Green

    # Copie des fichiers d'environnement depuis develop
    $devPath = _gw_path "develop"
    @(".env", ".env.local", ".env.development") | ForEach-Object {
        $src = Join-Path $devPath $_
        if (Test-Path $src) {
            Copy-Item $src (Join-Path $path $_) -Force
            Write-Host "  Copie : $_ (depuis develop)" -ForegroundColor DarkGray
        }
    }

    # Installation de l'environnement virtuel uv
    if (-not $NoInstall) {
        Write-Host "  Installation de l'environnement (uv run just install-dev)..." -ForegroundColor DarkGray
        Push-Location $path
        try {
            uv run just install-dev
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  .venv pret dans : $path" -ForegroundColor DarkGray
            }
            else {
                Write-Warning "install-dev a echoue (code $LASTEXITCODE). Relancer manuellement : gwrun $Branch uv run just install-dev"
            }
        }
        finally {
            Pop-Location
        }
    }
}

# gwrm [branche] [-DeleteBranch]
# Supprime un worktree (et optionnellement la branche locale).
function gwrm {
    param(
        [Parameter(Mandatory)][string]$Branch,
        [switch]$DeleteBranch
    )

    $category = _gw_detect_category $Branch
    $safeName = $Branch -replace '[/\\]', '-'
    $path = _gw_path $safeName $category

    git worktree remove $path --force
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Worktree supprime : $path" -ForegroundColor Green
        if ($DeleteBranch) {
            git branch -d $Branch
            Write-Host "  Branche supprimee : $Branch" -ForegroundColor DarkGray
        }
    }
}

# gwcd [branche]
# Se déplace dans le dossier du worktree.
function gwcd {
    param([Parameter(Mandatory)][string]$Branch)

    $category = _gw_detect_category $Branch
    $safeName = $Branch -replace '[/\\]', '-'
    $path = _gw_path $safeName $category

    if (-not (Test-Path $path)) {
        $path = _gw_path $Branch
    }

    if (Test-Path $path) {
        Set-Location $path
    }
    else {
        Write-Error "Worktree introuvable : $path"
    }
}

# gwls
# Liste tous les worktrees actifs avec leur branche git.
function gwls {
    $root = _gw_root
    Write-Host ""
    Write-Host "  BRANCHE GIT                         DOSSIER" -ForegroundColor DarkGray
    Write-Host "  " + ("-" * 70) -ForegroundColor DarkGray

    $lines = git worktree list --porcelain
    $wPath = ""; $branch = ""

    foreach ($line in $lines) {
        if ($line -match "^worktree (.+)") {
            $wPath = $Matches[1]
        }
        elseif ($line -match "^branch refs/heads/(.+)") {
            $branch = $Matches[1]
        }
        elseif ($line -eq "") {
            if ($wPath) {
                $rel = $wPath -replace [regex]::Escape($root.Replace("\", "/")), "" -replace "^[\\/]", ""
                if ($rel -eq ".git" -or $rel -eq "") {
                    Write-Host ("  {0,-35}  {1}" -f "(bare)", $root) -ForegroundColor DarkGray
                } else {
                    Write-Host ("  {0,-35}  {1}" -f $branch, $rel) -ForegroundColor Cyan
                }
            }
            $wPath = ""; $branch = ""
        }
    }
    # Dernier bloc (pas de ligne vide finale)
    if ($wPath) {
        $rel = $wPath -replace [regex]::Escape($root.Replace("\", "/")), "" -replace "^[\\/]", ""
        if ($rel -eq ".git" -or $rel -eq "") {
            Write-Host ("  {0,-35}  {1}" -f "(bare)", $root) -ForegroundColor DarkGray
        } else {
            Write-Host ("  {0,-35}  {1}" -f $branch, $rel) -ForegroundColor Cyan
        }
    }
    Write-Host ""
    Write-Host "  Utiliser le nom de BRANCHE GIT avec gwnew/gwcd/gwopen/gwrm/gwrun" -ForegroundColor DarkGray
    Write-Host ""
}

# gwrun [branche] [commande...]
# Execute une commande dans le dossier du worktree.
function gwrun {
    param(
        [Parameter(Mandatory)][string]$Branch,
        [Parameter(Mandatory, ValueFromRemainingArguments)][string[]]$Command
    )

    $category = _gw_detect_category $Branch
    $safeName = $Branch -replace '[/\\]', '-'
    $path = _gw_path $safeName $category

    if (-not (Test-Path $path)) {
        Write-Error "Worktree introuvable : $path"
        return
    }

    Push-Location $path
    try {
        & $Command[0] $Command[1..($Command.Length - 1)]
    }
    finally {
        Pop-Location
    }
}

# gwcopy [branche] [fichiers...]
# Copie des fichiers depuis develop vers un worktree.
function gwcopy {
    param(
        [Parameter(Mandatory)][string]$Branch,
        [string[]]$Files = @(".env", ".env.local")
    )

    $category = _gw_detect_category $Branch
    $safeName = $Branch -replace '[/\\]', '-'
    $dest = _gw_path $safeName $category
    $src = _gw_path "develop"

    foreach ($f in $Files) {
        $srcFile = Join-Path $src $f
        if (Test-Path $srcFile) {
            Copy-Item $srcFile (Join-Path $dest $f) -Force
            Write-Host "Copie : $f -> $dest" -ForegroundColor DarkGray
        }
        else {
            Write-Warning "Fichier introuvable dans develop : $f"
        }
    }
}

# gwopen [branche]
# Ouvre le worktree dans VS Code.
function gwopen {
    param([Parameter(Mandatory)][string]$Branch)

    $category = _gw_detect_category $Branch
    $safeName = $Branch -replace '[/\\]', '-'
    $path = _gw_path $safeName $category

    if (Test-Path $path) {
        code $path
    }
    else {
        Write-Error "Worktree introuvable : $path"
    }
}

# gwsave [branche] [-Message "texte"]
# Commit tout le travail en cours (WIP) et pousse sur le remote.
# Le commit est préfixe WIP: pour être facilement identifiable.
function gwsave {
    param(
        [Parameter(Mandatory)][string]$Branch,
        [string]$Message = ""
    )

    $category = _gw_detect_category $Branch
    $safeName = $Branch -replace '[/\\]', '-'
    $path = _gw_path $safeName $category

    if (-not (Test-Path $path)) {
        Write-Error "Worktree introuvable : $path"
        return
    }

    Push-Location $path
    try {
        $status = git status --porcelain
        if (-not $status) {
            Write-Host "Rien a sauvegarder dans $Branch" -ForegroundColor DarkGray
            return
        }

        $date = Get-Date -Format "yyyy-MM-dd HH:mm"
        $wipMsg = if ($Message) { "WIP: $Message [$date]" } else { "WIP: travail en cours [$date]" }

        git add --all
        git commit --message $wipMsg
        git push --set-upstream origin $Branch

        if ($LASTEXITCODE -eq 0) {
            Write-Host "Sauvegarde : $wipMsg" -ForegroundColor Green
            Write-Host "  Pousse sur origin/$Branch" -ForegroundColor DarkGray
        }
    }
    finally {
        Pop-Location
    }
}

# gwresume [branche]
# Annule le dernier commit WIP et remet les fichiers en zone de travail.
# Ne fait rien si le dernier commit n'est pas un WIP.
function gwresume {
    param(
        [Parameter(Mandatory)][string]$Branch
    )

    $category = _gw_detect_category $Branch
    $safeName = $Branch -replace '[/\\]', '-'
    $path = _gw_path $safeName $category

    if (-not (Test-Path $path)) {
        Write-Error "Worktree introuvable : $path"
        return
    }

    Push-Location $path
    try {
        $lastMsg = git log -1 --format="%s"

        if ($lastMsg -notmatch "^WIP:") {
            Write-Host "Dernier commit non WIP : $lastMsg" -ForegroundColor DarkGray
            Write-Host "Rien a annuler." -ForegroundColor DarkGray
            return
        }

        git reset HEAD~1
        Write-Host "WIP commit annule : $lastMsg" -ForegroundColor Green
        Write-Host "  Les fichiers sont de retour dans l'espace de travail." -ForegroundColor DarkGray
    }
    finally {
        Pop-Location
    }
}
