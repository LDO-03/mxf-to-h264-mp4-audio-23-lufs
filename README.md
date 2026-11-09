# MXF → MP4 conforme (WEC, Mac)

Converte un video MXF in un MP4 conforme alle specifiche: H.264 1280×720, circa 3 Mbps, AAC stereo, audio a -23 LUFS.

## Requisiti
- macOS
- FFmpeg: `brew install ffmpeg`

## Installazione
1. Scarica o clona il repository.
2. Apri Terminale, scrivi `bash ` (con lo spazio), trascina dentro `Installa.command` e premi Invio.
3. Si crea l'app `MXF Conforme` in `~/Applications`.

## Uso
Trascina uno o più file MXF sull'icona. Accanto a ogni originale compare `NOME_WEC_Conforme.mp4`.

Regole applicate:
- Audio solo dalla traccia A1, copiata su sinistra e destra.
- Se A1 è silenziosa, non crea nulla e avvisa.
- Durata non controllata (riportata solo nel resoconto).

Registro: `~/Library/Logs/MXF_Conforme.log`
