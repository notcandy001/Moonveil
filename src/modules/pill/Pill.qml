import QtQuick
import "../../services"

// This component is only ever alive while the PanelWindow is visible
// (see shell.qml's Loader). That means the Timer below only ticks while
// the pill is on screen — there is no permanent clock running in the
// background, satisfying the "no unnecessary polling while hidden" rule.
Rectangle {
    id: root

    // Target: 220-260 x 40-48, decided at the low end for a compact rice.
    implicitWidth: 232
    implicitHeight: 44
    radius: 18

    // Placeholder palette — intentionally NOT wired to any theming system
    // yet. Phase 3 replaces these four values with Colors.* from
    // ~/.cache/trez/colors.json. Keeping them isolated here means that
    // swap touches only this block.
    color: "#CC1A1B26"
    border.color: "#33FFFFFF"
    border.width: 1

    Battery {
        id: battery
    }

    property string timeText: ""

    function updateClock() {
        const now = new Date()
        timeText = Qt.formatTime(now, "hh:mm")
    }

    Timer {
        id: clockTimer
        interval: 1000
        running: true // only exists while Pill exists, i.e. while visible
        repeat: true
        onTriggered: root.updateClock()
    }

    Component.onCompleted: root.updateClock()

    Row {
        anchors.centerIn: parent
        spacing: 10

        Text {
            text: root.timeText
            color: "#EDEDF2"
            font.pixelSize: 15
            font.family: "monospace"
            anchors.verticalCenter: parent.verticalCenter
        }

        Rectangle {
            width: 1
            height: 16
            color: "#33FFFFFF"
            anchors.verticalCenter: parent.verticalCenter
        }

        Row {
            spacing: 5
            anchors.verticalCenter: parent.verticalCenter

            Text {
                text: battery.icon
                color: "#EDEDF2"
                font.pixelSize: 14
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: battery.percentText
                color: "#EDEDF2"
                font.pixelSize: 13
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
