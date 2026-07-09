pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "./LockContext.qml"
import "./LockSurface.qml"

Singleton {
    Process {
        id: screencopyCmd
        running: false
        command: ["grim", "-s", "0.5", "-t", "jpeg", "/tmp/lock_screencopy.jpeg"]
        onExited: () => {
            lock.locked = true;
        }
    }

    IpcHandler {
        target: "lockscreen"

        function lock(): void {
            screencopyCmd.running = true;
        }
    }

    LockContext {
        id: lockContext
        onUnlocked: () => {
            lock.locked = false;
        }
    }

    WlSessionLock {
        id: lock
        locked: false

        WlSessionLockSurface {
            id: lockSurface
            color: "transparent"
            LockSurface {
                anchors.fill: parent
                context: lockContext
            }
        }
    }

    function init() {}
}
