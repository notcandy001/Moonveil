pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.UPower
import Quickshell.Widgets
import qs
import qs.services
import qs.modules
import qs.modules.uikit
import "../bar" as CsBar

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
            active: GlobalStates.barOpen && !GlobalStates.screenLocked
            required property ShellScreen modelData

            component: PanelWindow {
                id: barRoot
                screen: barLoader.modelData

                readonly property bool onRight: Config.options.bar.bottom
                readonly property HyprlandMonitor hyprMonitor: Hyprland.monitorFor(screen)
                readonly property Toplevel activeWindow: ToplevelManager.activeToplevel

                // Attached to screen edge, pushes windows away
                exclusionMode: ExclusionMode.Normal
                exclusiveZone: 44

                implicitWidth: 44
                color: "transparent"

                WlrLayershell.namespace: "crescentshell:verticalBar"
                WlrLayershell.layer: WlrLayer.Top
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

                anchors {
                    left:   !onRight
                    right:   onRight
                    top:    true
                    bottom: true
                }

                Component.onCompleted:   GlobalFocusGrab.addPersistent(barRoot)
                Component.onDestruction: GlobalFocusGrab.removePersistent(barRoot)

                // Floating panel with margin
                Rectangle {
                    anchors {
                        top: parent.top; bottom: parent.bottom
                        left: parent.left; right: parent.right
                        topMargin: 8; bottomMargin: 8
                        leftMargin: barRoot.onRight ? 0 : 6
                        rightMargin: barRoot.onRight ? 6 : 0
                    }
                    radius: 20
                    color: Appearance.m3colors.m3surfaceContainerLow
                    border.width: 1
                    border.color: Appearance.colors.colLayer0Border

                    ColumnLayout {
                        anchors {
                            fill: parent
                            topMargin: 10; bottomMargin: 10
                            leftMargin: 4; rightMargin: 4
                        }
                        spacing: 5

                        // ── Launcher ──────────────────────────────
                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            width: 36; height: 36; radius: 18
                            color: launchHov.containsMouse
                                ? Appearance.colors.colLayer2
                                : Appearance.colors.colLayer1
                            Behavior on color { ColorAnimation { duration: 120 } }
                            Text {
                                anchors.centerIn: parent
                                text: "⊞"; font.pixelSize: 16
                                color: Appearance.m3colors.m3onSurface
                            }
                            MouseArea {
                                id: launchHov; anchors.fill: parent; hoverEnabled: true
                                onClicked: GlobalStates.overviewOpen = !GlobalStates.overviewOpen
                            }
                        }

                        // ── Time ──────────────────────────────────
                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            width: 36; height: 52; radius: 18
                            color: "#000000"
                            Column {
                                anchors.centerIn: parent; spacing: 0
                                Text {
                                    id: hourText
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: Qt.formatTime(new Date(), "hh")
                                    color: Appearance.colors.colPrimary
                                    font.pixelSize: 13; font.weight: Font.Bold
                                    Timer {
                                        interval: 60000; running: true; repeat: true
                                        onTriggered: {
                                            hourText.text = Qt.formatTime(new Date(), "hh")
                                            minText.text  = Qt.formatTime(new Date(), "mm")
                                        }
                                    }
                                }
                                Text {
                                    id: minText
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: Qt.formatTime(new Date(), "mm")
                                    color: Appearance.colors.colPrimary
                                    font.pixelSize: 13; font.weight: Font.Bold
                                }
                            }
                        }

                        // ── Workspaces ────────────────────────────
                        Column {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 2

                            Repeater {
                                model: Config.options.bar.workspaces.shown

                                Item {
                                    required property int index
                                    width: 36; height: 24

                                    readonly property int wsId: {
                                        const activeId = barRoot.hyprMonitor?.activeWorkspace?.id ?? 1
                                        const grp = Math.floor((activeId - 1) / Config.options.bar.workspaces.shown)
                                        return grp * Config.options.bar.workspaces.shown + index + 1
                                    }
                                    readonly property bool isActive:
                                        (barRoot.hyprMonitor?.activeWorkspace?.id ?? 1) === wsId
                                    readonly property bool isOccupied:
                                        HyprlandData.workspaceOccupationMap[wsId] ?? false
                                    readonly property var biggestWin:
                                        HyprlandData.biggestWindowForWorkspace(wsId)

                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: 22; height: 22; radius: 11
                                        color: parent.isActive
                                            ? Appearance.colors.colPrimary
                                            : parent.isOccupied
                                                ? Appearance.m3colors.m3secondaryContainer
                                                : "transparent"
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                    }

                                    IconImage {
                                        anchors.centerIn: parent
                                        implicitSize: 14
                                        source: parent.biggestWin && Config.options.bar.workspaces.showAppIcons
                                            ? Quickshell.iconPath(AppSearch.guessIcon(parent.biggestWin.class), "application-x-executable")
                                            : ""
                                        visible: parent.biggestWin !== null && Config.options.bar.workspaces.showAppIcons
                                    }

                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: parent.isActive ? 6 : 3
                                        height: width; radius: width / 2
                                        visible: !parent.biggestWin || !Config.options.bar.workspaces.showAppIcons
                                        color: parent.isActive
                                            ? Appearance.m3colors.m3onPrimary
                                            : parent.isOccupied
                                                ? Appearance.m3colors.m3onSecondaryContainer
                                                : Appearance.colors.colOnLayer1Inactive
                                        Behavior on width { NumberAnimation { duration: 150 } }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: Hyprland.dispatch("workspace " + parent.wsId)
                                    }
                                }
                            }
                        }

                        // ── Active window title ───────────────────
                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            width: 36; height: 110; radius: 18
                            color: Appearance.colors.colLayer1
                            visible: barRoot.activeWindow?.title ?? false
                            clip: true

                            Text {
                                anchors.centerIn: parent
                                width: parent.height - 12
                                text: {
                                    const t = barRoot.activeWindow?.title ?? ""
                                    const clean = t.split(" - ")[0].split(" — ")[0]
                                    return clean.length > 16 ? clean.slice(0, 16) + "…" : clean
                                }
                                color: Appearance.colors.colPrimary
                                font.pixelSize: 11
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                                // Right panel: rotate +90, Left panel: rotate -90
                                rotation: barRoot.onRight ? 90 : -90
                            }
                        }

                        // ── Fill ──────────────────────────────────
                        Item { Layout.fillHeight: true }

                        // ── Systray ───────────────────────────────
                        Flow {
                            Layout.alignment: Qt.AlignHCenter
                            width: 36; spacing: 3
                            CsBar.SysTray { height: 16; invertSide: false }
                        }

                        // ── Divider ───────────────────────────────
                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            width: 28; height: 1
                            color: Appearance.colors.colLayer0Border
                        }

                        // ── Battery ───────────────────────────────
                        CsBar.BatteryIndicator {
                            Layout.alignment: Qt.AlignHCenter
                            visible: Battery.available
                        }

                        // ── Network ───────────────────────────────
                        MaterialSymbol {
                            Layout.alignment: Qt.AlignHCenter
                            text: Network.materialSymbol
                            iconSize: 15
                            color: Appearance.m3colors.m3onSurface
                            MouseArea {
                                anchors.fill: parent
                                onClicked: GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen
                            }
                        }

                        // ── Notif dot ─────────────────────────────
                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            width: 7; height: 7; radius: 4
                            visible: Notifications.unread > 0
                            color: Appearance.m3colors.m3error
                            MouseArea {
                                anchors.fill: parent
                                onClicked: GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen
                            }
                        }
                    }
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

    GlobalShortcut {
        name: "barToggle"; description: "Toggle vertical bar"
        onPressed: GlobalStates.barOpen = !GlobalStates.barOpen
    }
}
