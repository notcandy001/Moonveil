import qs
import qs.services
import qs.core
import qs.core.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Hyprland

import qs.shell.notifications
import qs.shell.notifications.quickToggles
import qs.shell.notifications.quickToggles.classicStyle
import qs.shell.notifications.quickToggles.androidStyle
import qs.shell.notifications.bluetoothDevices
import qs.shell.notifications.nightLight
import qs.shell.notifications.volumeMixer
import qs.shell.notifications.wifiNetworks

Item {
    id: root
    required property var scopeRoot
    property int sidebarPadding: 10
    property string settingsQmlPath: Quickshell.shellPath("settings.qml")
    property bool showAudioOutputDialog: false
    property bool showAudioInputDialog: false
    property bool showBluetoothDialog: false
    property bool showNightLightDialog: false
    property bool showWifiDialog: false
    property bool editMode: false

    Connections {
        target: GlobalStates
        function onSidebarLeftOpenChanged() {
            if (!GlobalStates.sidebarLeftOpen) {
                root.showWifiDialog = false
                root.showBluetoothDialog = false
                root.showAudioOutputDialog = false
                root.showAudioInputDialog = false
            }
        }
    }

    anchors.fill: parent

    ColumnLayout {
        anchors {
            fill: parent
            margins: sidebarPadding
        }
        spacing: sidebarPadding

        // ── Top button row ────────────────────────────────────
        Item {
            Layout.fillWidth: true
            implicitHeight: Math.max(uptimePill.implicitHeight, actionButtons.implicitHeight)

            // Uptime pill
            Rectangle {
                id: uptimePill
                anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                color: Appearance.colors.colLayer1
                radius: height / 2
                implicitWidth: uptimeRow.implicitWidth + 24
                implicitHeight: uptimeRow.implicitHeight + 8
                Row {
                    id: uptimeRow
                    anchors.centerIn: parent
                    spacing: 8
                    CustomIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 25; height: 25
                        source: SystemInfo.distroIcon
                        colorize: true
                        color: Appearance.colors.colOnLayer0
                    }
                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colOnLayer0
                        text: Translation.tr("Up %1").arg(DateTime.uptime)
                    }
                }
            }

            // Action buttons
            ButtonGroup {
                id: actionButtons
                anchors { top: parent.top; bottom: parent.bottom; right: parent.right }
                color: Appearance.colors.colLayer1
                padding: 4

                QuickToggleButton {
                    toggled: false
                    buttonIcon: "restart_alt"
                    onClicked: { Hyprland.dispatch("reload"); Quickshell.reload(true) }
                    StyledToolTip { text: Translation.tr("Reload Hyprland & Quickshell") }
                }
                QuickToggleButton {
                    toggled: false
                    buttonIcon: "settings"
                    onClicked: {
                        GlobalStates.sidebarLeftOpen = false
                        Quickshell.execDetached(["qs", "-p", root.settingsQmlPath])
                    }
                    StyledToolTip { text: Translation.tr("Settings") }
                }
                QuickToggleButton {
                    toggled: false
                    buttonIcon: "power_settings_new"
                    onClicked: GlobalStates.sessionOpen = true
                    StyledToolTip { text: Translation.tr("Session") }
                }
            }
        }

        // ── Sliders ───────────────────────────────────────────
        Loader {
            Layout.fillWidth: true
            visible: active
            active: {
                const c = Config.options.sidebar.quickSliders
                if (!c.enable) return false
                return c.showMic || c.showVolume || c.showBrightness
            }
            sourceComponent: QuickSliders {}
        }

        // ── Quick toggles (classic) ───────────────────────────
        LoaderedQuickPanel {
            styleName: "classic"
            sourceComponent: ClassicQuickPanel {}
        }

        // ── Quick toggles (android) ───────────────────────────
        LoaderedQuickPanel {
            styleName: "android"
            sourceComponent: AndroidQuickPanel { editMode: root.editMode }
        }

        // ── Bottom widgets (calendar/todo/timer) ──────────────
        BottomWidgetGroup {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillHeight: false
            Layout.fillWidth: true
            Layout.preferredHeight: implicitHeight
        }
    }

    // ── Dialogs ───────────────────────────────────────────────
    ToggleDialog { shownPropertyString: "showAudioOutputDialog"; dialog: VolumeDialog { isSink: true } }
    ToggleDialog { shownPropertyString: "showAudioInputDialog";  dialog: VolumeDialog { isSink: false } }
    ToggleDialog {
        shownPropertyString: "showBluetoothDialog"
        dialog: BluetoothDialog {}
        onShownChanged: {
            if (!shown) Bluetooth.defaultAdapter.discovering = false
            else { Bluetooth.defaultAdapter.enabled = true; Bluetooth.defaultAdapter.discovering = true }
        }
    }
    ToggleDialog { shownPropertyString: "showNightLightDialog"; dialog: NightLightDialog {} }
    ToggleDialog {
        shownPropertyString: "showWifiDialog"
        dialog: WifiDialog {}
        onShownChanged: { if (!shown) return; Network.enableWifi(); Network.rescanWifi() }
    }

    component ToggleDialog: Loader {
        id: tdl
        required property string shownPropertyString
        property alias dialog: tdl.sourceComponent
        readonly property bool shown: root[shownPropertyString]
        anchors.fill: parent
        onShownChanged: if (shown) tdl.active = true
        active: shown
        onActiveChanged: { if (active) { item.show = true; item.forceActiveFocus() } }
        Connections {
            target: tdl.item
            function onDismiss() { tdl.item.show = false; root[tdl.shownPropertyString] = false }
            function onVisibleChanged() { if (!tdl.item.visible && !root[tdl.shownPropertyString]) tdl.active = false }
        }
    }

    component LoaderedQuickPanel: Loader {
        id: lqp
        required property string styleName
        Layout.alignment: item?.Layout.alignment ?? Qt.AlignHCenter
        Layout.fillWidth: item?.Layout.fillWidth ?? false
        visible: active
        active: Config.options.sidebar.quickToggles.style === styleName
        Connections {
            target: lqp.item
            function onOpenAudioOutputDialog() { root.showAudioOutputDialog = true }
            function onOpenAudioInputDialog()  { root.showAudioInputDialog = true }
            function onOpenBluetoothDialog()   { root.showBluetoothDialog = true }
            function onOpenNightLightDialog()  { root.showNightLightDialog = true }
            function onOpenWifiDialog()        { root.showWifiDialog = true }
        }
    }
}
