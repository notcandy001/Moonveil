import QtQuick
import Quickshell

import qs.core

LazyLoader {
    property bool extraCondition: true
    active: Config.ready && extraCondition
}
