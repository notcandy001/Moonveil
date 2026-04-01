import QtQuick
import QtQuick.Layouts
import qs.modules
import qs.modules.uikit

RowLayout {
    id: root
    required property string icon
    required property string label
    required property string value
    spacing: 4

    MaterialSymbol {
        text: root.icon
        color: Appearance.colors.colOnSurfaceVariant
        iconSize: Appearance.font.pixelSize.large
    }
    StyledText {
        text: root.label
        color: Appearance.colors.colOnSurfaceVariant
    }
    StyledText {
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignRight
        visible: root.value !== ""
        color: Appearance.colors.colOnSurfaceVariant
        text: root.value
    }
}
