"""Diagnostic rapide : ou sont (ou ne sont pas) les DLL CUDA dont
faster-whisper/ctranslate2 a besoin sur cette machine.

Lance-le avec le MEME python que celui qui fait tourner l'appli :
    py check_cuda_dlls.py

Il n'installe rien, ne modifie rien - il liste juste ce qui existe deja.
"""
import os
import sys

print(f"Python: {sys.version}")
print(f"Executable: {sys.executable}")
print()

targets = [
    "cublas64_12.dll", "cublas64_11.dll", "cublasLt64_12.dll",
    "cudnn64_9.dll", "cudnn64_8.dll",
    "cudnn_ops64_9.dll", "cudnn_cnn64_9.dll", "cudnn_graph64_9.dll",
    "cudnn_engines_runtime_compiled64_9.dll", "cudnn_heuristic64_9.dll",
    "cudart64_12.dll",
]

site_packages = os.path.dirname(os.path.dirname(os.__file__))
try:
    import site
    roots = list(set(site.getsitepackages() + [site.getusersitepackages()]))
except Exception:
    roots = [site_packages]

print("Dossiers site-packages scannes :")
for r in roots:
    print(f"  - {r}")
print()

found = {}
for root in roots:
    if not os.path.isdir(root):
        continue
    for dirpath, dirnames, filenames in os.walk(root):
        # ne descend pas dans les paquets non pertinents pour aller plus vite
        base = os.path.basename(dirpath).lower()
        for fn in filenames:
            if fn.lower() in [t.lower() for t in targets]:
                found.setdefault(fn, []).append(os.path.join(dirpath, fn))

print("=== Resultat ===")
for t in targets:
    matches = found.get(t) or [m for k, v in found.items() if k.lower() == t.lower() for m in v]
    if matches:
        print(f"[TROUVE]   {t}")
        for m in matches:
            print(f"             -> {m}")
    else:
        print(f"[ABSENT]   {t}")

print()
try:
    import torch
    print(f"torch: {torch.__version__}  cuda dispo: {torch.cuda.is_available()}")
    if torch.cuda.is_available():
        print(f"  GPU: {torch.cuda.get_device_name(0)}")
    print(f"  torch compile avec CUDA: {torch.version.cuda}")
except Exception as e:
    print(f"torch: impossible a importer ({e})")

try:
    import ctranslate2
    print(f"ctranslate2: {ctranslate2.__version__}")
except Exception as e:
    print(f"ctranslate2: impossible a importer ({e})")

print()
print("Si cublas64_12.dll est ABSENT partout ci-dessus, la solution directe est :")
print("  py -m pip install nvidia-cublas-cu12 nvidia-cudnn-cu12")
print("(en gardant la meme version majeure CUDA que ton torch, vu ci-dessus)")
