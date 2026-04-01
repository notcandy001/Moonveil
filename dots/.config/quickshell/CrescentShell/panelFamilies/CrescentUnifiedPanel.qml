pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs
import qs.modules
import qs.modules.uikit
import qs.modules.unified.notch
import qs.modules.services
import qs.modules.globals as AmbxstGlobals
import qs.modules.widgets.launcher
import qs.modules.widgets.dashboard
import qs.modules.widgets.powermenu
import qs.modules.widgets.tools
import qs.modules.widgets.defaultview
import qs.config
import qs.modules.crescentshell.bar

// CrescentUnifiedPanel
// A fullscreen overlay window that hosts:
//   - Our LeftContainer (launcher btn + workspaces) on the left
//   - Ambxst's NotchContent in the center (launcher, dashboard, powermenu all via StackView)
//   - Our RightContainer (systray + system pill) on the right
// Uses a mask so clicks pass through empty areas.

Scope {
    id: root

    Variants {
        model: Quickshell.screens

        LazyLoader {
            id: loader
            required property ShellScreen modelData
            active: true

            component: PanelWindow {
                id: panel
                screen: loader.modelData

                anchors { top: true; bottom: true; left: true; right: true }
                color: "transparent"
                exclusionMode: ExclusionMode.Ignore
                exclusiveZone: 50  // Reserve space at top for bar

                WlrLayershell.namespace:     "crescentshell:bar"
                WlrLayershell.layer:         WlrLayer.Overlay
                WlrLayershell.keyboardFocus: (notchContentLoader.item && notchContentLoader.item.screenNotchOpen)
                    ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

                // Mask: only the bar strip + notch expanded area are interactive
                mask: Region {
                    regions: [
                        Region { item: barStrip },
                        Region { item: notchContentLoader.item ? notchContentLoader.item.notchHitbox : null }
                    ]
                }

                // Register with Ambxst's Visibilities so launcher/dashboard work
                Component.onCompleted: {
                    Visibilities.registerBarPanel(screen.name, panel)
                    Visibilities.registerNotchPanel(screen.name, panel)
                }
                Component.onDestruction: {
                    Visibilities.unregisterBarPanel(screen.name)
                    Visibilities.unregisterNotchPanel(screen.name)
                    Visibilities.unregisterNotch(screen.name)
                }

                // Register notch once NotchContent is loaded
                Connections {
                    target: notchContentLoader
                    function onLoaded() {
                        Visibilities.registerNotch(panel.screen.name, notchContentLoader.item.notchContainerRef)
                    }
                }

                // Focus grab when notch is open
                HyprlandFocusGrab {
                    id: focusGrab
                    windows: [panel]
                    active: notchContentLoader.item ? notchContentLoader.item.screenNotchOpen : false
                    onCleared: { Visibilities.setActiveModule("") }
                }

                // ── BAR STRIP (our pills) ──────────────────────
                Item {
                    id: barStrip
                    anchors { top: parent.top; left: parent.left; right: parent.right }
                    height: 50

                    // Left pill
                    LeftContainer {
                        id: leftPill
                        monitor: panel.screen
                        anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 14 }
                        onLauncherRequested: Visibilities.setActiveModule("launcher")
                    }

                    // Center: stable notch pill (time + title, click = open dashboard)
                    Notch {
                        id: notchPill
                        anchors { horizontalCenter: parent.horizontalCenter; verticalCenter: parent.verticalCenter }
                    }

                    // Right pill
                    RightContainer {
                        id: rightPill
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter; rightMargin: 14 }
                    }
                }

                // ── AMBXST NOTCH (center, fullscreen positioned) ──
                // Loaded only after Config is ready to avoid crashes from null Config properties
                Loader {
                    id: notchContentLoader
                    anchors.fill: parent
                    active: Config.notchReady && Config.themeReady
                    sourceComponent: Component {
                        NotchContent {
                            id: notchContent
                            anchors.fill: parent
                            screen: panel.screen
                            // Hide Ambxst's notch pill when idle - our stable pill shows instead
                            forceHideWhenIdle: true
                        }
                    }
                }


            }
        }
    }
}
