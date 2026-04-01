import qs.services
import qs.modules
import qs.modules.models.quickToggles
import qs.modules.functions
import qs.modules.uikit
import QtQuick
import Quickshell
import Quickshell.Bluetooth

AndroidQuickToggleButton {
    id: root
    
    toggleModel: BluetoothToggle {}
}
