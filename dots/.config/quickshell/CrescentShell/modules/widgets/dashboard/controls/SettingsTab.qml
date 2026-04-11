pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.theme
import QtQuick.Effects
import qs.modules.components
import qs.modules.services
import qs.config
import "SettingsCrawler.js" as SettingsCrawler

Rectangle {
    id: root
    color: "transparent"
    implicitWidth: 400
    implicitHeight: 300

    property int currentSection: 0
    property int selectedIndex: 0
    property string searchQuery: ""

    onFilteredSectionsChanged: selectedIndex = 0

    Timer {
        id: focusRestoreTimer
        interval: 50
        onTriggered: searchInput.focusInput()
    }

    onSelectedIndexChanged: {
        if (filteredSections && selectedIndex >= 0 && selectedIndex < filteredSections.length) {
            const item = filteredSections[selectedIndex]
            root.currentSection = item.section
            root.dispatchSubSection(item.section, item.subSection)
            root.scrollSidebarToSelection()
            focusRestoreTimer.restart()
        }
    }

    function focusSearchInput() { searchInput.focusInput() }

    SettingsIndex { id: searchIndex }

    // ── Dynamic settings indexer ──────────────────────────────────────
    Item {
        id: settingsIndexer
        visible: false
        property int currentPanelIndex: 0
        property var aggregatedItems: []
        property bool isIndexing: false

        Loader {
            id: indexerLoader
            active: settingsIndexer.isIndexing
            asynchronous: true
            source: settingsIndexer.isIndexing && settingsIndexer.currentPanelIndex < contentArea.panelComponents.length
                ? contentArea.panelComponents[settingsIndexer.currentPanelIndex].component : ""
            onStatusChanged: {
                if (status === Loader.Ready && item) {
                    const sectionId = contentArea.panelComponents[settingsIndexer.currentPanelIndex].section
                    settingsIndexer.aggregatedItems = settingsIndexer.aggregatedItems.concat(SettingsCrawler.crawl(item, sectionId))
                    settingsIndexer.currentPanelIndex++
                } else if (status === Loader.Error) {
                    settingsIndexer.currentPanelIndex++
                }
            }
        }

        onCurrentPanelIndexChanged: {
            if (currentPanelIndex >= contentArea.panelComponents.length && isIndexing) {
                isIndexing = false
                searchIndex.addDynamicItems(aggregatedItems)
            }
        }

        Component.onCompleted: indexingTimer.start()
        Timer { id: indexingTimer; interval: 500; onTriggered: settingsIndexer.isIndexing = true }
    }

    property string pendingSubSection: ""

    function dispatchSubSection(sectionId, subSectionId) {
        if (!subSectionId || subSectionId === "") return
        if ([4, 6, 7, 8].includes(sectionId)) {
            if (panelLoader.item && panelLoader.status === Loader.Ready) {
                panelLoader.item.currentSection = subSectionId
            } else {
                pendingSubSection = subSectionId
            }
        }
    }

    function scrollSidebarToSelection() {
        if (sidebarFlickable.height <= 0) return
        const itemY = root.selectedIndex * 46
        if (itemY < sidebarFlickable.contentY) {
            sidebarFlickable.contentY = itemY
        } else if (itemY + 46 > sidebarFlickable.contentY + sidebarFlickable.height) {
            sidebarFlickable.contentY = itemY + 46 - sidebarFlickable.height
        }
    }

    function fuzzyMatch(query, target) {
        if (query.length === 0) return true
        const lq = query.toLowerCase(), lt = target.toLowerCase()
        let qi = 0
        for (let i = 0; i < lt.length && qi < lq.length; i++)
            if (lt[i] === lq[qi]) qi++
        return qi === lq.length
    }

    function fuzzyScore(query, target) {
        if (query.length === 0) return 0
        const lq = query.toLowerCase(), lt = target.toLowerCase()
        if (lt.includes(lq)) return 1000 + (100 - target.length)
        let qi = 0, score = 0, cons = 0, maxCons = 0
        for (let i = 0; i < lt.length && qi < lq.length; i++) {
            if (lt[i] === lq[qi]) {
                qi++; cons++; maxCons = Math.max(maxCons, cons)
                if (i === 0 || " -_".includes(lt[i - 1])) score += 10
            } else { cons = 0 }
        }
        return qi === lq.length ? score + maxCons * 5 : -1
    }

    readonly property var sectionModel: [
        { icon: Icons.wifiHigh,    label: "Network",     section: 0, isIcon: true },
        { icon: Icons.bluetooth,   label: "Bluetooth",   section: 1, isIcon: true },
        { icon: Icons.faders,      label: "Mixer",       section: 2, isIcon: true },
        { icon: Icons.waveform,    label: "Effects",     section: 3, isIcon: true },
        { icon: Icons.paintBrush,  label: "Theme",       section: 4, isIcon: true },
        { icon: Icons.keyboard,    label: "Binds",       section: 5, isIcon: true },
        { icon: Icons.circuitry,   label: "System",      section: 6, isIcon: true },
        { icon: Icons.compositor,  label: "Compositor",  section: 7, isIcon: true },
        { icon: Qt.resolvedUrl("../../../../assets/ambxst/ambxst-icon.svg"), label: "Ambxst", section: 8, isIcon: false },
    ]

    readonly property var filteredSections: {
        if (searchQuery.length === 0) return sectionModel
        const q = searchQuery.toLowerCase()
        return searchIndex.items.filter(item =>
            fuzzyMatch(q, item.label) || (item.keywords && item.keywords.includes(q))
        ).map(item => {
            const meta = sectionModel.find(s => s.section === item.section) || {}
            return {
                label: item.label, section: item.section,
                subSection: item.subSection || "", subLabel: item.subLabel || "",
                icon: meta.icon || item.icon,
                isIcon: meta.isIcon !== undefined ? meta.isIcon : (item.isIcon !== undefined ? item.isIcon : true),
                score: fuzzyScore(q, item.label)
            }
        }).sort((a, b) => b.score - a.score)
    }

    // ── Layout ─────────────────────────────────────────────────────────
    RowLayout {
        anchors.fill: parent
        spacing: 8

        // ── LEFT SIDEBAR ───────────────────────────────────────────────
        ColumnLayout {
            Layout.preferredWidth: 192
            Layout.maximumWidth: 192
            Layout.fillHeight: true
            spacing: 4

            // Search bar
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                radius: Styling.radius(-2)
                color: searchInput.activeFocus
                    ? Colors.surfaceContainerHighest
                    : Colors.surfaceContainerLow
                border.width: searchInput.activeFocus ? 1 : 0
                border.color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.45)
                Behavior on color  { ColorAnimation { duration: 120 } }

                RowLayout {
                    anchors { fill: parent; leftMargin: 8; rightMargin: 6 }
                    spacing: 5

                    Text {
                        text: "search"
                        font.family: Icons.font
                        font.pixelSize: 15
                        color: searchInput.activeFocus ? Colors.primary : Colors.outlineVariant
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    SearchInput {
                        id: searchInput
                        Layout.fillWidth: true
                        placeholderText: "Search…"
                        clearOnEscape: true

                        onSearchTextChanged: text => root.searchQuery = text
                        onEscapePressed: { searchInput.focus = false; root.forceActiveFocus() }
                        onAccepted: {
                            if (root.filteredSections.length > 0) {
                                const item = root.filteredSections[root.selectedIndex]
                                root.currentSection = item.section
                                root.dispatchSubSection(item.section, item.subSection)
                            }
                        }
                        onDownPressed: root.selectedIndex = (root.selectedIndex < root.filteredSections.length - 1) ? root.selectedIndex + 1 : 0
                        onUpPressed: root.selectedIndex = (root.selectedIndex > 0) ? root.selectedIndex - 1 : root.filteredSections.length - 1
                    }
                }
            }

            // Nav list
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Styling.radius(0)
                color: Colors.surfaceContainerLow
                border.width: 1
                border.color: Qt.rgba(Colors.outlineVariant.r, Colors.outlineVariant.g, Colors.outlineVariant.b, 0.35)
                clip: true

                // Sliding selection pill
                Rectangle {
                    id: selPill
                    x: 4; width: parent.width - 8; height: 38
                    radius: Styling.radius(-2)
                    color: Colors.primaryContainer
                    opacity: root.selectedIndex >= 0 && root.selectedIndex < root.filteredSections.length ? 1 : 0
                    y: {
                        const idx = root.selectedIndex
                        return idx >= 0 ? idx * 46 + 4 - sidebarFlickable.contentY : 4
                    }
                    Behavior on y { NumberAnimation { duration: (Config.animDuration ?? 0) / 2; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: 100 } }
                }

                Flickable {
                    id: sidebarFlickable
                    anchors { fill: parent; margins: 4 }
                    contentWidth: width
                    contentHeight: navCol.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    ScrollBar.vertical: ScrollBar {
                        width: 3
                        contentItem: Rectangle { color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.45); radius: 2 }
                        background: Rectangle { color: "transparent" }
                    }

                    Column {
                        id: navCol
                        width: parent.width
                        spacing: 0

                        Repeater {
                            model: root.filteredSections

                            delegate: Item {
                                id: navItem
                                required property var modelData
                                required property int index
                                width: navCol.width
                                height: 46

                                readonly property bool isActive: index === root.selectedIndex

                                RowLayout {
                                    anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                                    spacing: 8

                                    // Font icon
                                    Text {
                                        visible: navItem.modelData.isIcon && (root.searchQuery.length === 0 || !navItem.modelData.subSection)
                                        text: navItem.modelData.isIcon ? navItem.modelData.icon : ""
                                        font.family: Icons.font
                                        font.pixelSize: 17
                                        color: navItem.isActive ? Colors.overPrimaryContainer : Colors.overSurfaceVariant
                                        Behavior on color { ColorAnimation { duration: (Config.animDuration ?? 0) } }
                                    }

                                    // SVG icon
                                    Item {
                                        width: 20; height: 20
                                        visible: !navItem.modelData.isIcon && (root.searchQuery.length === 0 || !navItem.modelData.subSection)
                                        Image {
                                            anchors.fill: parent
                                            source: !navItem.modelData.isIcon ? navItem.modelData.icon : ""
                                            sourceSize: Qt.size(40, 40)
                                            fillMode: Image.PreserveAspectFit
                                            smooth: true
                                            asynchronous: true
                                            layer.enabled: true
                                            layer.effect: MultiEffect {
                                                brightness: 1.0
                                                colorization: 1.0
                                                colorizationColor: navItem.isActive ? Colors.overPrimaryContainer : Colors.overSurfaceVariant
                                            }
                                        }
                                    }

                                    // Labels
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 1

                                        Text {
                                            Layout.fillWidth: true
                                            text: navItem.modelData.label
                                            font.family: Config.theme.font
                                            font.pixelSize: Styling.fontSize(0)
                                            font.weight: navItem.isActive ? Font.SemiBold : Font.Normal
                                            color: navItem.isActive ? Colors.overPrimaryContainer : Colors.overSurface
                                            elide: Text.ElideRight
                                            Behavior on color { ColorAnimation { duration: (Config.animDuration ?? 0) } }
                                        }

                                        Text {
                                            visible: !!navItem.modelData.subLabel
                                            text: navItem.modelData.subLabel || ""
                                            font.family: Config.theme.font
                                            font.pixelSize: Styling.fontSize(-2)
                                            color: Colors.outlineVariant
                                            elide: Text.ElideRight
                                        }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.selectedIndex = index
                                        root.dispatchSubSection(navItem.modelData.section, navItem.modelData.subSection)
                                    }
                                }
                            }
                        }
                    }

                    WheelHandler {
                        enabled: sidebarFlickable.contentHeight <= sidebarFlickable.height
                        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                        onWheel: event => {
                            if (event.angleDelta.y > 0 && root.selectedIndex > 0) root.selectedIndex--
                            else if (event.angleDelta.y < 0 && root.selectedIndex < root.filteredSections.length - 1) root.selectedIndex++
                        }
                    }
                }
            }
        }

        // ── CONTENT PANEL ──────────────────────────────────────────────
        Rectangle {
            id: contentArea
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Styling.radius(0)
            color: Colors.surfaceContainerLowest
            border.width: 1
            border.color: Qt.rgba(Colors.outlineVariant.r, Colors.outlineVariant.g, Colors.outlineVariant.b, 0.3)
            clip: true

            property int previousSection: 0
            readonly property int maxContentWidth: 480

            Connections {
                target: root
                function onCurrentSectionChanged() { contentArea.previousSection = root.currentSection }
            }

            readonly property var panelComponents: [
                { component: "WifiPanel.qml",         section: 0 },
                { component: "BluetoothPanel.qml",    section: 1 },
                { component: "AudioMixerPanel.qml",   section: 2 },
                { component: "EasyEffectsPanel.qml",  section: 3 },
                { component: "ThemePanel.qml",        section: 4 },
                { component: "BindsPanel.qml",        section: 5 },
                { component: "SystemPanel.qml",       section: 6 },
                { component: "CompositorPanel.qml",   section: 7 },
                { component: "ShellPanel.qml",        section: 8 },
            ]

            Loader {
                id: panelLoader
                anchors.fill: parent
                asynchronous: true
                source: contentArea.panelComponents[root.currentSection]?.component ?? ""

                opacity: status === Loader.Ready ? 1 : 0
                Behavior on opacity {
                    enabled: (Config.animDuration ?? 0) > 0
                    NumberAnimation { duration: Config.animDuration ?? 0; easing.type: Easing.OutCubic }
                }

                onLoaded: {
                    if (item) {
                        item.maxContentWidth = contentArea.maxContentWidth
                        if (root.pendingSubSection !== "" && item.currentSection !== undefined) {
                            item.currentSection = root.pendingSubSection
                            root.pendingSubSection = ""
                        }
                    }
                }
            }

            // Loading indicator
            Rectangle {
                anchors.centerIn: parent
                visible: panelLoader.status === Loader.Loading
                width: 32; height: 32; radius: 8
                color: Colors.surfaceContainer

                Text {
                    anchors.centerIn: parent
                    text: "sync"
                    font.family: Icons.font
                    font.pixelSize: 18
                    color: Colors.primary

                    RotationAnimation on rotation {
                        running: parent.visible
                        from: 0; to: 360
                        duration: 900
                        loops: Animation.Infinite
                    }
                }
            }
        }
    }
}
