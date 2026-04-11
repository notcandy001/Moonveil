import QtQuick
import QtQuick.Layouts
import qs.modules.theme

RowLayout {
    id: root
    property bool uniform: false
    spacing: 4
    uniformCellSizes: uniform
    Layout.fillWidth: true

    // Subtle indent indicator
    Rectangle {
        Layout.preferredWidth: 2
        Layout.fillHeight: true
        Layout.leftMargin: 8
        radius: 1
        color: Qt.rgba(Colors.outlineVariant.r, Colors.outlineVariant.g, Colors.outlineVariant.b, 0.4)
        visible: false // subtle, only show when needed
    }
}
