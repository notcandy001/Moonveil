pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs
import qs.modules
import "workspaces"

Row {
    id: root
    signal launcherRequested()
    spacing: 10
    required property var monitor

    Rectangle {
        width: 32; height: 32; radius: 16
        color: launchArea.containsMouse ? Appearance.m3colors.m3surfaceContainerHigh : Appearance.m3colors.m3surfaceContainerLow
        Behavior on color { ColorAnimation { duration: 120 } }
        Text { anchors.centerIn: parent; text: "⊞"; color: Appearance.m3colors.m3onSurface; font.pixelSize: 16 }
        MouseArea { id: launchArea; anchors.fill: parent; hoverEnabled: true; onClicked: root.launcherRequested() }
    }

    Workspaces { monitor: root.monitor }
}
