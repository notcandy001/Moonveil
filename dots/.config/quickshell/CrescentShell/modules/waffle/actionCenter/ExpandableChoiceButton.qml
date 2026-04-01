import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.services.network
import qs.modules
import qs.modules.functions
import qs.modules.uikit
import qs.modules.waffle.looks


WChoiceButton {
    id: root

    property bool expanded: false
    checked: expanded
    clip: true

    horizontalPadding: 12
    verticalPadding: 6
    animateChoiceHighlight: false

    Behavior on implicitHeight {
        animation: Looks.transition.resize.createObject(this)
    }
    onClicked: expanded = !expanded
}
