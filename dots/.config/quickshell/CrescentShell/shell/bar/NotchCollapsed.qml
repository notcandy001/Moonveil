import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland

Item {

    property int contentWidth: 400

    width: contentWidth
    height: 20

    RowLayout {
        anchors.fill: parent
        spacing: 12

        Text {
            id: timeText
            text: Qt.formatTime(new Date(), "hh:mm")
            color: "#cfcfcf"
            font.pixelSize: 14
        }

        Item { Layout.fillWidth: true }

        Text {
            text: Hyprland.activeToplevel
                  && Hyprland.activeToplevel.title
                  ? Hyprland.activeToplevel.title
                  : "Desktop"

            color: "#ffffff"
            font.pixelSize: 14
            elide: Text.ElideRight
            Layout.alignment: Qt.AlignRight
        }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: timeText.text =
            Qt.formatTime(new Date(), "hh:mm")
    }
}
