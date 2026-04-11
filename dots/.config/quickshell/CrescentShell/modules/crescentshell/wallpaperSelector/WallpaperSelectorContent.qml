import qs
import qs.services
import qs.modules
import qs.modules.uikit
import qs.modules.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io

// Root is transparent — the hex grid floats directly over the desktop.
// No window box, no sidebar. Matches the skwd-wall hex overlay style.
MouseArea {
    id: root
    property bool useDarkMode: Appearance.m3colors.darkmode

    // Honeycomb geometry — flat-top hexagons
    readonly property real hexSize:     82
    readonly property real hexH:        hexSize * 2
    readonly property real hexW:        hexSize * Math.sqrt(3)
    readonly property real hexHorizGap: 4
    readonly property real hexVertGap:  4
    readonly property int  hexCols:     6

    function updateThumbnails() {
        const sz = Images.thumbnailSizeNameForDimensions(Math.round(hexW), Math.round(hexH))
        Wallpapers.generateThumbnail(sz)
    }

    Connections {
        target: Wallpapers
        function onDirectoryChanged() { root.updateThumbnails() }
    }

    function selectWallpaperPath(filePath) {
        if (filePath && filePath.length > 0) {
            Wallpapers.select(filePath, root.useDarkMode)
            filterField.text = ""
        }
    }

    function handleFilePasting(event) {
        const entry = Cliphist.entries[0]
        if (/^\d+\tfile:\/\/\S+/.test(entry)) {
            Wallpapers.setDirectory(FileUtils.trimFileProtocol(decodeURIComponent(StringUtils.cleanCliphistEntry(entry))))
            event.accepted = true
        } else {
            event.accepted = false
        }
    }

    acceptedButtons: Qt.BackButton | Qt.ForwardButton
    onPressed: event => {
        if (event.button === Qt.BackButton)         Wallpapers.navigateBack()
        else if (event.button === Qt.ForwardButton) Wallpapers.navigateForward()
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            GlobalStates.wallpaperSelectorOpen = false; event.accepted = true
        } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_V) {
            root.handleFilePasting(event)
        } else if (event.modifiers & Qt.AltModifier && event.key === Qt.Key_Up) {
            Wallpapers.navigateUp(); event.accepted = true
        } else if (event.modifiers & Qt.AltModifier && event.key === Qt.Key_Left) {
            Wallpapers.navigateBack(); event.accepted = true
        } else if (event.modifiers & Qt.AltModifier && event.key === Qt.Key_Right) {
            Wallpapers.navigateForward(); event.accepted = true
        } else if (event.key === Qt.Key_Backspace) {
            if (filterField.text.length > 0)
                filterField.text = filterField.text.substring(0, filterField.text.length - 1)
            filterField.forceActiveFocus(); event.accepted = true
        } else if (event.key === Qt.Key_Slash) {
            filterField.forceActiveFocus(); event.accepted = true
        } else {
            if (event.text.length > 0) {
                filterField.text += event.text
                filterField.cursorPosition = filterField.text.length
                filterField.forceActiveFocus()
            }
            event.accepted = true
        }
    }

    // ── THIN TOOLBAR (floats above hex grid) ─────────────────────────────────
    Rectangle {
        id: toolbar
        anchors {
            top: parent.top
            topMargin: 10
            horizontalCenter: parent.horizontalCenter
        }
        width: hexGrid.width
        height: 36
        radius: Appearance.rounding.normal
        color: Qt.rgba(
            Colors.surfaceContainerLowest.r,
            Colors.surfaceContainerLowest.g,
            Colors.surfaceContainerLowest.b, 0.88)
        border.width: 1
        border.color: Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.22)

        // Prevent clicks falling through to desktop
        MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; propagateComposedEvents: false }

        RowLayout {
            anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
            spacing: 6

            // Address bar
            AddressBar {
                id: addressBar
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.topMargin: 4
                Layout.bottomMargin: 4
                directory: Wallpapers.effectiveDirectory
                onNavigateToDirectory: path => Wallpapers.setDirectory(path.length == 0 ? "/" : path)
                radius: Appearance.rounding.small
            }

            // Search field
            Rectangle {
                Layout.preferredHeight: 26
                width: filterField.activeFocus || filterField.text.length > 0 ? 150 : 100
                radius: Appearance.rounding.small
                color: filterField.activeFocus ? Colors.surfaceContainerHighest : Colors.surfaceContainer
                border.width: filterField.activeFocus ? 1 : 0
                border.color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.45)
                Behavior on width { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 100 } }

                RowLayout {
                    anchors { fill: parent; leftMargin: 6; rightMargin: 4 }
                    spacing: 3
                    MaterialSymbol {
                        text: "search"; iconSize: Appearance.font.pixelSize.small
                        color: filterField.activeFocus ? Colors.primary : Colors.overSurfaceVariant
                        Behavior on color { ColorAnimation { duration: 100 } }
                    }
                    ToolbarTextField {
                        id: filterField
                        Layout.fillWidth: true
                        placeholderText: filterField.activeFocus ? Translation.tr("Search") : Translation.tr("Hit \"/\"")
                        clip: true
                        font.pixelSize: Appearance.font.pixelSize.small
                        onTextChanged: Wallpapers.searchQuery = text
                    }
                }
            }

            // Shuffle button
            Rectangle {
                width: 28; height: 28; radius: Appearance.rounding.small
                color: shuffleMA.containsMouse ? Colors.surfaceContainerHigh : "transparent"
                Behavior on color { ColorAnimation { duration: 100 } }
                MaterialSymbol {
                    anchors.centerIn: parent; text: "ifl"
                    iconSize: Appearance.font.pixelSize.normal
                    color: shuffleMA.containsMouse ? Colors.tertiary : Colors.overSurfaceVariant
                    Behavior on color { ColorAnimation { duration: 100 } }
                }
                MouseArea { id: shuffleMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: Wallpapers.randomFromCurrentFolder() }
                StyledToolTip { text: Translation.tr("Pick random") }
            }

            // Dark/light toggle
            Rectangle {
                width: 28; height: 28; radius: Appearance.rounding.small
                color: root.useDarkMode
                    ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.18)
                    : modeMA.containsMouse ? Colors.surfaceContainerHigh : "transparent"
                Behavior on color { ColorAnimation { duration: 120 } }
                MaterialSymbol {
                    anchors.centerIn: parent
                    text: root.useDarkMode ? "dark_mode" : "light_mode"
                    iconSize: Appearance.font.pixelSize.normal
                    color: root.useDarkMode ? Colors.primary : Colors.overSurfaceVariant
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
                MouseArea { id: modeMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: root.useDarkMode = !root.useDarkMode }
                StyledToolTip { text: Translation.tr("Toggle dark/light") }
            }

            // Close button
            Rectangle {
                width: 28; height: 28; radius: Appearance.rounding.small
                color: closeMA.containsMouse ? Qt.rgba(Colors.error.r, Colors.error.g, Colors.error.b, 0.18) : "transparent"
                Behavior on color { ColorAnimation { duration: 100 } }
                MaterialSymbol {
                    anchors.centerIn: parent; text: "close"
                    iconSize: Appearance.font.pixelSize.normal
                    color: closeMA.containsMouse ? Colors.error : Colors.overSurfaceVariant
                    Behavior on color { ColorAnimation { duration: 100 } }
                }
                MouseArea { id: closeMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: GlobalStates.wallpaperSelectorOpen = false }
                StyledToolTip { text: Translation.tr("Cancel wallpaper selection") }
            }
        }
    }

    // Thumbnail generation progress bar (under toolbar)
    Rectangle {
        id: progressBar
        visible: Wallpapers.thumbnailGenerationRunning
        anchors {
            top: toolbar.bottom; topMargin: 3
            horizontalCenter: parent.horizontalCenter
        }
        width: toolbar.width; height: 2; radius: 1
        color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.18)

        Rectangle {
            width: Wallpapers.thumbnailGenerationProgress > 0
                ? parent.width * Wallpapers.thumbnailGenerationProgress
                : parent.width
            height: parent.height; radius: 1
            color: Colors.primary
            Behavior on width { NumberAnimation { duration: 200 } }
        }
    }

    // ── HEX GRID (centered on screen, below toolbar) ──────────────────────────
    Item {
        id: hexGrid
        anchors {
            top: toolbar.bottom; topMargin: 10
            horizontalCenter: parent.horizontalCenter
        }

        readonly property real cellW: root.hexW + root.hexHorizGap
        readonly property real cellH: root.hexH * 0.75 + root.hexVertGap
        readonly property real staggerOffset: root.hexH * 0.375
        readonly property int  totalItems: Wallpapers.folderModel.count
        readonly property int  rows: Math.ceil(totalItems / root.hexCols)

        width:  root.hexCols * cellW
        height: rows * cellH + staggerOffset + 20

        // Reusable hex mask
        component HexMask: Canvas {
            property real r: 40
            onPaint: {
                const ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                ctx.fillStyle = "white"
                ctx.beginPath()
                const cx = width / 2, cy = height / 2
                for (let i = 0; i < 6; i++) {
                    const angle = Math.PI / 180 * (60 * i - 30)
                    const px = cx + r * Math.cos(angle)
                    const py = cy + r * Math.sin(angle)
                    i === 0 ? ctx.moveTo(px, py) : ctx.lineTo(px, py)
                }
                ctx.closePath()
                ctx.fill()
            }
        }

        Component.onCompleted: root.updateThumbnails()

        Repeater {
            model: Wallpapers.folderModel

            delegate: Item {
                id: hexItem
                required property var modelData
                required property int index

                readonly property int  col:         index % root.hexCols
                readonly property int  row:         Math.floor(index / root.hexCols)
                readonly property bool isEvenCol:   col % 2 === 0
                readonly property bool isSelected:  modelData.filePath === Config.options.background.wallpaperPath
                readonly property bool isHovered:   hexMA.containsMouse

                width:  root.hexW
                height: root.hexH

                x: col * hexGrid.cellW
                y: row * hexGrid.cellH + (isEvenCol ? 0 : hexGrid.staggerOffset) + 10

                // Scale animation on hover/select
                transform: Scale {
                    origin.x: root.hexW / 2
                    origin.y: root.hexH / 2
                    xScale: hexItem.isHovered ? 1.09 : (hexItem.isSelected ? 1.05 : 1.0)
                    yScale: xScale
                    Behavior on xScale {
                        NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 1.3 }
                    }
                }

                // Hover / selected ring
                Canvas {
                    anchors.fill: parent
                    visible: hexItem.isHovered || hexItem.isSelected
                    onPaint: {
                        const ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)
                        const cx = width / 2, cy = height / 2
                        const r = root.hexSize - 1
                        ctx.strokeStyle = hexItem.isSelected
                            ? Qt.rgba(Colors.secondary.r, Colors.secondary.g, Colors.secondary.b, 1)
                            : Qt.rgba(Colors.primary.r,   Colors.primary.g,   Colors.primary.b,   1)
                        ctx.lineWidth = hexItem.isSelected ? 3 : 2.5
                        ctx.beginPath()
                        for (let i = 0; i < 6; i++) {
                            const angle = Math.PI / 180 * (60 * i - 30)
                            const px = cx + r * Math.cos(angle)
                            const py = cy + r * Math.sin(angle)
                            i === 0 ? ctx.moveTo(px, py) : ctx.lineTo(px, py)
                        }
                        ctx.closePath()
                        ctx.stroke()
                    }
                    onVisibleChanged: requestPaint()
                    Component.onCompleted: requestPaint()
                }

                // Hex image (clipped)
                Item {
                    id: hexImageHolder
                    anchors { fill: parent; margins: 3 }

                    Rectangle {
                        anchors.fill: parent
                        color: hexItem.isSelected ? Colors.secondaryContainer
                             : hexItem.isHovered  ? Colors.primaryContainer
                             : Colors.surfaceContainer
                        Behavior on color { ColorAnimation { duration: Appearance.animation.elementMoveFast.duration } }
                    }

                    Loader {
                        anchors.fill: parent
                        active: Images.isValidImageByName(modelData.fileName)
                        sourceComponent: ThumbnailImage {
                            generateThumbnail: false
                            sourcePath: hexItem.modelData.filePath
                            cache: false
                            fillMode: Image.PreserveAspectCrop
                            clip: true
                            sourceSize.width:  Math.round(root.hexW)
                            sourceSize.height: Math.round(root.hexH)

                            Connections {
                                target: Wallpapers
                                function onThumbnailGenerated(directory) {
                                    if (parent.status !== Image.Error) return
                                    parent.source = ""; parent.source = parent.thumbnailPath
                                }
                                function onThumbnailGeneratedFile(filePath) {
                                    if (parent.status !== Image.Error) return
                                    if (Qt.resolvedUrl(parent.sourcePath) !== Qt.resolvedUrl(filePath)) return
                                    parent.source = ""; parent.source = parent.thumbnailPath
                                }
                            }
                        }
                    }

                    // Hover tint
                    Rectangle {
                        anchors.fill: parent
                        color: hexItem.isHovered
                            ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.22)
                            : hexItem.isSelected
                                ? Qt.rgba(Colors.secondary.r, Colors.secondary.g, Colors.secondary.b, 0.18)
                                : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    // Hex clip
                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: HexMask {
                            width:  hexImageHolder.width
                            height: hexImageHolder.height
                            r: Math.min(width, height) / 2 - 1
                            Component.onCompleted: requestPaint()
                        }
                    }
                }

                // Filename label
                Text {
                    anchors {
                        bottom: parent.bottom
                        horizontalCenter: parent.horizontalCenter
                        bottomMargin: 6
                    }
                    text: modelData.fileName
                    font.family: Appearance.font.family
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: hexItem.isHovered || hexItem.isSelected
                        ? Colors.overBackground : Colors.overSurfaceVariant
                    elide: Text.ElideRight
                    width: parent.width * 0.85
                    horizontalAlignment: Text.AlignHCenter
                    Behavior on color { ColorAnimation { duration: 120 } }
                }

                MouseArea {
                    id: hexMA
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.selectWallpaperPath(modelData.filePath)
                }
            }
        }
    }

    // ── TAG / FILTER CHIP BAR (below hex grid) ────────────────────────────────
    Rectangle {
        id: tagbar
        anchors {
            top: hexGrid.bottom; topMargin: 10
            horizontalCenter: parent.horizontalCenter
        }
        width: hexGrid.width; height: 30
        radius: Appearance.rounding.normal
        color: Qt.rgba(
            Colors.surfaceContainerLowest.r,
            Colors.surfaceContainerLowest.g,
            Colors.surfaceContainerLowest.b, 0.82)
        border.width: 1
        border.color: Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.18)

        MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; propagateComposedEvents: false }

        Row {
            anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
            spacing: 6

            Repeater {
                model: Wallpapers.tags ?? []
                delegate: Rectangle {
                    required property string modelData
                    required property int    index
                    height: 20; width: tagLabel.implicitWidth + 14; radius: 5
                    anchors.verticalCenter: parent.verticalCenter
                    color: Wallpapers.activeTag === modelData
                        ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.18)
                        : Qt.rgba(Colors.surfaceContainer.r, Colors.surfaceContainer.g, Colors.surfaceContainer.b, 0.9)
                    border.width: 1
                    border.color: Wallpapers.activeTag === modelData
                        ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.5)
                        : Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.25)
                    Text {
                        id: tagLabel
                        anchors.centerIn: parent
                        text: modelData
                        font.family: Appearance.font.family
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Wallpapers.activeTag === modelData ? Colors.primary : Colors.overSurfaceVariant
                        Behavior on color { ColorAnimation { duration: 100 } }
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: Wallpapers.activeTag = (Wallpapers.activeTag === modelData ? "" : modelData)
                    }
                }
            }
        }
    }

    Connections {
        target: GlobalStates
        function onWallpaperSelectorOpenChanged() {
            if (GlobalStates.wallpaperSelectorOpen)
                filterField.forceActiveFocus()
        }
    }

    Connections {
        target: Wallpapers
        function onChanged() { GlobalStates.wallpaperSelectorOpen = false }
    }
}
