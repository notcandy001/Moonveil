pragma ComponentBehavior: Bound

import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import qs
import qs.modules
import qs.modules.uikit
import qs.modules.widgets.dashboard
import qs.modules.theme
import qs.modules.components
import qs.modules.globals as AmbxstGlobals
import qs.modules.services as AmbxstSvc
import qs.config

// CrescentDashboard - Ambxst dashboard in floating overlay
// Lives in panelFamilies/ so it's in Quickshell's qs.* context

Scope {
    id: dashScope

    Variants {
        model: Quickshell.screens

        LazyLoader {
            id: dashLoader
            required property ShellScreen modelData
            active: GlobalStates.dashboardOpen && Config.themeReady

            component: PanelWindow {
                id: dashWindow
                screen: dashLoader.modelData

                anchors { top: true; bottom: true; left: true; right: true }
                color: "transparent"
                exclusionMode: ExclusionMode.Ignore

                WlrLayershell.namespace:     "crescentshell:dashboard"
                WlrLayershell.layer:         WlrLayer.Overlay
                WlrLayershell.keyboardFocus: GlobalStates.dashboardOpen
                    ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

                // Dim backdrop
                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(0, 0, 0, 0.6)
                    opacity: GlobalStates.dashboardOpen ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                    MouseArea {
                        anchors.fill: parent
                        enabled: GlobalStates.dashboardOpen
                        onClicked: GlobalStates.dashboardOpen = false
                    }
                }

                // Dashboard panel
                Item {
                    id: panel
                    width:  Math.min(960, dashWindow.width  - 60)
                    height: Math.min(620, dashWindow.height - 60)
                    anchors.centerIn: parent

                    scale:   GlobalStates.dashboardOpen ? 1.0 : 0.88
                    opacity: GlobalStates.dashboardOpen ? 1.0 : 0.0
                    Behavior on scale   { NumberAnimation { duration: 240; easing.type: Easing.OutBack; easing.overshoot: 1.05 } }
                    Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutQuart } }

                    MouseArea { anchors.fill: parent; onClicked: {} }

                    // Ambxst Dashboard loaded directly (we're in qs.* context)
                    Dashboard {
                        anchors.fill: parent
                        leftPanelWidth: 270
                        // NotchAnimationBehavior requires isVisible to show content
                        isVisible: true

                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Escape) {
                                GlobalStates.dashboardOpen = false
                                event.accepted = true
                            }
                        }
                        Component.onCompleted: Qt.callLater(() => forceActiveFocus())
                    }
                }
            }
        }
    }
}
