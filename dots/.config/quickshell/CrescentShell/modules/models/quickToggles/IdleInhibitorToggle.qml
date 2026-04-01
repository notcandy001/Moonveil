import QtQuick
import Quickshell
import qs
import qs.services
import qs.modules
import qs.modules.functions
import qs.modules.uikit

QuickToggleModel {
    name: Translation.tr("Keep awake")

    toggled: Idle.inhibit
    icon: "coffee"
    mainAction: () => {
        Idle.toggleInhibit()
    }
    tooltipText: Translation.tr("Keep system awake")
}
