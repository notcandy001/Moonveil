import qs.modules
import qs.modules.theme
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Item {
    id: root
    property string buttonIcon
    property string text
    property alias iconSize: iconWidget.iconSize
    property bool checked: false
    property bool enabled: true

    signal clicked()

    Layout.fillWidth: true
    implicitHeight: rowLayout.implicitHeight + 14

    opacity: enabled ? 1.0 : 0.45

    Rectangle {
        anchors.fill: parent
        radius: Styling.radius(-2)
        color: rowMA.containsMouse
            ? Colors.surfaceContainerHigh
            : "transparent"
        Behavior on color { ColorAnimation { duration: 100 } }
    }

    RowLayout {
        id: rowLayout
        anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
        spacing: 10

        OptionalMaterialSymbol {
            id: iconWidget
            icon: root.buttonIcon
            iconSize: Appearance.font.pixelSize.larger
        }

        StyledText {
            Layout.fillWidth: true
            text: root.text
            font.pixelSize: Appearance.font.pixelSize.small
            color: Colors.overBackground
            wrapMode: Text.WordWrap
        }

        // Pill toggle
        Rectangle {
            id: pill
            implicitWidth: 38; implicitHeight: 20
            radius: height / 2
            color: root.checked ? Colors.primary : Colors.surfaceContainerHighest
            border.width: 1
            border.color: root.checked
                ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.6)
                : Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.5)
            Behavior on color        { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }

            Rectangle {
                x: root.checked ? parent.width - width - 3 : 3
                y: 3; width: parent.height - 6; height: width; radius: width / 2
                color: root.checked ? Colors.overPrimary : Colors.overSurfaceVariant
                Behavior on x     { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 150 } }
            }
        }
    }

    MouseArea {
        id: rowMA
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.checked = !root.checked
            root.clicked()
        }
    }
}
