pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules
import QtQuick
import Quickshell
import Quickshell.Io

// RodctlService
// Reads JSON state events from `rodctl daemon` via a named pipe.
// Exposes:
//   running         — true only when rodctl daemon is alive
//   workspaces      — list of { id, name, monitor, windows }
//   windows         — list of { address, class, title, workspace: { id, name } }
//   focusedWorkspace — id of the currently active workspace
//   focusedWindow   — address of focused window
//
// All workspace/app data in CrescentShell should bind to this
// instead of Hyprland directly, so the UI only populates when
// rodctl is present.

Singleton {
    id: root

    // ── Public state ──────────────────────────────────────────

    property bool running: false

    property var workspaces: []
    property var windows: []
    property int focusedWorkspace: 1
    property string focusedWindow: ""

    // Convenience: biggest window (by title length) per workspace id
    function biggestWindowForWorkspace(wsId) {
        var wins = root.windows.filter(w => w.workspace && w.workspace.id === wsId)
        if (wins.length === 0) return null
        return wins.reduce((a, b) => (b.title.length > a.title.length ? b : a))
    }

    // ── Pipe path (matches Go: $XDG_RUNTIME_DIR/rodctl.pipe) ──

    readonly property string pipePath: {
        var xdg = Quickshell.env("XDG_RUNTIME_DIR") || ("/run/user/" + Quickshell.env("UID"))
        return xdg + "/rodctl.pipe"
    }

    // ── Liveness probe timer ──────────────────────────────────
    // We check every 2s whether the pipe file exists.
    // The daemon creates the pipe on start and removes it on stop.

    Timer {
        id: aliveTimer
        interval: 2000
        repeat: true
        running: true
        onTriggered: root.checkAlive()
    }

    function checkAlive() {
        probeProcess.running = false
        probeProcess.running = true
    }

    Process {
        id: probeProcess
        running: false
        command: ["test", "-p", root.pipePath]
        onExited: (code) => {
            var wasRunning = root.running
            root.running = (code === 0)
            if (!wasRunning && root.running) {
                // Just came online — open the pipe reader
                pipeReader.active = true
            } else if (wasRunning && !root.running) {
                // Daemon stopped — clear state
                pipeReader.active = false
                root.workspaces = []
                root.windows = []
                root.focusedWorkspace = 1
                root.focusedWindow = ""
            }
        }
    }

    // ── Pipe reader ───────────────────────────────────────────
    // Opens the named pipe and reads JSON lines from the daemon.

    Loader {
        id: pipeReader
        active: false

        sourceComponent: Component {
            Process {
                id: catProc
                // `cat` on a named pipe: blocks until daemon writes, streams continuously
                command: ["cat", root.pipePath]
                running: true

                stdout: SplitParser {
                    splitMarker: "\n"
                    onRead: (line) => {
                        if (!line || line.trim() === "") return
                        try {
                            var ev = JSON.parse(line)
                            if (ev.type === "state" && ev.state) {
                                root.workspaces        = ev.state.workspaces        || []
                                root.windows           = ev.state.windows           || []
                                root.focusedWorkspace  = ev.state.focusedWorkspace  || 1
                                root.focusedWindow     = ev.state.focusedWindow     || ""
                            }
                        } catch (e) {}
                    }
                }

                onExited: {
                    // Pipe closed (daemon stopped) — retry after a moment
                    pipeReader.active = false
                    retryTimer.restart()
                }
            }
        }
    }

    Timer {
        id: retryTimer
        interval: 1500
        repeat: false
        onTriggered: {
            if (root.running) pipeReader.active = true
        }
    }
}
