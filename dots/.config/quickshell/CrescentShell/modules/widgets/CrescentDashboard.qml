pragma ComponentBehavior: Bound

import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import qs
import qs.modules
import qs.modules.uikit

// CrescentDashboard
// Hosts the Ambxst Dashboard in a floating overlay.
// LAZY — the Ambxst modules only load when first opened.

Scope {
    id: dashScope

    Variants {
        model: Quickshell.screens

        // LazyLoader: only becomes active when dashboard is open
        LazyLoader {
            id: dashLoader
            required property ShellScreen modelData
            // Load on first open, stay loaded after that
            active: GlobalStates.dashboardOpen

            component: PanelWindow {
                id: dashWindow
                screen: dashLoader.modelData

                anchors { top: true; bottom: true; left: true; right: true }
                color: "transparent"
                exclusionMode: ExclusionMode.Ignore

                WlrLayershell.namespace:     "crescentshell:dashboard"
                WlrLayershell.layer:         WlrLayer.Overlay
                WlrLayershell.keyboardFocus: GlobalStates.dashboardOpen
                    ? WlrKeyboardFocus.OnDemand
                    : WlrKeyboardFocus.None

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
                    height: Math.min(600, dashWindow.height - 60)
                    anchors.centerIn: parent

                    scale:   GlobalStates.dashboardOpen ? 1.0 : 0.88
                    opacity: GlobalStates.dashboardOpen ? 1.0 : 0.0
                    Behavior on scale   { NumberAnimation { duration: 240; easing.type: Easing.OutBack; easing.overshoot: 1.05 } }
                    Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutQuart } }

                    // Block clicks falling through
                    MouseArea { anchors.fill: parent; onClicked: {} }

                    // Load Ambxst Dashboard
                    Loader {
                        id: ambxstLoader
                        anchors.fill: parent
                        active: true
                        source: Qt.resolvedUrl("dashboard/DashboardView.qml")
                        onStatusChanged: {
                            if (status === Loader.Error)
                                console.warn("[CrescentDashboard] Ambxst load failed")
                        }
                    }
                }

    
            }
        }
    }
}
