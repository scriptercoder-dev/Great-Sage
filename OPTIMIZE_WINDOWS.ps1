# ============================================================================
#  Great Sage - OPTIMIZE_WINDOWS.ps1
#  Applique automatiquement les optimisations "zero lag" cote environnement
#  Windows. N'importe QUOI dans le code Python de Great Sage : ce script agit
#  uniquement sur le systeme (Defender, WebView2, plan d'alimentation).
#
#  A lancer EN ADMINISTRATEUR (clic droit > "Executer avec PowerShell" en
#  admin, ou : powershell -ExecutionPolicy Bypass -File OPTIMIZE_WINDOWS.ps1)
# ============================================================================

$ErrorActionPreference = "Continue"

function Section($title) {
    Write-Host ""
    Write-Host "=== $title ===" -ForegroundColor Cyan
}

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Ce script doit etre lance EN ADMINISTRATEUR pour les exclusions Defender." -ForegroundColor Yellow
    Write-Host "Clic droit sur le fichier > 'Executer avec PowerShell' (en admin)." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Il continue quand meme pour les etapes qui n'ont pas besoin d'admin..." -ForegroundColor Yellow
}

# ----------------------------------------------------------------------------
Section "1. Dossier de l'application"
# ----------------------------------------------------------------------------
$appDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Write-Host "Dossier detecte : $appDir"

$driveLetter = (Get-Item $appDir).PSDrive.Name
try {
    $vol = Get-Volume -DriveLetter $driveLetter -ErrorAction Stop
    $isSSD = $false
    $disk = Get-PhysicalDisk | Where-Object { (Get-Partition -DriveLetter $driveLetter -ErrorAction SilentlyContinue) -ne $null }
    if ($disk) { $isSSD = ($disk.MediaType -eq "SSD") }
    Write-Host "Lecteur $driveLetter : $($vol.FileSystemLabel)  (SSD detecte: $isSSD)"
    if (-not $isSSD) {
        Write-Host "  -> Tu es sur un disque dur classique (HDD). Le chargement de torch/CUDA" -ForegroundColor Yellow
        Write-Host "     (plusieurs Go de DLL) sera nettement plus lent que sur SSD." -ForegroundColor Yellow
    }
} catch {
    Write-Host "Impossible de determiner le type de disque, on continue." -ForegroundColor DarkGray
}

if ($appDir -match "OneDrive|Dropbox|Google ?Drive") {
    Write-Host "  -> ATTENTION : l'appli semble etre dans un dossier synchronise (cloud)." -ForegroundColor Red
    Write-Host "     Deplace le dossier hors de OneDrive/Dropbox/Drive pour de meilleures perfs." -ForegroundColor Red
}

# ----------------------------------------------------------------------------
Section "2. Exclusions Windows Defender"
# ----------------------------------------------------------------------------
if ($isAdmin) {
    try {
        Add-MpPreference -ExclusionPath $appDir -ErrorAction Stop
        Write-Host "OK : $appDir exclu du scan Defender en temps reel." -ForegroundColor Green
    } catch {
        Write-Host "Echec de l'exclusion Defender : $_" -ForegroundColor Red
    }

    # Exclut aussi les process (utile si l'exe est lance depuis plusieurs
    # emplacements pendant le dev/build).
    $exePath = Join-Path $appDir "GreatSage.exe"
    if (Test-Path $exePath) {
        try {
            Add-MpPreference -ExclusionProcess $exePath -ErrorAction Stop
            Write-Host "OK : GreatSage.exe exclu par nom de process." -ForegroundColor Green
        } catch {
            Write-Host "Echec de l'exclusion process : $_" -ForegroundColor Red
        }
    }
} else {
    Write-Host "Ignore (pas admin). Relance en admin pour cette etape." -ForegroundColor Yellow
}

# ----------------------------------------------------------------------------
Section "3. WebView2 Runtime"
# ----------------------------------------------------------------------------
$webview2Key = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}"
if (Test-Path $webview2Key) {
    $ver = (Get-ItemProperty -Path $webview2Key -ErrorAction SilentlyContinue).pv
    Write-Host "OK : WebView2 Evergreen Runtime deja installe (version $ver)." -ForegroundColor Green
} else {
    Write-Host "WebView2 non detecte. Sans lui, le premier lancement le telecharge" -ForegroundColor Yellow
    Write-Host "et l'installe lui-meme -> gros delai au premier demarrage." -ForegroundColor Yellow
    Write-Host "Installe-le maintenant : https://go.microsoft.com/fwlink/p/?LinkId=2124703" -ForegroundColor Yellow
}

# ----------------------------------------------------------------------------
Section "4. GPU NVIDIA"
# ----------------------------------------------------------------------------
$nvidiaSmi = Get-Command nvidia-smi -ErrorAction SilentlyContinue
if ($nvidiaSmi) {
    $gpuInfo = & nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv,noheader 2>$null
    Write-Host "GPU detecte : $gpuInfo" -ForegroundColor Green
} else {
    Write-Host "nvidia-smi introuvable : pas de GPU NVIDIA detecte, ou drivers absents." -ForegroundColor Yellow
    Write-Host "F5-TTS (la voix) tournera en CPU, ce qui est nettement plus lent." -ForegroundColor Yellow
}

# ----------------------------------------------------------------------------
Section "5. Plan d'alimentation Windows"
# ----------------------------------------------------------------------------
try {
    $currentPlan = (powercfg /getactivescheme)
    Write-Host "Plan actuel : $currentPlan"
    if ($currentPlan -notmatch "Performances elevees|High performance|Ultimate") {
        Write-Host "  -> Un plan 'Equilibre'/'Economie' peut brider le CPU/GPU sous charge." -ForegroundColor Yellow
        Write-Host "     Passe sur 'Performances elevees' dans les Parametres d'alimentation" -ForegroundColor Yellow
        Write-Host "     si tu veux le max de perf pendant que Great Sage + un jeu tournent." -ForegroundColor Yellow
    } else {
        Write-Host "OK : deja sur un plan haute performance." -ForegroundColor Green
    }
} catch {
    Write-Host "Impossible de lire le plan d'alimentation." -ForegroundColor DarkGray
}

# ----------------------------------------------------------------------------
Section "6. Cache de demarrage Great Sage"
# ----------------------------------------------------------------------------
$cachePath = Join-Path $env:LOCALAPPDATA "GreatSage\startup_ready.json"
if (Test-Path $cachePath) {
    $age = (Get-Date) - (Get-Item $cachePath).LastWriteTime
    Write-Host "Cache de preflight present, age: $([math]::Round($age.TotalHours,1))h (valide 24h)." -ForegroundColor Green
} else {
    Write-Host "Pas de cache de preflight trouve : le PROCHAIN lancement fera les" -ForegroundColor Yellow
    Write-Host "verifications completes (Ollama, GPU, WebView2...) une seule fois," -ForegroundColor Yellow
    Write-Host "puis les lancements suivants seront rapides pendant 24h." -ForegroundColor Yellow
}

# ----------------------------------------------------------------------------
Section "Termine"
# ----------------------------------------------------------------------------
Write-Host "Optimisations systeme appliquees. Relance GreatSage.exe pour tester." -ForegroundColor Cyan
Write-Host ""
Read-Host "Appuie sur Entree pour fermer"
