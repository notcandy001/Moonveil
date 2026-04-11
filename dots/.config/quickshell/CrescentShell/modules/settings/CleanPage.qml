pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.services
import qs.modules
import qs.modules.uikit
import qs.modules.theme

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

            Text {
                text: root.pageTitle
                font.pixelSize: Styling.fontSize(-1)
                font.weight: Font.SemiBold
                font.letterSpacing: 1.2
                color: Colors.overSurfaceVariant
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

    component CCard: Rectangle {
        default property alias content: inner.data
        Layout.fillWidth: true
        implicitHeight: inner.implicitHeight + 24
        radius: Styling.radius(0)
        color: Colors.surfaceContainer
        border.width: 1
        border.color: Qt.rgba(Colors.outlineVariant.r, Colors.outlineVariant.g, Colors.outlineVariant.b, 0.35)

        ColumnLayout {
            id: inner
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16; topMargin: 12 }
            spacing: 0
        }
    }

    component CSectionLabel: Text {
        Layout.fillWidth: true
        Layout.topMargin: 10
        font.pixelSize: Styling.fontSize(-2)
        font.weight: Font.SemiBold
        font.letterSpacing: 1.3
        color: Colors.overSurfaceVariant
        opacity: 0.75
    }

    component CRow: Rectangle {
        id: crow
        property string icon: ""
        property string label: ""
        property string subtitle: ""
        signal clicked()

        Layout.fillWidth: true
        implicitHeight: crowContent.implicitHeight + 14
        radius: Styling.radius(-2)
        color: rowHov.containsMouse ? Colors.surfaceContainerHigh : "transparent"
        Behavior on color { ColorAnimation { duration: 100 } }

        RowLayout {
            id: crowContent
            anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
            spacing: 10

            MaterialSymbol {
                text: crow.icon
                iconSize: Appearance.font.pixelSize.larger
                color: Colors.overSurfaceVariant
                visible: crow.icon !== ""
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                Text { text: crow.label; font.pixelSize: Styling.fontSize(0); color: Colors.overBackground }
                Text { text: crow.subtitle; font.pixelSize: Styling.fontSize(-2); color: Colors.overSurfaceVariant; visible: crow.subtitle !== "" }
            }
        }
        MouseArea {
            id: rowHov; anchors.fill: parent; hoverEnabled: true
            cursorShape: Qt.PointingHandCursor; onClicked: crow.clicked()
        }
    }

    component CToggle: Rectangle {
        id: ctog
        property string icon: ""
        property string label: ""
        property bool checked: false
        signal toggled(bool state)

        Layout.fillWidth: true
        implicitHeight: ctogRow.implicitHeight + 14
        radius: Styling.radius(-2)
        color: Colors.surfaceContainer
        border.width: 1
        border.color: Qt.rgba(Colors.outlineVariant.r, Colors.outlineVariant.g, Colors.outlineVariant.b, 0.3)

        RowLayout {
            id: ctogRow
            anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
            spacing: 10

            MaterialSymbol {
                text: ctog.icon; iconSize: Appearance.font.pixelSize.larger
                color: Colors.overSurfaceVariant; visible: ctog.icon !== ""
            }
            Text { Layout.fillWidth: true; text: ctog.label; font.pixelSize: Styling.fontSize(0); color: Colors.overBackground }

            Rectangle {
                implicitWidth: 38; implicitHeight: 20; radius: height / 2
                color: ctog.checked ? Colors.primary : Colors.surfaceContainerHighest
                border.width: 1
                border.color: ctog.checked
                    ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.6)
                    : Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.5)
                Behavior on color        { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }
                Rectangle {
                    x: ctog.checked ? parent.width - width - 3 : 3
                    y: 3; width: parent.height - 6; height: width; radius: width / 2
                    color: ctog.checked ? Colors.overPrimary : Colors.overSurfaceVariant
                    Behavior on x     { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }
        }
        MouseArea {
            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
            onClicked: { ctog.checked = !ctog.checked; ctog.toggled(ctog.checked) }
        }
    }
}
