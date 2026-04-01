pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import qs
import qs.services
import qs.modules
import qs.modules.uikit

Row {
    id: root
    spacing: 8

    // SysTray pill
    Rectangle {
        height: 32; width: Math.max(trayRow.implicitWidth + 20, 36)
        radius: 16
        color: Appearance.m3colors.m3surfaceContainerLow
        visible: trayRow.implicitWidth > 0
        Row {
            id: trayRow; anchors.centerIn: parent; spacing: 6
            SysTray { height: 20; invertSide: false }
        }
    }

    // Power profile button
    Rectangle {
        id: powerProfileBtn
        height: 32; width: 32; radius: 16
        color: Appearance.m3colors.m3surfaceContainerLow
        property string currentProfile: "balanced"
        property bool menuOpen: false

        Component.onCompleted: {
            getProfile.running = true
        }

        Process {
            id: getProfile
            command: ["powerprofilesctl", "get"]
            running: false
            stdout: SplitParser {
                onRead: data => powerProfileBtn.currentProfile = data.trim()
            }
        }

        MaterialSymbol {
            anchors.centerIn: parent
            iconSize: 16
            color: Appearance.m3colors.m3onSurface
            text: {
                if (powerProfileBtn.currentProfile === "power-saver") return "battery_saver"
                if (powerProfileBtn.currentProfile === "performance") return "bolt"
                return "balance"
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: powerProfileBtn.menuOpen = !powerProfileBtn.menuOpen
        }

        // Dropdown
        Rectangle {
            id: profileMenu
            visible: powerProfileBtn.menuOpen
            anchors.top: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: 6
            width: 160; radius: 12
            color: Appearance.m3colors.m3surfaceContainer
            height: profileCol.implicitHeight + 16
            z: 999
            clip: false
            parent: powerProfileBtn.parent.parent

            Column {
                id: profileCol
                anchors { top: parent.top; left: parent.left; right: parent.right; margins: 8 }
                spacing: 4

                Repeater {
                    model: [
                        { id: "power-saver", icon: "battery_saver", label: "Power Saving" },
                        { id: "balanced",    icon: "balance",        label: "Balanced"     },
                        { id: "performance", icon: "bolt",           label: "Performance"  }
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        width: parent.width; height: 36; radius: 8
                        color: powerProfileBtn.currentProfile === modelData.id
                            ? Appearance.colors.colPrimary
                            : "transparent"

                        Row {
                            anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: 8 }
                            spacing: 8
                            MaterialSymbol {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.icon; iconSize: 16
                                color: powerProfileBtn.currentProfile === modelData.id
                                    ? Appearance.m3colors.m3onPrimary
                                    : Appearance.m3colors.m3onSurface
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.label
                                font.pixelSize: 12
                                color: powerProfileBtn.currentProfile === modelData.id
                                    ? Appearance.m3colors.m3onPrimary
                                    : Appearance.m3colors.m3onSurface
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                Quickshell.execDetached(["powerprofilesctl", "set", modelData.id])
                                powerProfileBtn.currentProfile = modelData.id
                                powerProfileBtn.menuOpen = false
                            }
                        }
                    }
                }
            }
        }
    }

    // System pill: battery · wifi · notif dot
    Rectangle {
        height: 32; width: sysRow.implicitWidth + 20
        radius: 16
        color: Appearance.m3colors.m3surfaceContainerLow
        MouseArea {
            anchors.fill: parent
            onClicked: GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen
        }
        Row {
            id: sysRow; anchors.centerIn: parent; spacing: 8

            // End-4's BatteryIndicator (bolt+progress bar style)
            BatteryIndicator {
                anchors.verticalCenter: parent.verticalCenter
                visible: Battery.available
            }

            // Network icon
            MaterialSymbol {
                anchors.verticalCenter: parent.verticalCenter
                text: Network.materialSymbol
                iconSize: 15
                color: Appearance.m3colors.m3onSurface
            }

            // Notification dot
            Rectangle {
                width: 7; height: 7; radius: 4
                anchors.verticalCenter: parent.verticalCenter
                color: Notifications.unread > 0
                    ? Appearance.m3colors.m3error
                    : Appearance.m3colors.m3outline
                visible: Notifications.unread > 0
                Behavior on color { ColorAnimation { duration: 200 } }
            }
        }
    }
}
