pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs
import qs.services
import qs.core
import qs.core.widgets

Scope {
    id: bar

    Variants {
        model: {
            const screens = Quickshell.screens
            const list = Config.options.bar.screenList
            if (!list || list.length === 0) return screens
            return screens.filter(s => list.includes(s.name))
        }

        LazyLoader {
            id: barLoader
            required property ShellScreen modelData
            active: GlobalStates.barOpen && !GlobalStates.screenLocked

            component: PanelWindow {
                id: barRoot
                screen: barLoader.modelData

                // Super-key show on press
                Timer {
                    id: showBarTimer
                    interval: Config?.options.bar.autoHide.showWhenPressingSuper.delay ?? 100
                    repeat: false
                    onTriggered: barRoot.superShow = true
                }
                Connections {
                    target: GlobalStates
                    function onSuperDownChanged() {
                        if (!Config?.options.bar.autoHide.showWhenPressingSuper.enable) return
                        if (GlobalStates.superDown) showBarTimer.restart()
                        else { showBarTimer.stop(); barRoot.superShow = false }
                    }
                }
                property bool superShow: false

                exclusionMode: ExclusionMode.Ignore
                exclusiveZone:  notch.collapsedHeight + 10
                implicitHeight: notch.mode !== "idle"
                    ? notch.expandedHeight + 10
                    : notch.collapsedHeight + 10

                WlrLayershell.namespace:     "crescentshell:bar"
                WlrLayershell.layer:         WlrLayer.Top
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

                color: "transparent"

                anchors {
                    top:    !Config.options.bar.bottom
                    bottom:  Config.options.bar.bottom
                    left:   true
                    right:  true
                }

                Component.onCompleted:   GlobalFocusGrab.addPersistent(barRoot)
                Component.onDestruction: GlobalFocusGrab.removePersistent(barRoot)

                // ── LEFT: launcher + workspaces ───────────────
                LeftContainer {
                    id: leftPills
                    monitor: barRoot.screen
                    anchors {
                        left:         parent.left
                        top:          !Config.options.bar.bottom ? parent.top    : undefined
                        bottom:        Config.options.bar.bottom ? parent.bottom : undefined
                        leftMargin:   14
                        topMargin:    !Config.options.bar.bottom ? 6 : 0
                        bottomMargin:  Config.options.bar.bottom ? 6 : 0
                    }
                    z: 2
                    onLauncherRequested: {
                        GlobalStates.overviewOpen = !GlobalStates.overviewOpen
                    }
                }

                // ── CENTER: notch pill ────────────────────────
                Notch {
                    id: notch
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top:    !Config.options.bar.bottom ? parent.top    : undefined
                    anchors.bottom:  Config.options.bar.bottom ? parent.bottom : undefined
                    anchors.topMargin:    !Config.options.bar.bottom ? 6 : 0
                    anchors.bottomMargin:  Config.options.bar.bottom ? 6 : 0
                    z: 3
                }

                // ── RIGHT: systray + system pill ──────────────
                RightContainer {
                    id: rightPills
                    anchors {
                        right:        parent.right
                        top:          !Config.options.bar.bottom ? parent.top    : undefined
                        bottom:        Config.options.bar.bottom ? parent.bottom : undefined
                        rightMargin:  14
                        topMargin:    !Config.options.bar.bottom ? 6 : 0
                        bottomMargin:  Config.options.bar.bottom ? 6 : 0
                    }
                    z: 2
                }
            }
        }
    }

    IpcHandler {
        target: "bar"
        function toggle(): void { GlobalStates.barOpen = !GlobalStates.barOpen }
        function close():  void { GlobalStates.barOpen = false }
        function open():   void { GlobalStates.barOpen = true }
    }

    GlobalShortcut { name: "barToggle"; description: "Toggle bar"
        onPressed: GlobalStates.barOpen = !GlobalStates.barOpen }
    GlobalShortcut { name: "barOpen";  description: "Open bar";  onPressed: GlobalStates.barOpen = true }
    GlobalShortcut { name: "barClose"; description: "Close bar"; onPressed: GlobalStates.barOpen = false }

    GlobalShortcut {
        name: "settingsOpen"
        description: "Open crescentshell settings"
        onPressed: Quickshell.execDetached(["qs", "-p", Quickshell.shellPath("settings.qml")])
    }
}
