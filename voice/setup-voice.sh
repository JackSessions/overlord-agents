#!/usr/bin/env bash
# ==================================================
#  setup-voice.sh — build the Overlord soundboard from YOUR OWN audio clips
#  You provide the audio (your own recordings or audio you have the rights to use).
#  This transcribes it with Whisper and slices it into a searchable library.
#
#  Usage:  ./setup-voice.sh /path/to/your-audio.mp3 [more.mp3 ...]
#  Needs:  ffmpeg, jq, and whisper-ctranslate2  (pip/uv install whisper-ctranslate2)
# ==================================================
set -euo pipefail
LIB="$HOME/.local/share/overlord/library"
TR="$HOME/.local/share/overlord/transcript"
mkdir -p "$LIB" "$TR"

command -v whisper-ctranslate2 >/dev/null || { echo "Install whisper-ctranslate2 first (uv tool install whisper-ctranslate2)"; exit 1; }
command -v ffmpeg >/dev/null || { echo "ffmpeg required"; exit 1; }

[[ $# -eq 0 ]] && { echo "usage: ./setup-voice.sh <audio1> [audio2 ...]"; exit 1; }

idx=0
: > "$LIB/index.tsv"
for AUDIO in "$@"; do
  [[ ! -f "$AUDIO" ]] && { echo "skip (not found): $AUDIO"; continue; }
  echo ">> Transcribing $(basename "$AUDIO") ..."
  whisper-ctranslate2 "$AUDIO" --model base --language en --device cpu \
    --output_format json --output_dir "$TR" --vad_filter True >/dev/null 2>&1
  JSON="$TR/$(basename "${AUDIO%.*}").json"
  echo ">> Slicing phrases ..."
  python3 - "$AUDIO" "$JSON" "$LIB" "$idx" <<'PY'
import json, re, subprocess, sys, os
audio, jsonf, lib, start_idx = sys.argv[1], sys.argv[2], sys.argv[3], int(sys.argv[4])
segs = json.load(open(jsonf))["segments"]
rows=[]
for i, s in enumerate(segs):
    text=s["text"].strip(); dur=max(0.6, s["end"]-s["start"])
    if dur>8: continue
    slug=re.sub(r'[^a-z0-9]+','_',text.lower()).strip('_')[:40] or f"line{i}"
    fn=f"{start_idx+i:04d}_{slug}.wav"; fo=max(0.1,dur-0.25)
    subprocess.run(["ffmpeg","-y","-ss",str(s["start"]),"-t",str(dur),"-i",audio,
        "-af",f"afade=t=in:d=0.05,afade=t=out:st={fo}:d=0.2,loudnorm=I=-16:TP=-1.5:LRA=11",
        "-ar","48000",os.path.join(lib,fn)],capture_output=True)
    rows.append(f"{fn}\t{text}")
open(os.path.join(lib,"index.tsv"),"a").write("\n".join(rows)+"\n")
print(f"   added {len(rows)} phrases")
PY
  idx=$((idx+500))
done
sed -i '/^$/d' "$LIB/index.tsv"
echo ">> Done. $(wc -l < "$LIB/index.tsv") lines in your library."
echo "   Try:  overlord-find --all   |   overlord-say ready"
