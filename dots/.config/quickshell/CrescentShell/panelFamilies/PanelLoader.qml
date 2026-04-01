import QtQuick
import Quickshell

import qs.modules

LazyLoader {
    property bool extraCondition: true
    active: Config.ready && extraCondition
}
