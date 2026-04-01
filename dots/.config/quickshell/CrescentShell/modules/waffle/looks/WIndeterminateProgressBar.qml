import QtQuick
import Qt5Compat.GraphicalEffects
import qs
import qs.services
import qs.services.network
import qs.modules
import qs.modules.uikit


StyledIndeterminateProgressBar {
    id: progressBar
    implicitHeight: 3
    background: null
    layer.enabled: true
    layer.effect: OpacityMask {
        maskSource: Rectangle {
            width: progressBar.width
            height: progressBar.height
            radius: progressBar.height / 2
        }
    }
}
