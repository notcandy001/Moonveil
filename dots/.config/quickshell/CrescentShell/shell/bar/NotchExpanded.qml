import QtQuick
import QtQuick.Layouts

Item {

    property string activeTab: "Widgets"

    anchors.fill: parent
    anchors.margins: 24

    ColumnLayout {
        anchors.fill: parent
        spacing: 18

        RowLayout {
            Layout.fillWidth: true
            spacing: 32

            Repeater {
                model: ["Widgets", "Pins", "Kanban", "Wallpapers", "Mixer"]

                delegate: Text {
                    text: modelData
                    color: activeTab === modelData ? "white" : "#777777"
                    font.pixelSize: 16

                    MouseArea {
                        anchors.fill: parent
                        onClicked: activeTab = modelData
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 24

            Rectangle { Layout.fillHeight: true; Layout.preferredWidth: 260; radius: 22; color: "#151515" }
            Rectangle { Layout.fillHeight: true; Layout.preferredWidth: 320; radius: 22; color: "#181818" }
            Rectangle { Layout.fillHeight: true; Layout.fillWidth: true; radius: 22; color: "#121212" }
            Rectangle { Layout.fillHeight: true; Layout.preferredWidth: 120; radius: 22; color: "#101010" }
        }
    }
}
