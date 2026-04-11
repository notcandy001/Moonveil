pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.theme
import qs.modules.components
import qs.modules.globals
import Quickshell
import Quickshell.Io
import qs.config
import Qt5Compat.GraphicalEffects

Item {
    id: root

    property int maxContentWidth: 480
    readonly property int contentWidth: Math.min(width, maxContentWidth)
    readonly property real sideMargin: (width - contentWidth) / 2

    property string currentSection: ""
    property string selectedVariant: "bg"

    // ── Reusable: Section nav button ─────────────────────────────────────
    component SectionButton: Rectangle {
        id: secBtn
        required property string text
        required property string sectionId

        Layout.fillWidth: true
        Layout.preferredHeight: 52
        radius: Styling.radius(0)
        color: secMA.containsMouse ? Colors.surfaceContainerHigh : Colors.surfaceContainer
        border.width: 1
        border.color: secMA.containsMouse
            ? Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.55)
            : Qt.rgba(Colors.outlineVariant.r, Colors.outlineVariant.g, Colors.outlineVariant.b, 0.4)

        Behavior on color        { ColorAnimation { duration: Appearance.animation.elementMoveFast.duration } }
        Behavior on border.color { ColorAnimation { duration: Appearance.animation.elementMoveFast.duration } }

        RowLayout {
            anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
            spacing: 10

            Rectangle {
                width: 4; height: 4; radius: 2
                color: secMA.containsMouse ? Colors.primary : Colors.outline
                Behavior on color { ColorAnimation { duration: 120 } }
            }

            Text {
                Layout.fillWidth: true
                text: secBtn.text
                font.family: Config.theme.font
                font.pixelSize: Styling.fontSize(0)
                font.weight: Font.Medium
                color: secMA.containsMouse ? Colors.overBackground : Colors.overSurfaceVariant
                Behavior on color { ColorAnimation { duration: 120 } }
            }

            Text {
                text: Icons.caretRight
                font.family: Icons.font
                font.pixelSize: 13
                color: secMA.containsMouse ? Colors.primary : Colors.outlineVariant
                Behavior on color { ColorAnimation { duration: 120 } }
            }
        }

        MouseArea {
            id: secMA; anchors.fill: parent; hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.currentSection = secBtn.sectionId
        }
    }

    // ── Reusable: Section label ──────────────────────────────────────────
    component SectionLabel: Text {
        Layout.fillWidth: true
        font.family: Config.theme.font
        font.pixelSize: Styling.fontSize(-2)
        font.weight: Font.SemiBold
        font.letterSpacing: 1.4
        color: Colors.overSurfaceVariant
        opacity: 0.75
        topPadding: 8
        bottomPadding: 2
    }

    // ── Reusable: Thin divider ───────────────────────────────────────────
    component Divider: Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Qt.rgba(Colors.outlineVariant.r, Colors.outlineVariant.g, Colors.outlineVariant.b, 0.4)
        Layout.topMargin: 4
        Layout.bottomMargin: 4
    }

    // ── Reusable: Pill toggle ────────────────────────────────────────────
    component PillSwitch: Item {
        id: ps
        property bool checked: false
        signal toggled(bool val)

        implicitWidth: 40; implicitHeight: 22

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: ps.checked ? Colors.primary : Colors.surfaceContainerHighest
            border.width: 1
            border.color: ps.checked
                ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.6)
                : Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.5)
            Behavior on color        { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }

            Rectangle {
                x: ps.checked ? parent.width - width - 3 : 3
                y: 3; width: parent.height - 6; height: width; radius: width / 2
                color: ps.checked ? Colors.overPrimary : Colors.overSurfaceVariant
                Behavior on x     { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation  { duration: 150 } }
            }
        }

        MouseArea {
            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
            onClicked: { ps.checked = !ps.checked; ps.toggled(ps.checked) }
        }
    }

    // ── Reusable: Compact text input ─────────────────────────────────────
    component MiniInput: Rectangle {
        id: mi
        property alias text: ti.text
        property alias placeholderText: ph.text
        property alias validator: ti.validator
        signal editingFinished()

        Layout.preferredHeight: 32
        color: Colors.surfaceContainerLow
        radius: Styling.radius(-2)
        border.width: ti.activeFocus ? 1 : 0
        border.color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.45)
        Behavior on border.color { ColorAnimation { duration: 100 } }

        Text {
            id: ph
            anchors { fill: parent; leftMargin: 9 }
            verticalAlignment: Text.AlignVCenter
            font.family: Config.theme.font
            font.pixelSize: Styling.fontSize(0)
            color: Colors.outlineVariant
            visible: !ti.text && !ti.activeFocus
        }

        TextInput {
            id: ti
            anchors { fill: parent; margins: 9 }
            font.family: Config.theme.font
            font.pixelSize: Styling.fontSize(0)
            color: Colors.overBackground
            selectByMouse: true
            clip: true
            verticalAlignment: TextInput.AlignVCenter
            selectionColor: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.3)
            onEditingFinished: mi.editingFinished()
        }
    }

    // ── Reusable: Value slider ───────────────────────────────────────────
    component ValueSlider: Item {
        id: vs
        property real value: 0.5
        property real stepSize: 0.01
        property color trackColor: Colors.primary
        signal valueChanged()

        implicitHeight: 18
        Layout.fillWidth: true

        // Track
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width; height: 4; radius: 2
            color: Colors.surfaceContainerHighest

            // Fill
            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, vs.value))
                height: parent.height; radius: parent.radius
                color: vs.trackColor
                Behavior on width { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }
            }
        }

        // Thumb
        Rectangle {
            id: vthumb
            x: Math.max(0, Math.min(parent.width - width, parent.width * Math.max(0, Math.min(1, vs.value)) - width / 2))
            anchors.verticalCenter: parent.verticalCenter
            width: 14; height: 14; radius: 7
            color: Colors.surfaceContainerHighest
            border.width: 2; border.color: vs.trackColor
            Behavior on x { NumberAnimation { duration: 70; easing.type: Easing.OutCubic } }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.SizeHorCursor

            function updateVal(mx) {
                let raw = Math.max(0, Math.min(1, mx / vs.width))
                if (vs.stepSize > 0) raw = Math.round(raw / vs.stepSize) * vs.stepSize
                if (Math.abs(raw - vs.value) > 0.0001) {
                    vs.value = raw
                    vs.valueChanged()
                }
            }

            onPressed:      mouse => updateVal(mouse.x)
            onPositionChanged: mouse => { if (pressed) updateVal(mouse.x) }
        }
    }

    // Color picker state
    property bool colorPickerActive: false
    property var colorPickerColorNames: []
    property string colorPickerCurrentColor: ""
    property string colorPickerDialogTitle: ""
    property var colorPickerCallback: null

    function openColorPicker(colorNames, currentColor, dialogTitle, callback) {
        colorPickerColorNames = colorNames
        colorPickerCurrentColor = currentColor
        colorPickerDialogTitle = dialogTitle
        colorPickerCallback = callback
        colorPickerActive = true
    }

    function closeColorPicker() {
        colorPickerActive = false
        colorPickerCallback = null
    }

    function handleColorSelected(color) {
        if (colorPickerCallback) colorPickerCallback(color)
        colorPickerCurrentColor = color
    }

    FileView {
        id: wallpaperConfig
        path: Quickshell.cachePath("wallpapers.json")
        JsonAdapter {
            property string currentWall: ""
            property string wallPath: ""
            property string matugenScheme: "scheme-tonal-spot"
            property string activeColorPreset: ""
        }
    }

    function srNameToId(srName) { return srName.substring(2).toLowerCase() }

    readonly property var allVariants: {
        let variants = []
        for (let prop in Config.theme) {
            if (prop.startsWith("sr") && Config.theme[prop] && typeof Config.theme[prop] === "object") {
                let label = Config.theme[prop].label || prop.substring(2)
                variants.push({ id: srNameToId(prop), label: label })
            }
        }
        return variants
    }

    function getVariantLabel(variantId) {
        for (let i = 0; i < allVariants.length; i++)
            if (allVariants[i].id === variantId) return allVariants[i].label
        return variantId
    }

    // ── Main Flickable ────────────────────────────────────────────────────
    Flickable {
        id: mainFlickable
        anchors.fill: parent
        contentHeight: mainColumn.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: !root.colorPickerActive

        opacity: root.colorPickerActive ? 0 : 1
        transform: Translate {
            x: root.colorPickerActive ? -28 : 0
            Behavior on x { NumberAnimation { duration: (Config.animDuration ?? 0) / 2; easing.type: Easing.OutQuart } }
        }
        Behavior on opacity { NumberAnimation { duration: (Config.animDuration ?? 0) / 2; easing.type: Easing.OutQuart } }

        ScrollBar.vertical: ScrollBar {
            width: 3
            contentItem: Rectangle {
                color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.5)
                radius: 2
            }
            background: Rectangle { color: "transparent" }
        }

        ColumnLayout {
            id: mainColumn
            width: mainFlickable.width
            spacing: 8

            // ── Header ────────────────────────────────────────────────
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: hdrRow.implicitHeight + 20

                RowLayout {
                    id: hdrRow
                    anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                    anchors.leftMargin: root.sideMargin + 4
                    anchors.rightMargin: root.sideMargin + 4
                    spacing: 8

                    // Back button
                    Rectangle {
                        visible: root.currentSection !== ""
                        width: 30; height: 30; radius: Styling.radius(-2)
                        color: backMA.containsMouse ? Colors.surfaceContainerHigh : Colors.surfaceContainer
                        border.width: 1
                        border.color: Qt.rgba(Colors.outlineVariant.r, Colors.outlineVariant.g, Colors.outlineVariant.b, 0.5)
                        Behavior on color { ColorAnimation { duration: 100 } }

                        Text {
                            anchors.centerIn: parent
                            text: Icons.arrowLeft
                            font.family: Icons.font
                            font.pixelSize: 14
                            color: Colors.primary
                        }
                        MouseArea { id: backMA; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor; onClicked: root.currentSection = "" }
                    }

                    // Title + status
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            text: root.currentSection === ""
                                ? "Theme"
                                : root.currentSection.charAt(0).toUpperCase() + root.currentSection.slice(1)
                            font.family: Config.theme.font
                            font.pixelSize: Styling.fontSize(1)
                            font.weight: Font.SemiBold
                            color: Colors.overBackground
                        }

                        Text {
                            visible: GlobalStates.themeHasChanges
                            text: "unsaved changes"
                            font.family: Config.theme.font
                            font.pixelSize: Styling.fontSize(-2)
                            color: Colors.error
                        }
                    }

                    // Discard
                    Rectangle {
                        visible: GlobalStates.themeHasChanges
                        width: 30; height: 30; radius: Styling.radius(-2)
                        color: discMA.containsMouse
                            ? Qt.rgba(Colors.error.r, Colors.error.g, Colors.error.b, 0.18)
                            : Colors.surfaceContainer
                        border.width: 1
                        border.color: Qt.rgba(Colors.outlineVariant.r, Colors.outlineVariant.g, Colors.outlineVariant.b, 0.5)
                        Behavior on color { ColorAnimation { duration: 100 } }

                        Text { anchors.centerIn: parent; text: Icons.arrowCounterClockwise
                            font.family: Icons.font; font.pixelSize: 14; color: Colors.error }
                        MouseArea { id: discMA; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor; onClicked: GlobalStates.discardThemeChanges() }
                        StyledToolTip { text: "Discard changes" }
                    }

                    // Apply
                    Rectangle {
                        visible: GlobalStates.themeHasChanges
                        width: 30; height: 30; radius: Styling.radius(-2)
                        color: applyMA.containsMouse
                            ? Colors.primaryContainer
                            : Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.18)
                        border.width: 1
                        border.color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.5)
                        Behavior on color { ColorAnimation { duration: 100 } }

                        Text { anchors.centerIn: parent; text: Icons.disk
                            font.family: Icons.font; font.pixelSize: 14; color: Colors.primary }
                        MouseArea { id: applyMA; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor; onClicked: GlobalStates.applyThemeChanges() }
                        StyledToolTip { text: "Apply changes" }
                    }
                }
            }

            // Header underline
            Rectangle {
                Layout.fillWidth: true; height: 1
                Layout.leftMargin: root.sideMargin; Layout.rightMargin: root.sideMargin
                color: Qt.rgba(Colors.outlineVariant.r, Colors.outlineVariant.g, Colors.outlineVariant.b, 0.4)
            }

            // ── Centered content column ────────────────────────────────
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: inner.implicitHeight

                ColumnLayout {
                    id: inner
                    width: root.contentWidth
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 8

                    // ════════════════════════════════════════════════
                    // MENU
                    // ════════════════════════════════════════════════
                    ColumnLayout {
                        visible: root.currentSection === ""
                        Layout.fillWidth: true
                        spacing: 6

                        SectionButton { text: "General"; sectionId: "general" }
                        SectionButton { text: "Shadow";  sectionId: "shadow"  }
                        SectionButton { text: "Colors";  sectionId: "colors"  }
                    }

                    // ════════════════════════════════════════════════
                    // GENERAL
                    // ════════════════════════════════════════════════
                    ColumnLayout {
                        visible: root.currentSection === "general"
                        Layout.fillWidth: true
                        spacing: 6

                        SectionLabel { text: "WALLPAPER" }

                        RowLayout {
                            Layout.fillWidth: true; spacing: 8
                            Text {
                                Layout.preferredWidth: 78
                                text: "Path"
                                font.family: Config.theme.font
                                font.pixelSize: Styling.fontSize(0)
                                color: Colors.overSurfaceVariant
                            }
                            MiniInput {
                                id: wallPathInput
                                Layout.fillWidth: true
                                placeholderText: "Default"
                                Component.onCompleted: text = wallpaperConfig.adapter.wallPath
                                onEditingFinished: {
                                    if (wallpaperConfig.adapter.wallPath !== text) {
                                        wallpaperConfig.adapter.wallPath = text
                                        wallpaperConfig.writeAdapter()
                                    }
                                }
                            }
                        }

                        Divider {}
                        SectionLabel { text: "INTERFACE" }

                        // Tint Icons
                        RowLayout {
                            Layout.fillWidth: true; spacing: 8
                            Text {
                                Layout.fillWidth: true; text: "Tint Icons"
                                font.family: Config.theme.font; font.pixelSize: Styling.fontSize(0)
                                color: Colors.overSurfaceVariant
                            }
                            PillSwitch {
                                id: tintIconsSwitch
                                checked: Config.theme.tintIcons
                                readonly property bool configValue: Config.theme.tintIcons
                                onConfigValueChanged: { if (checked !== configValue) checked = configValue }
                                onToggled: state => {
                                    if (state !== Config.theme.tintIcons) {
                                        GlobalStates.markThemeChanged(); Config.theme.tintIcons = state
                                    }
                                }
                            }
                        }

                        // Screen Corners
                        RowLayout {
                            Layout.fillWidth: true; spacing: 8
                            Text {
                                Layout.fillWidth: true; text: "Screen Corners"
                                font.family: Config.theme.font; font.pixelSize: Styling.fontSize(0)
                                color: Colors.overSurfaceVariant
                            }
                            PillSwitch {
                                id: cornersSwitch
                                checked: Config.theme.enableCorners
                                readonly property bool configValue: Config.theme.enableCorners
                                onConfigValueChanged: { if (checked !== configValue) checked = configValue }
                                onToggled: state => {
                                    if (state !== Config.theme.enableCorners) {
                                        GlobalStates.markThemeChanged(); Config.theme.enableCorners = state
                                    }
                                }
                            }
                        }

                        Divider {}
                        SectionLabel { text: "ANIMATION" }

                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 4
                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    Layout.fillWidth: true; text: "Duration"
                                    font.family: Config.theme.font; font.pixelSize: Styling.fontSize(0)
                                    color: Colors.overSurfaceVariant
                                }
                                Text {
                                    text: Config.theme.animDuration + "ms"
                                    font.family: Config.theme.font; font.pixelSize: Styling.fontSize(-1)
                                    color: Colors.primary; font.weight: Font.SemiBold
                                }
                            }
                            ValueSlider {
                                id: animSlider
                                trackColor: Colors.primary
                                readonly property real configValue: Config.theme.animDuration / 1000
                                onConfigValueChanged: { if (Math.abs(value - configValue) > 0.001) value = configValue }
                                Component.onCompleted: value = configValue
                                onValueChanged: {
                                    let d = Math.round(value * 1000)
                                    if (d !== Config.theme.animDuration) { GlobalStates.markThemeChanged(); Config.theme.animDuration = d }
                                }
                            }
                        }

                        Divider {}
                        SectionLabel { text: "TYPOGRAPHY" }

                        // UI Font row
                        RowLayout {
                            Layout.fillWidth: true; spacing: 8
                            Text {
                                Layout.preferredWidth: 78; text: "UI Font"
                                font.family: Config.theme.font; font.pixelSize: Styling.fontSize(0)
                                color: Colors.overSurfaceVariant
                            }
                            MiniInput {
                                id: fontInput; Layout.fillWidth: true
                                readonly property string configValue: Config.theme.font
                                onConfigValueChanged: { if (text !== configValue) text = configValue }
                                Component.onCompleted: text = configValue
                                onEditingFinished: {
                                    if (text !== Config.theme.font && text.trim() !== "") {
                                        GlobalStates.markThemeChanged(); Config.theme.font = text.trim()
                                    }
                                }
                            }
                            MiniInput {
                                id: fontSizeInput; Layout.preferredWidth: 52
                                validator: IntValidator { bottom: 8; top: 32 }
                                readonly property int configValue: Config.theme.fontSize
                                onConfigValueChanged: { if (text !== configValue.toString()) text = configValue.toString() }
                                Component.onCompleted: text = configValue.toString()
                                onEditingFinished: {
                                    let n = parseInt(text)
                                    if (!isNaN(n) && n >= 8 && n <= 32 && n !== Config.theme.fontSize) {
                                        GlobalStates.markThemeChanged(); Config.theme.fontSize = n
                                    }
                                }
                            }
                            Text { text: "px"; font.family: Config.theme.font; font.pixelSize: Styling.fontSize(0); color: Colors.outlineVariant }
                        }

                        // Mono font row
                        RowLayout {
                            Layout.fillWidth: true; spacing: 8
                            Text {
                                Layout.preferredWidth: 78; text: "Mono"
                                font.family: Config.theme.font; font.pixelSize: Styling.fontSize(0)
                                color: Colors.overSurfaceVariant
                            }
                            MiniInput {
                                id: monoFontInput; Layout.fillWidth: true
                                readonly property string configValue: Config.theme.monoFont
                                onConfigValueChanged: { if (text !== configValue) text = configValue }
                                Component.onCompleted: text = configValue
                                onEditingFinished: {
                                    if (text !== Config.theme.monoFont && text.trim() !== "") {
                                        GlobalStates.markThemeChanged(); Config.theme.monoFont = text.trim()
                                    }
                                }
                            }
                            MiniInput {
                                id: monoFontSizeInput; Layout.preferredWidth: 52
                                validator: IntValidator { bottom: 8; top: 32 }
                                readonly property int configValue: Config.theme.monoFontSize
                                onConfigValueChanged: { if (text !== configValue.toString()) text = configValue.toString() }
                                Component.onCompleted: text = configValue.toString()
                                onEditingFinished: {
                                    let n = parseInt(text)
                                    if (!isNaN(n) && n >= 8 && n <= 32 && n !== Config.theme.monoFontSize) {
                                        GlobalStates.markThemeChanged(); Config.theme.monoFontSize = n
                                    }
                                }
                            }
                            Text { text: "px"; font.family: Config.theme.font; font.pixelSize: Styling.fontSize(0); color: Colors.outlineVariant }
                        }

                        Divider {}
                        SectionLabel { text: "ROUNDNESS" }

                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 4
                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    Layout.fillWidth: true; text: "Corner Radius"
                                    font.family: Config.theme.font; font.pixelSize: Styling.fontSize(0)
                                    color: Colors.overSurfaceVariant
                                }
                                Text {
                                    text: Math.round(roundSlider.value * 20)
                                    font.family: Config.theme.font; font.pixelSize: Styling.fontSize(-1)
                                    color: Colors.tertiary; font.weight: Font.SemiBold
                                }
                            }
                            ValueSlider {
                                id: roundSlider
                                trackColor: Colors.tertiary
                                stepSize: 0.05
                                readonly property real configValue: Config.theme.roundness / 20
                                onConfigValueChanged: { if (Math.abs(value - configValue) > 0.001) value = configValue }
                                Component.onCompleted: value = configValue
                                onValueChanged: {
                                    let r = Math.round(value * 20)
                                    if (r !== Config.theme.roundness) { GlobalStates.markThemeChanged(); Config.theme.roundness = r }
                                }
                            }
                        }
                    }

                    // ════════════════════════════════════════════════
                    // SHADOW
                    // ════════════════════════════════════════════════
                    ColumnLayout {
                        visible: root.currentSection === "shadow"
                        Layout.fillWidth: true
                        spacing: 6

                        SectionLabel { text: "SHADOW" }

                        // Opacity
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 4
                            RowLayout {
                                Layout.fillWidth: true
                                Text { Layout.fillWidth: true; text: "Opacity"; font.family: Config.theme.font; font.pixelSize: Styling.fontSize(0); color: Colors.overSurfaceVariant }
                                Text { text: Math.round(shadowOpacitySlider.value * 100) + "%"; font.family: Config.theme.font; font.pixelSize: Styling.fontSize(-1); color: Colors.primary; font.weight: Font.SemiBold }
                            }
                            ValueSlider {
                                id: shadowOpacitySlider; trackColor: Colors.primary; stepSize: 0.01
                                readonly property real configValue: Config.theme.shadowOpacity
                                onConfigValueChanged: { if (Math.abs(value - configValue) > 0.001) value = configValue }
                                Component.onCompleted: value = configValue
                                onValueChanged: { if (Math.abs(value - Config.theme.shadowOpacity) > 0.001) { GlobalStates.markThemeChanged(); Config.theme.shadowOpacity = value } }
                            }
                        }

                        // Blur
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 4
                            RowLayout {
                                Layout.fillWidth: true
                                Text { Layout.fillWidth: true; text: "Blur"; font.family: Config.theme.font; font.pixelSize: Styling.fontSize(0); color: Colors.overSurfaceVariant }
                                Text { text: Config.theme.shadowBlur.toFixed(1); font.family: Config.theme.font; font.pixelSize: Styling.fontSize(-1); color: Colors.secondary; font.weight: Font.SemiBold }
                            }
                            ValueSlider {
                                id: shadowBlurSlider; trackColor: Colors.secondary; stepSize: 0.01
                                readonly property real configValue: Config.theme.shadowBlur / 4
                                onConfigValueChanged: { if (Math.abs(value - configValue) > 0.001) value = configValue }
                                Component.onCompleted: value = configValue
                                onValueChanged: { let b = value * 4; if (Math.abs(b - Config.theme.shadowBlur) > 0.01) { GlobalStates.markThemeChanged(); Config.theme.shadowBlur = b } }
                            }
                        }

                        Divider {}
                        SectionLabel { text: "OFFSET" }

                        // X Offset
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 4
                            RowLayout {
                                Layout.fillWidth: true
                                Text { Layout.fillWidth: true; text: "Horizontal"; font.family: Config.theme.font; font.pixelSize: Styling.fontSize(0); color: Colors.overSurfaceVariant }
                                Text { text: Config.theme.shadowXOffset; font.family: Config.theme.font; font.pixelSize: Styling.fontSize(-1); color: Colors.tertiary; font.weight: Font.SemiBold }
                            }
                            ValueSlider {
                                id: shadowXSlider; trackColor: Colors.tertiary; stepSize: 0.025
                                readonly property real configValue: (Config.theme.shadowXOffset + 20) / 40
                                onConfigValueChanged: { if (Math.abs(value - configValue) > 0.001) value = configValue }
                                Component.onCompleted: value = configValue
                                onValueChanged: { let v = Math.round((value - 0.5) * 40); if (v !== Config.theme.shadowXOffset) { GlobalStates.markThemeChanged(); Config.theme.shadowXOffset = v } }
                            }
                        }

                        // Y Offset
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 4
                            RowLayout {
                                Layout.fillWidth: true
                                Text { Layout.fillWidth: true; text: "Vertical"; font.family: Config.theme.font; font.pixelSize: Styling.fontSize(0); color: Colors.overSurfaceVariant }
                                Text { text: Config.theme.shadowYOffset; font.family: Config.theme.font; font.pixelSize: Styling.fontSize(-1); color: Colors.tertiary; font.weight: Font.SemiBold }
                            }
                            ValueSlider {
                                id: shadowYSlider; trackColor: Colors.tertiary; stepSize: 0.025
                                readonly property real configValue: (Config.theme.shadowYOffset + 20) / 40
                                onConfigValueChanged: { if (Math.abs(value - configValue) > 0.001) value = configValue }
                                Component.onCompleted: value = configValue
                                onValueChanged: { let v = Math.round((value - 0.5) * 40); if (v !== Config.theme.shadowYOffset) { GlobalStates.markThemeChanged(); Config.theme.shadowYOffset = v } }
                            }
                        }

                        Divider {}
                        SectionLabel { text: "COLOR" }

                        Rectangle {
                            id: shadowColorBtn
                            Layout.fillWidth: true; Layout.preferredHeight: 40
                            radius: Styling.radius(-1)
                            color: shadowColorMA.containsMouse ? Colors.surfaceContainerHigh : Colors.surfaceContainer
                            border.width: 1
                            border.color: Qt.rgba(Colors.outlineVariant.r, Colors.outlineVariant.g, Colors.outlineVariant.b, 0.5)
                            Behavior on color { ColorAnimation { duration: 100 } }

                            RowLayout {
                                anchors { fill: parent; margins: 10 }; spacing: 8
                                Rectangle {
                                    width: 18; height: 18; radius: 4
                                    color: Config.resolveColor(Config.theme.shadowColor)
                                    border.width: 1; border.color: Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.4)
                                }
                                Text {
                                    Layout.fillWidth: true; text: Config.theme.shadowColor
                                    font.family: Config.theme.font; font.pixelSize: Styling.fontSize(0)
                                    color: Colors.overSurfaceVariant; elide: Text.ElideRight
                                }
                                Text {
                                    text: "Change"; font.family: Config.theme.font
                                    font.pixelSize: Styling.fontSize(-1); color: Colors.primary; font.weight: Font.Medium
                                }
                            }
                            MouseArea {
                                id: shadowColorMA; anchors.fill: parent; hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.openColorPicker(Colors.availableColorNames, Config.theme.shadowColor, "Select Shadow Color", (c) => {
                                    GlobalStates.markThemeChanged(); Config.theme.shadowColor = c
                                })
                            }
                        }
                    }

                    // ════════════════════════════════════════════════
                    // COLORS
                    // ════════════════════════════════════════════════
                    ColumnLayout {
                        visible: root.currentSection === "colors"
                        Layout.fillWidth: true
                        spacing: 6

                        SectionLabel { text: "VARIANT" }

                        // Variant chip row
                        Flickable {
                            Layout.fillWidth: true; Layout.preferredHeight: 34
                            contentWidth: chipRow.implicitWidth
                            flickableDirection: Flickable.HorizontalFlick
                            clip: true; boundsBehavior: Flickable.StopAtBounds

                            ScrollBar.horizontal: ScrollBar {
                                height: 3
                                contentItem: Rectangle { color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.45); radius: 2 }
                                background: Rectangle { color: "transparent" }
                            }

                            Row {
                                id: chipRow
                                spacing: 4

                                Repeater {
                                    model: root.allVariants
                                    delegate: Rectangle {
                                        id: chip
                                        required property var modelData
                                        required property int index

                                        readonly property bool isSelected: root.selectedVariant === modelData.id

                                        width: chipLbl.implicitWidth + 20
                                        height: 30
                                        radius: Styling.radius(-2)
                                        color: isSelected
                                            ? Colors.primaryContainer
                                            : chipMA.containsMouse
                                                ? Colors.surfaceContainerHigh
                                                : Colors.surfaceContainer
                                        border.width: 1
                                        border.color: isSelected
                                            ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.55)
                                            : Qt.rgba(Colors.outlineVariant.r, Colors.outlineVariant.g, Colors.outlineVariant.b, 0.4)

                                        Behavior on color        { ColorAnimation { duration: Appearance.animation.elementMoveFast.duration } }
                                        Behavior on border.color { ColorAnimation { duration: Appearance.animation.elementMoveFast.duration } }

                                        Text {
                                            id: chipLbl
                                            anchors.centerIn: parent
                                            text: chip.modelData.label
                                            font.family: Config.theme.font
                                            font.pixelSize: Styling.fontSize(-1)
                                            font.weight: chip.isSelected ? Font.SemiBold : Font.Normal
                                            color: chip.isSelected ? Colors.overPrimaryContainer : Colors.overSurfaceVariant
                                            Behavior on color { ColorAnimation { duration: Appearance.animation.elementMoveFast.duration } }
                                        }
                                        MouseArea { id: chipMA; anchors.fill: parent; hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor; onClicked: root.selectedVariant = chip.modelData.id }
                                    }
                                }
                            }
                        }

                        Divider {}
                        SectionLabel { text: "EDITOR  ·  " + root.getVariantLabel(root.selectedVariant).toUpperCase() }

                        VariantEditor {
                            Layout.fillWidth: true
                            variantId: root.selectedVariant
                            onClose: {}
                            onOpenColorPickerRequested: (colorNames, currentColor, dialogTitle, callback) =>
                                root.openColorPicker(colorNames, currentColor, dialogTitle, callback)
                        }
                    }

                    Item { Layout.fillWidth: true; Layout.preferredHeight: 16 }
                }
            }
        }
    }

    // ── Color picker overlay ──────────────────────────────────────────────
    Item {
        id: colorPickerContainer
        anchors.fill: parent
        clip: true

        opacity: root.colorPickerActive ? 1 : 0
        transform: Translate {
            x: root.colorPickerActive ? 0 : 28
            Behavior on x { NumberAnimation { duration: (Config.animDuration ?? 0) / 2; easing.type: Easing.OutQuart } }
        }
        Behavior on opacity { NumberAnimation { duration: (Config.animDuration ?? 0) / 2; easing.type: Easing.OutQuart } }
        enabled: root.colorPickerActive

        MouseArea {
            anchors.fill: parent; enabled: root.colorPickerActive; hoverEnabled: true
            acceptedButtons: Qt.AllButtons
            onPressed: event => event.accepted = true
            onReleased: event => event.accepted = true
            onWheel: event => event.accepted = true
        }

        ColorPickerView {
            anchors.fill: parent
            anchors.leftMargin: root.sideMargin; anchors.rightMargin: root.sideMargin
            colorNames: root.colorPickerColorNames
            currentColor: root.colorPickerCurrentColor
            dialogTitle: root.colorPickerDialogTitle
            onColorSelected: color => root.handleColorSelected(color)
            onClosed: root.closeColorPicker()
        }
    }
}
