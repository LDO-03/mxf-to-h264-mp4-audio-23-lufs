#!/bin/bash
# Converte un video (MXF) in MP4 conforme: H.264 1280x720, ~3 Mbps, AAC stereo, -23 LUFS.
# Audio: solo la traccia 1 (A1), copiata su sinistra e destra. Uso: mxf_conforme.sh input
# Esito: ultima riga stdout = resoconto. Codici: 0 ok, 2 errore, 3 traccia A1 silenziosa.
set -uo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:/opt/local/bin:$PATH"
IN="$1"
command -v ffmpeg >/dev/null || { echo "FFmpeg non trovato. Apri Terminale e scrivi: brew install ffmpeg"; exit 2; }
[ -f "$IN" ] || { echo "File non trovato: $IN"; exit 2; }
DIR="$(dirname "$IN")"; BASE="$(basename "${IN%.*}")"
OUT="$DIR/${BASE}_WEC_Conforme.mp4"; n=2
while [ -e "$OUT" ]; do OUT="$DIR/${BASE}_WEC_Conforme_$n.mp4"; n=$((n+1)); done
[ -w "$DIR" ] || OUT="$HOME/Movies/${BASE}_WEC_Conforme.mp4"; mkdir -p "$(dirname "$OUT")"
TMP="$(mktemp -d)"; PASSLOG="$TMP/passlog"; trap 'rm -rf "$TMP"' EXIT
LOG="$HOME/Library/Logs/MXF_Conforme.log"; mkdir -p "$(dirname "$LOG")"
ff() { ffmpeg -nostdin -hide_banner "$@"; }

ff -v error -i "$IN" -map 0:a:0 -t 1 -f null - 2>/dev/null || { echo "Nessuna traccia audio trovata in $(basename "$IN")"; exit 2; }
DURSEC=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$IN" 2>/dev/null | cut -d. -f1)

PAN="pan=stereo|c0=c0|c1=c0"
# traccia A1 silenziosa?
MAXV=$(ff -i "$IN" -map 0:a:0 -vn -af volumedetect -f null - 2>&1 | awk '/max_volume:/{print $(NF-1)}' | tail -1)
if [ -z "$MAXV" ] || awk "BEGIN{exit !($MAXV < -50)}"; then
  echo "La traccia audio 1 (A1) è silenziosa in $(basename "$IN"): non ho creato nulla. Controlla dove sta il servizio."; exit 3
fi

MEAS=$(ff -i "$IN" -map 0:a:0 -vn -af "$PAN,loudnorm=I=-23:TP=-2:LRA=11:print_format=json" -f null - 2>&1)
jv() { echo "$MEAS" | awk -F'"' -v k="$1" '$2==k{print $4}' | tail -1; }
MI=$(jv input_i); MTP=$(jv input_tp); MLRA=$(jv input_lra); MTH=$(jv input_thresh); MOFF=$(jv target_offset)
[ -n "$MI" ] && [ -n "$MOFF" ] || { echo "Misura del volume non riuscita (audio non leggibile)"; exit 2; }
AF="$PAN,loudnorm=I=-23:TP=-2:LRA=11:measured_I=$MI:measured_TP=$MTP:measured_LRA=$MLRA:measured_thresh=$MTH:offset=$MOFF:linear=true"
VF="scale=1280:720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2:black,setsar=1,format=yuv420p"
V="-c:v libx264 -profile:v high -preset slow -b:v 2800k -maxrate 2800k -bufsize 5600k"

{ ff -v error -y -i "$IN" -map 0:v:0 -vf "$VF" $V -pass 1 -passlogfile "$PASSLOG" -an -f null /dev/null && \
  ff -v error -y -i "$IN" -map 0:v:0 -map 0:a:0 -vf "$VF" $V -pass 2 -passlogfile "$PASSLOG" \
     -af "$AF" -c:a aac -b:a 192k -ar 48000 -movflags +faststart -map_metadata -1 "$OUT"; } >>"$LOG" 2>&1 \
  || { rm -f "$OUT"; echo "Codifica non riuscita (dettagli in $LOG)"; exit 2; }

# verifica finale
LUFS=$(ff -i "$OUT" -af ebur128=peak=true -f null - 2>&1 | grep -E "^[[:space:]]+I:" | tail -1 | awk '{print $2}')
TPK=$(ff -i "$OUT" -af ebur128=peak=true -f null - 2>&1 | grep -E "^[[:space:]]+Peak:" | tail -1 | awk '{print $2}')
SIZE=$(stat -f%z "$OUT" 2>/dev/null || stat -c%s "$OUT"); MB=$(awk "BEGIN{printf \"%.1f\", $SIZE/1048576}")
BR=$(ffprobe -v error -show_entries format=bit_rate -of csv=p=0 "$OUT" | awk '{printf "%.2f",$1/1000000}')
RES=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 "$OUT")
OK="✓"; WARN=""
awk "BEGIN{exit !($MB > 45)}" && { OK="⚠"; WARN="$WARN\nSUPERA 45 MB."; }
awk "BEGIN{d=$LUFS+23; exit !(d>0.5 || d<-0.5)}" && { OK="⚠"; WARN="$WARN\nLoudness fuori da -23 LUFS."; }
echo "$(date '+%F %T') $OUT ${MB}MB ${LUFS}LUFS" >> "$LOG"
printf '%s %s\n%s, %s Mbps, %s MB\nAudio: %s LUFS, picco %s dBTP (solo A1, stereo)\nDurata: %ss (non controllata)%b' \
  "$OK" "$(basename "$OUT")" "$RES" "$BR" "$MB" "$LUFS" "$TPK" "$DURSEC" "$WARN"
echo
exit 0
