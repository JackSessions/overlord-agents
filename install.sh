#!/usr/bin/env bash
# ==================================================
#  Overlord installer — symlinks the agents into ~/.local/bin
# ==================================================
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
BIN="$HOME/.local/bin"
mkdir -p "$BIN" "$HOME/.config/overlord" "$HOME/.local/share/overlord"

echo ">> Linking agents into $BIN"
for f in "$HERE"/bin/*; do
  ln -sf "$f" "$BIN/$(basename "$f")"
  echo "   + $(basename "$f")"
done

# Seed cloud.env if missing (optional — agents work locally without it)
if [[ ! -f "$HOME/.config/overlord/cloud.env" ]]; then
  cp "$HERE/cloud.env.example" "$HOME/.config/overlord/cloud.env"
  chmod 600 "$HOME/.config/overlord/cloud.env"
  echo ">> Seeded ~/.config/overlord/cloud.env (edit it to add your API key, or leave it for local-only)"
fi

cat <<'EOF'

>> Installed. Make sure ~/.local/bin is on your PATH.

   Next steps:
   1. (local brain)  Install Ollama + a model:  ollama pull qwen2.5-coder:3b
   2. (cloud brain, optional)  Edit ~/.config/overlord/cloud.env with your API key
   3. (voice, optional)  ./voice/setup-voice.sh /path/to/your-own-audio.mp3
   4. Run:  overlord-help

   Suggested aliases (add to your shell rc):
     alias ov=overlord  ovs=overlord-sys  ovc=overlord-code
     alias ovf=overlord-find  ovh=overlord-help
EOF
