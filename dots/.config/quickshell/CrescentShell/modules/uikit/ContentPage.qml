import QtQuick
import QtQuick.Layouts
import qs.modules
import qs.modules.theme

StyledFlickable {
    id: root
    property real baseWidth: 600
    property bool forceWidth: false
    property real bottomContentPadding: 80

    default property alias data: contentColumn.data

    clip: true
    contentHeight: contentColumn.implicitHeight + root.bottomContentPadding

    ScrollBar.vertical: ScrollBar {
        width: 3
        contentItem: Rectangle {
            color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.45)
            radius: 2
        }
        background: Rectangle { color: "transparent" }
    }

    ColumnLayout {
        id: contentColumn
        width: root.forceWidth ? root.baseWidth : Math.max(root.baseWidth, implicitWidth)
        anchors {
            top: parent.top
            horizontalCenter: parent.horizontalCenter
            margins: 20
        }
        spacing: 20
    }
}
