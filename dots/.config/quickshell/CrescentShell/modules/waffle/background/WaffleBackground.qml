pragma ComponentBehavior: Bound

import qs
import qs.services
import qs.modules
import qs.modules.uikit
import qs.modules.uikit.widgetCanvas
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

import qs.modules.crescentshell.background.widgets
import qs.modules.crescentshell.background.widgets.clock
import qs.modules.crescentshell.background.widgets.weather

Variants {
    id: root
    model: Quickshell.screens

    PanelWindow {
        id: panelRoot
        required property var modelData

        screen: modelData
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.namespace: "crescentshell:background"
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        color: "transparent"

        StyledImage {
            anchors.fill: parent
            source: Config.options.background.wallpaperPath
            fillMode: Image.PreserveAspectCrop
        }
    }
}
