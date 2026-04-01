import QtQuick
import QtQuick.Layouts

ColumnLayout {
    spacing: 16

    function run(cmd) {
        var proc = Qt.createQmlObject('import QtQuick; Process {}', parent)
        proc.program = "bash"
        proc.arguments = ["-c", cmd]
        proc.start()
    }

    Rectangle {
        Layout.fillWidth: true
        height: 44
        radius: 12
        color: "#222"

        Text {
            anchors.centerIn: parent
            text: "Lock"
            color: "white"
        }

        MouseArea {
            anchors.fill: parent
            onClicked: run("hyprlock")
        }
    }

    Rectangle {
        Layout.fillWidth: true
        height: 44
        radius: 12
        color: "#222"

        Text {
            anchors.centerIn: parent
            text: "Logout"
            color: "white"
        }

        MouseArea {
            anchors.fill: parent
            onClicked: run("hyprctl dispatch exit")
        }
    }

    Rectangle {
        Layout.fillWidth: true
        height: 44
        radius: 12
        color: "#222"

        Text {
            anchors.centerIn: parent
            text: "Reboot"
            color: "white"
        }

        MouseArea {
            anchors.fill: parent
            onClicked: run("systemctl reboot")
        }
    }

    Rectangle {
        Layout.fillWidth: true
        height: 44
        radius: 12
        color: "#222"

        Text {
            anchors.centerIn: parent
            text: "Shutdown"
            color: "white"
        }

        MouseArea {
            anchors.fill: parent
            onClicked: run("systemctl poweroff")
        }
    }
}
