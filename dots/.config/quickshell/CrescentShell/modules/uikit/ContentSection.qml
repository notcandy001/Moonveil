import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules
import qs.modules.theme

ColumnLayout {
    id: root
    property string title
    property string icon: ""
    default property alias data: sectionContent.data

    Layout.fillWidth: true
    spacing: 0

    // Section header
    RowLayout {
        Layout.fillWidth: true
        Layout.bottomMargin: 6
        spacing: 8

        // Accent bar
        Rectangle {
            width: 3; height: 16; radius: 2
            color: Colors.primary
            visible: root.title !== ""
        }

        OptionalMaterialSymbol {
            icon: root.icon
            iconSize: Appearance.font.pixelSize.larger
        }

        StyledText {
            Layout.fillWidth: true
            text: root.title
            font.pixelSize: Appearance.font.pixelSize.normal
            font.weight: Font.SemiBold
            color: Colors.overBackground
        }
    }

    // Section body card
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: sectionContent.implicitHeight + 16
        radius: Styling.radius(-1)
        color: Colors.surfaceContainer
        border.width: 1
        border.color: Qt.rgba(Colors.outlineVariant.r, Colors.outlineVariant.g, Colors.outlineVariant.b, 0.35)

        ColumnLayout {
            id: sectionContent
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 8; topMargin: 8 }
            spacing: 2
        }
    }
}
