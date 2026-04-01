import QtQuick
import Quickshell
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.services
import qs.modules
import qs.modules.functions

Rectangle {
    id: root

    property string mode: "idle"
    property int collapsedHeight: 40
    property int expandedHeight: 460

    signal closeRequested()

    property Toplevel activeToplevel: HyprlandData.isWorkspaceOccupied(HyprlandData.focusedWorkspaceId)
        ? HyprlandData.activeToplevel
        : null

    // Cava
    property var cavaBars: []
    property int cavaBarCount: 16
    readonly property bool mediaPlaying: {
        const p = MprisController.activePlayer
        return p !== null && p.playbackState === MprisPlaybackState.Playing
    }

    // Start/stop cava based on media state
    Process {
        id: cavaProc
        command: ["bash", "-c",
            "rm -f /tmp/crescentshell_cava.fifo; mkfifo /tmp/crescentshell_cava.fifo; " +
            "cava -p " + Quickshell.shellPath("scripts/cava/cava.ini") + " &" +
            "cat /tmp/crescentshell_cava.fifo"]
        running: root.mediaPlaying
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                const vals = data.trim().split(";").map(v => parseInt(v) || 0)
                if (vals.length >= root.cavaBarCount)
                    root.cavaBars = vals.slice(0, root.cavaBarCount)
            }
        }
    }

    // Kill cava when not playing
    Process {
        id: cavakillProc
        command: ["bash", "-c", "pkill -f 'cava -p'"]
        running: false
    }
    onMediaPlayingChanged: {
        if (!mediaPlaying) {
            cavakillProc.running = true
            root.cavaBars = []
        }
    }

    property string cleanTitle: {
        if (!activeToplevel) return "Desktop"
        var raw = activeToplevel?.title
        if (!raw || raw === "" || raw === "Workspace") return "Desktop"
        var parts = raw.split(" - ")
        if (parts.length > 1) return parts[0]
        return raw
    }

    width: {
        if (mode !== "idle") return 800
        if (mediaPlaying) return 280
        var base = 160
        var textWidth = titleText.implicitWidth
        var calculated = base + textWidth
        return Math.min(Math.max(calculated, 240), 600)
    }

    height: mode === "idle" ? collapsedHeight : expandedHeight
    radius: mode === "idle" ? 20 : 28
    color: "#000000"
    clip: true

    Behavior on width  { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
    Behavior on height { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
    Behavior on radius { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

    Keys.onEscapePressed: { if (mode !== "idle") mode = "idle" }
    focus: true

    // ── IDLE CONTENT ──────────────────────────────────────────
    Item {
        anchors.fill: parent
        opacity: mode === "idle" ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 80 } }

        // Normal: time + title
        Row {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12
            opacity: root.mediaPlaying ? 0 : 1
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 200 } }

            Text {
                id: timeText
                text: Qt.formatTime(new Date(), "hh:mm")
                color: Appearance.colors.colPrimary
                font.pixelSize: 14
                verticalAlignment: Text.AlignVCenter
                height: parent.height
                Timer {
                    interval: 60000; running: true; repeat: true
                    onTriggered: timeText.text = Qt.formatTime(new Date(), "hh:mm")
                }
            }
            Item {
                width: parent.width - timeText.width - titleText.width - 32
                height: 1
            }
            Text {
                id: titleText
                text: root.cleanTitle
                color: "#ffffff"
                font.pixelSize: 14
                elide: Text.ElideRight
                width: Math.min(implicitWidth, 300)
                verticalAlignment: Text.AlignVCenter
                height: parent.height
            }
        }

        // Cava mode: app icon + bars
        Row {
            anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
            spacing: 8
            opacity: root.mediaPlaying ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 200 } }

            // App icon
            Item {
                width: 24; height: parent.height
                anchors.verticalCenter: undefined

                Image {
                    anchors.centerIn: parent
                    width: 20; height: 20
                    source: {
                        const p = MprisController.activePlayer
                        if (!p) return ""
                        return Quickshell.iconPath(
                            AppSearch.guessIcon(p.identity.toLowerCase()),
                            "audio-x-generic"
                        )
                    }
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }
            }

            // Cava bars
            Row {
                id: barsRow
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1
                height: root.collapsedHeight - 10
                width: parent.width - 44

                Repeater {
                    model: root.cavaBarCount
                    delegate: Rectangle {
                        required property int index
                        width: Math.max(1, (barsRow.width - (root.cavaBarCount - 1) * 1) / root.cavaBarCount)
                        radius: 2
                        height: Math.max(3,
                            (root.cavaBars[index] ?? 0) / 100 * (barsRow.height))
                        anchors.bottom: parent.bottom
                        color: Appearance.colors.colPrimary
                        Behavior on height {
                            NumberAnimation { duration: 60; easing.type: Easing.OutQuad }
                        }
                    }
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.mode = "dashboard"
        }
    }

    // ── EXPANDED CONTENT ──────────────────────────────────────
    Item {
        anchors.fill: parent
        anchors.margins: 32
        opacity: mode === "dashboard" ? 1 : 0
        scale: mode === "dashboard" ? 1 : 0.94
        visible: opacity > 0
        transformOrigin: Item.Top
        Behavior on opacity { NumberAnimation { duration: 160 } }
        Behavior on scale   { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        Rectangle {
            anchors.fill: parent
            radius: 22; color: "#151515"
            Text { anchors.centerIn: parent; text: "Dashboard"; color: "white"; font.pixelSize: 22 }
        }
        MouseArea { anchors.fill: parent; onClicked: root.mode = "idle" }
    }
}
