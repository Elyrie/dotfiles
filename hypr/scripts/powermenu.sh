#!/usr/bin/env bash

chosen=$(printf "  Shutdown\n  Restart\n  Logout" | wofi --dmenu --prompt "Power" --width 200 --height 200 --lines 3 --hide-search)

case "$chosen" in
    "  Shutdown")
        systemctl poweroff
        ;;
    "  Restart")
        systemctl reboot
        ;;
    "  Logout")
        hyprctl dispatch exit
        ;;
esac
