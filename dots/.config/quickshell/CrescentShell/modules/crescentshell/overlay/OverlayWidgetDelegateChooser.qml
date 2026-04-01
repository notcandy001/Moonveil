pragma ComponentBehavior: Bound
import qs.services
import qs.modules
import qs.modules.uikit
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import qs.modules.crescentshell.overlay.crosshair
import qs.modules.crescentshell.overlay.volumeMixer
import qs.modules.crescentshell.overlay.floatingImage
import qs.modules.crescentshell.overlay.fpsLimiter
import qs.modules.crescentshell.overlay.recorder
import qs.modules.crescentshell.overlay.resources
import qs.modules.crescentshell.overlay.notes

DelegateChooser {
    id: root
    role: "identifier"

    DelegateChoice { roleValue: "crosshair"; Crosshair {} }
    DelegateChoice { roleValue: "floatingImage"; FloatingImage {} }
    DelegateChoice { roleValue: "fpsLimiter"; FpsLimiter {} }
    DelegateChoice { roleValue: "recorder"; Recorder {} }
    DelegateChoice { roleValue: "resources"; Resources {} }
    DelegateChoice { roleValue: "notes"; Notes {} }
    DelegateChoice { roleValue: "volumeMixer"; VolumeMixer {} }
}
