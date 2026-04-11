import qs.modules
import qs.modules.theme
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root
    property string text: ""
    property string icon
    property alias value: spinBoxWidget.value
    property alias stepSize: spinBoxWidget.stepSize
    property alias from: spinBoxWidget.from
    property alias to: spinBoxWidget.to
    spacing: 10
    Layout.leftMargin: 10
    Layout.rightMargin: 10
    Layout.fillWidth: true
    implicitHeight: 40

    OptionalMaterialSymbol {
        icon: root.icon
        iconSize: Appearance.font.pixelSize.larger
        opacity: root.enabled ? 1 : 0.4
    }

    StyledText {
        Layout.fillWidth: true
        text: root.text
        color: Colors.overBackground
        font.pixelSize: Appearance.font.pixelSize.small
        opacity: root.enabled ? 1 : 0.4
    }

    // Compact spinbox
    Rectangle {
        implicitWidth: spinRow.implicitWidth + 8
        implicitHeight: 30
        radius: Styling.radius(-2)
        color: Colors.surfaceContainerLow
        border.width: 1
        border.color: Qt.rgba(Colors.outlineVariant.r, Colors.outlineVariant.g, Colors.outlineVariant.b, 0.5)

        Row {
            id: spinRow
            anchors.centerIn: parent
            spacing: 0

            // Decrement
            Rectangle {
                width: 28; height: 28; radius: Styling.radius(-3)
                color: decMA.containsMouse ? Colors.surfaceContainerHigh : "transparent"
                Behavior on color { ColorAnimation { duration: 80 } }
                Text {
                    anchors.centerIn: parent; text: "−"
                    font.pixelSize: 16; color: Colors.overSurfaceVariant
                }
                MouseArea { id: decMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: spinBoxWidget.decrease() }
            }

            // Value display
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: spinBoxWidget.value
                font.family: Config.theme.font
                font.pixelSize: Styling.fontSize(0)
                color: Colors.overBackground
                horizontalAlignment: Text.AlignHCenter
                width: 38
            }

            // Increment
            Rectangle {
                width: 28; height: 28; radius: Styling.radius(-3)
                color: incMA.containsMouse ? Colors.surfaceContainerHigh : "transparent"
                Behavior on color { ColorAnimation { duration: 80 } }
                Text {
                    anchors.centerIn: parent; text: "+"
                    font.pixelSize: 16; color: Colors.overSurfaceVariant
                }
                MouseArea { id: incMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: spinBoxWidget.increase() }
            }
        }
    }

    StyledSpinBox {
        id: spinBoxWidget
        visible: false
        value: root.value
    }
}
