import QtQuick
import Quickshell
import Quickshell.Io
// These are local component directories, not installed QML modules.  Use a
// relative directory import so this config works without adding a qmldir file
// or changing Quickshell's global import paths.
import "src/modules/pill" as PillModule

// Trez — single persistent process, single QML engine.
// Phase 1: hidden-by-default panel + toggle pill.
ShellRoot {
    id: root

    PanelWindow {
        id: window

        // Hidden on startup. No visible surface while idle.
        visible: false

        anchors {
            top: true
            left: true
        }
        margins {
            top: 10
            left: 10
        }

        // Size the surface to the pill itself — no extra empty window area
        // that could trigger compositor compositing/redraw for nothing.
        implicitWidth: pillLoader.item ? pillLoader.item.implicitWidth : 1
        implicitHeight: pillLoader.item ? pillLoader.item.implicitHeight : 1

        color: "transparent"

        // Loader is only active while the window is visible. This means the
        // Pill (and its clock Timer + battery hookups) is created on show
        // and fully destroyed on hide — zero idle timers, zero idle redraw.
        Loader {
            id: pillLoader
            active: window.visible
            sourceComponent: PillModule.Pill {}
        }

        // IPC entrypoint: `qs ipc call trez toggle`
        // Toggling only flips visibility on the already-running process —
        // it never restarts Quickshell or spawns a new one.
        IpcHandler {
            target: "trez"

            function toggle(): void {
                window.visible = !window.visible
            }

            function show(): void {
                window.visible = true
            }

            function hide(): void {
                window.visible = false
            }
        }
    }
}
