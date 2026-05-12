#!/usr/bin/env python3
"""
Listen to Hyprland IPC events and toggle eDP-1 on lid open/close.
"""
import json
import socket
import subprocess
import os
import sys
import time

EDP = "eDP-1"

def hyprctl_eval(lua):
    subprocess.run(["hyprctl", "eval", lua], check=False)


def migrate_workspaces_from(output: str) -> None:
    """Move any workspaces still sitting on *output* (or orphaned) to the
    first other active monitor.  Called after *output* is disabled."""
    # Give Hyprland a moment to finish the disable before querying state.
    time.sleep(0.3)

    try:
        monitors_raw = subprocess.check_output(["hyprctl", "monitors", "-j"])
        workspaces_raw = subprocess.check_output(["hyprctl", "workspaces", "-j"])
    except subprocess.CalledProcessError:
        return

    monitors = json.loads(monitors_raw)
    workspaces = json.loads(workspaces_raw)

    # Find any monitor that is NOT the one we just disabled.
    active_monitors = [m["name"] for m in monitors if m["name"] != output]
    if not active_monitors:
        return  # nowhere to send them

    target = active_monitors[0]

    for ws in workspaces:
        ws_monitor = ws.get("monitor", "")
        # Orphaned workspaces have an empty string or the disabled monitor name.
        if ws_monitor in ("", output):
            ws_id = ws["id"]
            subprocess.run(
                ["hyprctl", "eval",
                 f"hl.dispatch(hl.dsp.workspace.move({{workspace = {ws_id}, monitor = '{target}'}})"],
                check=False,
            )

def main():
    instance = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
    runtime  = os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")

    if not instance:
        print("HYPRLAND_INSTANCE_SIGNATURE not set", file=sys.stderr)
        sys.exit(1)

    sock_path = f"{runtime}/hypr/{instance}/.socket2.sock"

    # Retry connection a few times in case Hyprland isn't ready yet
    for _ in range(10):
        try:
            sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            sock.connect(sock_path)
            break
        except OSError:
            time.sleep(0.5)
    else:
        print(f"Could not connect to {sock_path}", file=sys.stderr)
        sys.exit(1)

    buf = b""
    while True:
        data = sock.recv(4096)
        if not data:
            break
        buf += data
        while b"\n" in buf:
            line, buf = buf.split(b"\n", 1)
            event = line.decode(errors="replace").strip()
            if event.startswith("switch>>on") and "Lid" in event:
                hyprctl_eval(f"hl.monitor({{output='{EDP}', disabled=true}})")
                migrate_workspaces_from(EDP)
            elif event.startswith("switch>>off") and "Lid" in event:
                hyprctl_eval(
                    f"hl.monitor({{output='{EDP}', mode='preferred',"
                    f" position='auto', scale='auto', disabled=false}})"
                )

if __name__ == "__main__":
    main()
