import qs
import qs.services
import qs.modules
import qs.modules.uikit
import qs.modules.functions
import QtQuick
import Quickshell
import Quickshell.Wayland

FullscreenPolkitWindow {
    id: root
    contentComponent: Component {
        WPolkitContent {}
    }
}
