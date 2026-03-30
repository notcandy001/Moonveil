import qs.core
import qs.core.models.quickToggles
import qs.core.widgets
import qs.services
import QtQuick
import Quickshell
import Quickshell.Io

AndroidQuickToggleButton {
    id: root

    toggleModel: CloudflareWarpToggle {}
}
