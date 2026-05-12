#!/bin/sh

LAPTOP_OUTPUT="eDP-1"
LID_STATE_FILE="/proc/acpi/button/lid/LID/state"

read -r LS <"$LID_STATE_FILE"

case "$LS" in
*open)   hyprctl reload ;;
*closed)
  hyprctl eval "hl.monitor({output='${LAPTOP_OUTPUT}', disabled=true})"
  # Give Hyprland a moment, then migrate any orphaned workspaces to the
  # first active monitor so they are not stranded on the disabled output.
  sleep 0.5
  ACTIVE=$(hyprctl monitors -j | python3 -c \
    "import json,sys; ms=json.load(sys.stdin); print(next((m['name'] for m in ms if m['name']!='${LAPTOP_OUTPUT}'),''))")
  if [ -n "$ACTIVE" ]; then
    hyprctl workspaces -j | python3 - "$LAPTOP_OUTPUT" "$ACTIVE" <<'PYEOF'
import json, sys, subprocess
disabled, target = sys.argv[1], sys.argv[2]
ws_list = json.load(sys.stdin)
for ws in ws_list:
    if ws.get("monitor", "") in ("", disabled):
        ws_id = str(ws["id"])
        subprocess.run(
            ["hyprctl", "eval",
             f"hl.dispatch('moveworkspacetomonitor', '{ws_id} {target}')"],
            check=False,
        )
PYEOF
  fi
  ;;
*)
  echo "Could not get lid state" >&2
  exit 1
  ;;
esac
