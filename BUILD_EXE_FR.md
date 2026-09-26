# Build Great Sage - Windows

Le build produit un seul fichier : `dist\\GreatSage.exe`.

L'overlay Qt est construit séparément avec Python 3.11/PySide6 6.4.3 puis embarqué dans le EXE final. L'utilisateur n'a donc pas besoin d'un dossier `overlay`, de Python, de `requirements.txt` ou de DLL à copier manuellement.

Les modèles Whisper/F5-TTS et le modèle Ollama sont téléchargés à la demande car ils font plusieurs Go. Les préférences et la mémoire sont conservées dans `%LOCALAPPDATA%\\GreatSage`.

Le STT détecte CUDA lorsqu'il est disponible et passe automatiquement en CPU si le GPU n'est pas compatible.

Lancer `BUILD_EXE_WINDOWS.bat` depuis PowerShell avec :

```powershell
.\\BUILD_EXE_WINDOWS.bat
```
