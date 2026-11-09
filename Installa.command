#!/bin/bash
cd "$(dirname "$0")"
APP="$HOME/Applications/MXF Conforme.app"
mkdir -p "$HOME/Applications"; rm -rf "$APP"
osacompile -o "$APP" droplet.applescript || { echo "Errore nella creazione dell'app"; read -r; exit 1; }
cp mxf_conforme.sh "$APP/Contents/Resources/"; chmod +x "$APP/Contents/Resources/mxf_conforme.sh"
xattr -cr "$APP" 2>/dev/null
command -v ffmpeg >/dev/null || [ -x /opt/homebrew/bin/ffmpeg ] || echo "ATTENZIONE: manca FFmpeg. Scrivi: brew install ffmpeg"
open -R "$APP"
echo "Fatto. L'app è in Applicazioni (cartella personale). Trascina l'MXF sull'icona."
