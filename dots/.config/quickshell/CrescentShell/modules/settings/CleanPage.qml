pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.services
import qs.modules
import qs.modules.uikit

Item {
    id: root
    default property alias content: col.data
    property string pageTitle: ""

    StyledFlickable {
        anchors.fill: parent
        contentHeight: mainCol.implicitHeight + 40

        ColumnLayout {
            id: mainCol
            width: parent.width
            anchors { top: parent.top; left: parent.left; right: parent.right; margins: 24 }
            spacing: 6

            // Page title
            Text {
                text: root.pageTitle
                font.pixelSize: 13
                font.weight: Font.Normal
                color: "#666666"
                Layout.bottomMargin: 6
                visible: root.pageTitle !== ""
            }

            ColumnLayout {
                id: col
                Layout.fillWidth: true
                spacing: 4
            }
        }
    }

    // Card component
    component CCard: Rectangle {
        default property alias content: inner.data
        Layout.fillWidth: true
        implicitHeight: inner.implicitHeight + 24
        radius: 12
        color: "#1e1e1e"

        ColumnLayout {
            id: inner
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16; topMargin: 12 }
            spacing: 0
        }
    }

    // Section label
    component CSectionLabel: Text {
        Layout.fillWidth: true
        Layout.topMargin: 10
        Layout.bottomMargin: 2
        font.pixelSize: 12
        font.weight: Font.Medium
        color: "#888888"
        leftPadding: 4
    }

    // Row item (for cards with chevron)
    component CRow: Rectangle {
        id: crow
        property string icon: ""
        property string label: ""
        property string subtitle: ""
        property alias trailing: trailingSlot.data
        signal clicked()
        Layout.fillWidth: true
        height: 52; radius: 12
        color: rowHov.containsMouse ? "#262626" : "#1e1e1e"
        Behavior on color { ColorAnimation { duration: 80 } }
        HoverHandler { id: rowHov }
        MouseArea { anchors.fill: parent; onClicked: crow.clicked() }

        RowLayout {
            anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
            spacing: 12
            MaterialSymbol {
                text: crow.icon; iconSize: 18
                color: "#aaaaaa"
                visible: crow.icon !== ""
            }
            ColumnLayout {
                Layout.fillWidth: true; spacing: 1
                Text { text: crow.label; font.pixelSize: 13; color: "#ffffff" }
                Text { text: crow.subtitle; font.pixelSize: 11; color: "#666"; visible: crow.subtitle !== "" }
            }
            Item { id: trailingSlot }
        }
    }

    // Toggle row
    component CToggle: Rectangle {
        id: ctog
        property string icon: ""
        property string label: ""
        property bool checked: false
        signal toggled(bool val)
        Layout.fillWidth: true
        height: 52; radius: 12
        color: "#1e1e1e"

        RowLayout {
            anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
            spacing: 12
            MaterialSymbol {
                text: ctog.icon; iconSize: 18; color: "#aaaaaa"
                visible: ctog.icon !== ""
            }
            Text {
                text: ctog.label; font.pixelSize: 13; color: "#ffffff"
                Layout.fillWidth: true
            }
            Rectangle {
                id: sw
                width: 44; height: 24; radius: 12
                color: ctog.checked ? Appearance.colors.colPrimary : "#333333"
                Behavior on color { ColorAnimation { duration: 150 } }
                Rectangle {
                    width: 18; height: 18; radius: 9
                    anchors.verticalCenter: parent.verticalCenter
                    x: ctog.checked ? parent.width - width - 3 : 3
                    color: "white"
                    Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                }
                MouseArea { anchors.fill: parent; onClicked: ctog.toggled(!ctog.checked) }
            }
        }
    }

    // Divider
    component CDivider: Rectangle {
        Layout.fillWidth: true; height: 1
        color: "#2a2a2a"
        Layout.leftMargin: 14; Layout.rightMargin: 14
    }
}
