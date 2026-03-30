import qs
import qs.services
import qs.core
import qs.core.widgets
import qs.core.functions
import QtQuick
import Quickshell
import Quickshell.Wayland

FullscreenPolkitWindow {
    id: root
    contentComponent: Component {
        PolkitContent {}
    }
}
