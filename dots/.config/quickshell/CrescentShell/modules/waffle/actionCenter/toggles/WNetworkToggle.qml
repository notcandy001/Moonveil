import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules
import qs.modules.functions
import qs.modules.waffle.looks
import qs.modules.waffle.actionCenter

ActionCenterToggle {
    id: root

    name: Network.ethernet ? Translation.tr("Network") : Network.networkName


}
