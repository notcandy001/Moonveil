
import qs.services
import qs.modules
import qs.modules.uikit
import QtQuick

Rectangle {
    id: rect
    readonly property string dialStyle: Config.options.background.widgets.clock.cookie.dialNumberStyle

    StyledText {
        anchors.centerIn: parent
        color: Appearance.colors.colSecondaryHover
        text: Qt.locale().toString(DateTime.clock.date, "dd")
        font {
            family: Appearance.font.family.expressive
            pixelSize: 20
            weight: 1000
        }
    }
}
