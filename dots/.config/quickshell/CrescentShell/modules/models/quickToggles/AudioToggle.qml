import QtQuick
import qs.services
import qs.modules
import qs.modules.functions
import qs.modules.uikit

QuickToggleModel {
    name: Translation.tr("Audio output")
    statusText: toggled ? Translation.tr("Unmuted") : Translation.tr("Muted")
    tooltipText: Translation.tr("Audio output | Right-click for volume mixer & device selector")
    toggled: !Audio.sink?.audio?.muted
    icon: Audio.sink?.audio?.muted ? "volume_off" : "volume_up"
    mainAction: () => {
        Audio.toggleMute()
    }
    hasMenu: true
}
