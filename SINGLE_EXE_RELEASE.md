# GREAT SAGE — version single EXE

Cette version prépare un build Windows où l'utilisateur final reçoit **un seul fichier `GreatSage.exe`**.

## Ce qui est intégré

- HUD et interface
- WebView / WebView2 côté application
- STT faster-whisper + dépendances
- TTS F5-TTS + dépendances
- assets audio et voix de référence
- overlay transparent Qt
- logique de détection GPU
- fallback CPU pour STT/TTS si CUDA n'est pas disponible

## Ce qui reste téléchargé automatiquement

Les modèles IA très volumineux ne sont pas copiés dans chaque EXE :

- modèle Ollama configuré
- modèles Whisper
- poids F5-TTS / Vocos

Ils sont récupérés à la demande et conservés dans les caches utilisateur.

## Build

Sur Windows :

```powershell
.\\BUILD_EXE_WINDOWS.bat
```

Le résultat final est :

```text
dist\\GreatSage.exe
```

Le dossier `GreatSageOverlay` sert uniquement pendant le build puis est supprimé après l'intégration dans l'EXE.

## GPU

Le programme essaie automatiquement CUDA/NVIDIA quand disponible. Si CUDA n'est pas utilisable, STT et TTS peuvent fonctionner en CPU. Cela évite de bloquer l'application sur une machine AMD, Intel ou sans GPU compatible CUDA.

## STT dans le EXE

Le build collecte explicitement `faster_whisper`, ses sous-modules et ses données, notamment le modèle VAD Silero. Si CUDA échoue au chargement de Whisper, le moteur retente automatiquement en CPU.

## Fast startup

The Windows EXE now uses a fast-start path after a successful launch:
- recent preflight HTTP/hardware checks are cached for 24 hours;
- the pywebview window is created before Ollama/ChatEngine/F5-TTS initialization;
- heavy backend imports and voice initialization run on a background thread;
- the page retries its local WebSocket connection while the backend becomes ready.

Set `GREAT_SAGE_FORCE_PREFLIGHT=1` to force a full prerequisite check during debugging.

Note: a PyInstaller `--onefile` application necessarily extracts its bundled native libraries (including PyTorch) at process start. This optimization removes the additional Python/backend wait; it cannot remove the OS-level one-file extraction cost without switching to an onedir installation.
