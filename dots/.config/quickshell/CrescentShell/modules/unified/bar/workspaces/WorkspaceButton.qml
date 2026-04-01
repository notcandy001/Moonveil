import QtQuick
import Quickshell.Hyprland

Item {
    id: root

    required property int wsId
    required property bool active
    required property bool occupied
    required property int dotSize
    required property int animDuration

    width: dotSize
    height: dotSize

    Rectangle {
        anchors.fill: parent
        radius: width / 2

        color: active
               ? "#ffffff"
               : occupied
                 ? "#aaaaaa"
                 : "#555555"

        Behavior on color {
            ColorAnimation {
                duration: animDuration
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: Hyprland.dispatch("workspace " + wsId)
    }
}
