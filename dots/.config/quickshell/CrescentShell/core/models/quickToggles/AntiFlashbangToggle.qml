import QtQuick
import qs.services
import qs.core
import qs.core.functions
import qs.core.widgets

QuickToggleModel {
    name: Translation.tr("Anti-flashbang")
    tooltipText: Translation.tr("Anti-flashbang")
    icon: "flash_off"
    toggled: Config.options.light.antiFlashbang.enable

    mainAction: () => {
        Config.options.light.antiFlashbang.enable = !Config.options.light.antiFlashbang.enable;
    }
    hasMenu: true
}
