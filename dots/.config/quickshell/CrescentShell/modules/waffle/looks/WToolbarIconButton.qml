import QtQuick
import QtQuick.Layouts
import qs.modules

WToolbarButton {
    id: root
    implicitWidth: height
    contentItem: Item {
        FluentIcon {
            anchors.centerIn: parent
            icon: root.icon.name
            implicitSize: 18
            color: root.fgColor
        }
    }
}
