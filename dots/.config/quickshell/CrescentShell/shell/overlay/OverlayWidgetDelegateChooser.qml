pragma ComponentBehavior: Bound
import qs.services
import qs.core
import qs.core.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import qs.shell.overlay.crosshair
import qs.shell.overlay.volumeMixer
import qs.shell.overlay.floatingImage
import qs.shell.overlay.fpsLimiter
import qs.shell.overlay.recorder
import qs.shell.overlay.resources
import qs.shell.overlay.notes

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
