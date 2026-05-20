#!/bin/sh
# Debounce: only one instance at a time; drop duplicate calls (e.g. from
# multiple monitor.added events firing in quick succession at startup).
exec 9>/tmp/hypr-monitor-sh.lock
flock -n 9 || exit 0

LAPTOP_OUTPUT="eDP-1"
LID_STATE_FILE="/proc/acpi/button/lid/LID/state"

read -r LS <"$LID_STATE_FILE"

case "$LS" in
*open)   hyprctl reload; sleep 0.5; systemctl --user restart waybar.service ;;
*closed)
  hyprctl eval "hl.monitor({output='${LAPTOP_OUTPUT}', disabled=true})"
  # Give Hyprland a moment, then migrate any orphaned workspaces to the
  # first active monitor so they are not stranded on the disabled output.
  sleep 0.5
  ACTIVE=$(hyprctl monitors -j | python3 -c \
    "import json,sys; ms=json.load(sys.stdin); print(next((m['name'] for m in ms if m['name']!='${LAPTOP_OUTPUT}'),''))")
  if [ -n "$ACTIVE" ]; then
    python3 - "$LAPTOP_OUTPUT" "$ACTIVE" <<'PYEOF'
import json, sys, subprocess
disabled, target = sys.argv[1], sys.argv[2]
raw = subprocess.check_output(["hyprctl", "workspaces", "-j"])
ws_list = json.loads(raw)
for ws in ws_list:
    if ws.get("monitor", "") in ("", disabled):
        ws_id = str(ws["id"])
        subprocess.run(
            ["hyprctl", "eval",
             f"hl.dispatch(hl.dsp.workspace.move({{workspace = {ws_id}, monitor = '{target}'}}))"],
            check=False,
        )
PYEOF
  fi
  sleep 0.3; systemctl --user restart waybar.service
  ;;
*)
  echo "Could not get lid state" >&2
  exit 1
  ;;
esac
