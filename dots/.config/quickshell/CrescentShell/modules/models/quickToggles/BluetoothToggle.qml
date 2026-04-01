import QtQuick
import Quickshell.Bluetooth
import qs.services
import qs.modules
import qs.modules.functions
import qs.modules.uikit

QuickToggleModel {
    name: Translation.tr("Bluetooth")
    statusText: BluetoothStatus.firstActiveDevice?.name ?? Translation.tr("Not connected")
    tooltipText: Translation.tr("%1 | Right-click to configure").arg(
        (BluetoothStatus.firstActiveDevice?.name ?? Translation.tr("Bluetooth"))
        + (BluetoothStatus.activeDeviceCount > 1 ? ` +${BluetoothStatus.activeDeviceCount - 1}` : "")
    )
    icon: BluetoothStatus.connected ? "bluetooth_connected" : BluetoothStatus.enabled ? "bluetooth" : "bluetooth_disabled"

    available: BluetoothStatus.available
    toggled: BluetoothStatus.enabled
    mainAction: () => {
        Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter?.enabled
    }
    hasMenu: true
}
