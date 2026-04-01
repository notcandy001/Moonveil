import qs.modules
import qs.modules.models.quickToggles
import qs.modules.uikit
import qs.services
import QtQuick
import Quickshell
import Quickshell.Io

AndroidQuickToggleButton {
    id: root

    toggleModel: CloudflareWarpToggle {}
}
