import qs
import qs.services
import qs.modules
import qs.modules.uikit
import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.modules.crescentshell.sidebarRight
import qs.modules.crescentshell.sidebarRight.notifications
import qs.modules.crescentshell.sidebarRight.quickToggles.classicStyle

Item {
    id: root
    property int sidebarWidth: Appearance.sizes.sidebarWidth
    property int sidebarPadding: 10

    implicitHeight: sidebarRightBackground.implicitHeight
    implicitWidth: sidebarRightBackground.implicitWidth

    StyledRectangularShadow {
        target: sidebarRightBackground
    }

    Rectangle {
        id: sidebarRightBackground
        anchors.fill: parent
        implicitHeight: parent.height - Appearance.sizes.hyprlandGapsOut * 2
        implicitWidth: sidebarWidth - Appearance.sizes.hyprlandGapsOut * 2
        color: Appearance.colors.colLayer0
        border.width: 1
        border.color: Appearance.colors.colLayer0Border
        radius: Appearance.rounding.screenRounding - Appearance.sizes.hyprlandGapsOut + 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: sidebarPadding
            spacing: sidebarPadding

            // Header
            Item {
                Layout.fillWidth: true
                implicitHeight: headerRow.implicitHeight + 8

                Row {
                    id: headerRow
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                    spacing: 8
                    MaterialSymbol {
                        text: "notifications"
                        iconSize: Appearance.font.pixelSize.larger
                        color: Appearance.colors.colOnLayer0
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    StyledText {
                        text: Translation.tr("Notifications")
                        font.pixelSize: Appearance.font.pixelSize.larger
                        color: Appearance.colors.colOnLayer0
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                // Clear all button
                ButtonGroup {
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    color: Appearance.colors.colLayer1
                    padding: 4
                    QuickToggleButton {
                        toggled: false
                        buttonIcon: "delete_sweep"
                        onClicked: Notifications.clearAll()
                        StyledToolTip { text: Translation.tr("Clear all") }
                    }
                }
            }

            // Notifications list fills the rest
            CenterWidgetGroup {
                Layout.alignment: Qt.AlignHCenter
                Layout.fillHeight: true
                Layout.fillWidth: true
            }
        }
    }
}
