#!/usr/bin/env sh
# opencode + aiTunnel quick install (Linux / macOS)
set -e

echo
echo "  opencode + aiTunnel quick install (Linux/macOS)"
echo

# ------------------------------------------------------------ 1) opencode
OC=""
if command -v opencode >/dev/null 2>&1; then
  OC="opencode"
elif [ -x "$HOME/.opencode/bin/opencode" ]; then
  OC="$HOME/.opencode/bin/opencode"
else
  echo "[1/3] Installing opencode..."
  curl -fsSL https://opencode.ai/install | sh
  OC="$HOME/.opencode/bin/opencode"
fi
echo "[1/3] opencode: $($OC --version)"

# ------------------------------------------------------------ 2) config
cfg_dir="$HOME/.config/opencode"
dst="$cfg_dir/opencode.json"
src="$(cd "$(dirname "$0")" && pwd)/opencode.json"
mkdir -p "$cfg_dir"

if [ -f "$dst" ] && grep -q '"aitunnel"' "$dst"; then
  echo "[2/3] aiTunnel provider already present in $dst"
else
  if command -v node >/dev/null 2>&1; then
    echo "[2/3] Merging aiTunnel into $dst ..."
    node "$(dirname "$0")/install-merge.js" "$src" "$dst"
  else
    echo "[2/3] Writing new config to $dst ..."
    cp "$src" "$dst"
  fi
fi

# ------------------------------------------------------------ 3) key
if [ -n "$AITUNNEL_API_KEY" ]; then
  echo "[3/3] AITUNNEL_API_KEY is set. Good."
elif grep -q "AITUNNEL_API_KEY" "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile" 2>/dev/null; then
  echo "[3/3] AITUNNEL_API_KEY found in shell rc."
else
  echo "[3/3] Add your aiTunnel key ONE time:"
  echo "       echo 'export AITUNNEL_API_KEY=sk-aiTunnel-xxxxxxxx' >> ~/.bashrc"
  echo "       source ~/.bashrc"
fi

echo
echo "============================================================"
echo "  DONE. Now run:   opencode"
echo "  Then in the app:  /models  -> choose  aitunnel/..."
echo "  Default model: aitunnel/auto   Small: aitunnel/deepseek-v4-flash"
echo "  For servers (browser GUI over SSH):  ./remote-server.sh"
echo "============================================================"
echo