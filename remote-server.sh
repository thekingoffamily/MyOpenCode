#!/usr/bin/env sh
# Start opencode as a background server on a Linux/macOS host,
# then connect to it from any machine over SSH with a browser GUI.
#
# Usage:
#   ./remote-server.sh            # workdir = $HOME
#   ./remote-server.sh /srv/proj  # workdir = specific project
#
# Local machine (Windows / Linux / macOS):
#   ssh -N -L 127.0.0.1:42042:127.0.0.1:42042 user@host
#   open http://127.0.0.1:42042
#
set -e

PORT="${PORT:-42042}"
SESSION="${SESSION:-brainai}"
DIR="${1:-$HOME}"

# ensure opencode installed (also sets up aiTunnel config)
if ! command -v opencode >/dev/null 2>&1 && [ ! -x "$HOME/.opencode/bin/opencode" ]; then
  echo "[setup] installing opencode ..."
  curl -fsSL https://opencode.ai/install | bash
fi

# Always use an ABSOLUTE path: the tmux shell does not inherit the interactive
# PATH (which normally includes ~/.opencode/bin), so a bare `opencode` would
# fail with "command not found" and kill the session silently.
if [ -x "$HOME/.opencode/bin/opencode" ]; then
  OC="$HOME/.opencode/bin/opencode"
elif command -v opencode >/dev/null 2>&1; then
  OC="$(command -v opencode)"
else
  echo "ERROR: opencode binary not found (tried \$HOME/.opencode/bin/opencode and PATH)."
  exit 1
fi

if ! command -v tmux >/dev/null 2>&1; then
  echo "ERROR: tmux not found. Install it:  apt install tmux  (or:  yum/dnf install tmux)"
  exit 1
fi

echo "[start] freeing port $PORT (stale server keeps old config) ..."
fuser -k "${PORT}/tcp" 2>/dev/null || true
sleep 1

echo "[start] killing old session '$SESSION' if any ..."
tmux kill-session -t "$SESSION" 2>/dev/null || true

echo "[start] launching: $OC serve --hostname 127.0.0.1 --port $PORT (workdir: $DIR)"
tmux new-session -d -s "$SESSION" -c "$DIR" "$OC serve --hostname 127.0.0.1 --port $PORT"

sleep 3
echo
echo "============================================================"
tmux ls
echo "============================================================"
if command -v curl >/dev/null 2>&1; then
  echo
  curl -s -o /dev/null -w "  HTTP check: http://127.0.0.1:$PORT/ -> %{http_code}\n" "http://127.0.0.1:$PORT/" || true
fi
echo
echo "  Server is up on 127.0.0.1:$PORT (GUI + HTTP API)."
echo
echo "  From your PC connect the tunnel and open the browser:"
echo "    ssh -N -L 127.0.0.1:$PORT:127.0.0.1:$PORT <user>@<host>"
echo "    open http://127.0.0.1:$PORT"
echo
echo "  Views/logs:  tmux attach -t $SESSION     (detach: Ctrl+B then D)"
echo "  Stop:        tmux kill-session -t $SESSION"
echo "  Optional pw: run with 'export OPENCODE_SERVER_PASSWORD=mypass' before starting."
echo