pragma ComponentBehavior: Bound

import qs
import qs.services
import qs.core
import qs.core.models
import qs.core.widgets
import qs.core.functions
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import Qt5Compat.GraphicalEffects

Item {
    id: root
    property bool vertical: false
    property bool borderless: Config.options.bar.borderless
    required property var monitor
    readonly property HyprlandMonitor hyprMonitor: Hyprland.monitorFor(monitor)
    readonly property Toplevel activeWindow: ToplevelManager.activeToplevel
    readonly property int effectiveActiveWorkspaceId: hyprMonitor?.activeWorkspace?.id ?? 1

    readonly property int workspacesShown: Config.options.bar.workspaces.shown
    readonly property int workspaceGroup: Math.floor((effectiveActiveWorkspaceId - 1) / root.workspacesShown)
    property list<bool> workspaceOccupied: []
    property int btnSize: 26          // size of each workspace button
    property int pillPad: 3           // padding inside the black pill
    property real activeWorkspaceMargin: 2
    property real workspaceIconSize: btnSize * 0.69
    property real workspaceIconSizeShrinked: btnSize * 0.55
    property real workspaceIconOpacityShrinked: 1
    property real workspaceIconMarginShrinked: -4
    property int workspaceIndexInGroup: (effectiveActiveWorkspaceId - 1) % root.workspacesShown

    property bool showNumbers: false
    Timer {
        id: showNumbersTimer
        interval: Config?.options.bar.autoHide.showWhenPressingSuper.delay ?? 100
        repeat: false
        onTriggered: root.showNumbers = true
    }
    Connections {
        target: GlobalStates
        function onSuperDownChanged() {
            if (!Config?.options.bar.autoHide.showWhenPressingSuper.enable) return
            if (GlobalStates.superDown) showNumbersTimer.restart()
            else { showNumbersTimer.stop(); root.showNumbers = false }
        }
        function onSuperReleaseMightTriggerChanged() { showNumbersTimer.stop() }
    }

    function updateWorkspaceOccupied() {
        workspaceOccupied = Array.from({ length: root.workspacesShown }, (_, i) => {
            return Hyprland.workspaces.values.some(ws => ws.id === workspaceGroup * root.workspacesShown + i + 1)
        })
    }
    Component.onCompleted: updateWorkspaceOccupied()
    Connections { target: Hyprland.workspaces;  function onValuesChanged()        { updateWorkspaceOccupied() } }
    Connections { target: Hyprland;             function onFocusedWorkspaceChanged() { updateWorkspaceOccupied() } }
    onWorkspaceGroupChanged: updateWorkspaceOccupied()

    // Overall size: pill wraps buttons tightly, height matches launcher (32px)
    implicitWidth:  root.btnSize * root.workspacesShown + root.pillPad * 2
    implicitHeight: 32

    // ── Black pill background ─────────────────────────────────
    Rectangle {
        anchors.fill: parent
        radius: 18
        color: "#000000"
    }

    // ── Input handlers ────────────────────────────────────────
    WheelHandler {
        onWheel: (event) => {
            if (event.angleDelta.y < 0) Hyprland.dispatch(`workspace r+1`)
            else Hyprland.dispatch(`workspace r-1`)
        }
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    }
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.BackButton
        onPressed: (event) => {
            if (event.button === Qt.BackButton)
                Hyprland.dispatch(`togglespecialworkspace`)
        }
    }

    // ── Content centered vertically in the pill ───────────────
    Item {
        id: content
        anchors.centerIn: parent
        width:  root.btnSize * root.workspacesShown
        height: root.btnSize

        // Layer 1: occupied highlight backgrounds
        Grid {
            z: 1
            anchors.fill: parent
            rowSpacing: 0; columnSpacing: 0
            columns: root.vertical ? 1 : root.workspacesShown
            rows:    root.vertical ? root.workspacesShown : 1

            Repeater {
                model: root.workspacesShown
                Rectangle {
                    required property int index
                    z: 1
                    width:  root.btnSize
                    height: root.btnSize
                    radius: width / 2
                    property bool prevOccupied: root.workspaceOccupied[index - 1] ?? false
                    property bool nextOccupied: root.workspaceOccupied[index + 1] ?? false
                    property real rPrev: prevOccupied ? 0 : width / 2
                    property real rNext: nextOccupied ? 0 : width / 2
                    topLeftRadius:     root.vertical ? rPrev : rPrev
                    bottomLeftRadius:  root.vertical ? rNext : rPrev
                    topRightRadius:    root.vertical ? rPrev : rNext
                    bottomRightRadius: root.vertical ? rNext : rNext
                    color:   Appearance.m3colors.m3secondaryContainer
                    opacity: root.workspaceOccupied[index] ? 1 : 0
                    Behavior on opacity { animation: Appearance.animation.elementMove.numberAnimation.createObject(this) }
                    Behavior on rPrev   { animation: Appearance.animation.elementMove.numberAnimation.createObject(this) }
                    Behavior on rNext   { animation: Appearance.animation.elementMove.numberAnimation.createObject(this) }
                }
            }
        }

        // Layer 2: active workspace indicator
        Rectangle {
            z: 2
            radius: Appearance.rounding.full
            color:  Appearance.colors.colPrimary
            anchors.verticalCenter:   root.vertical ? undefined : parent.verticalCenter
            anchors.horizontalCenter: root.vertical ? parent.horizontalCenter : undefined

            AnimatedTabIndexPair { id: idxPair; index: root.workspaceIndexInGroup }
            property real indicatorPos:       Math.min(idxPair.idx1, idxPair.idx2) * root.btnSize + root.activeWorkspaceMargin
            property real indicatorLen:       Math.abs(idxPair.idx1 - idxPair.idx2) * root.btnSize + root.btnSize - root.activeWorkspaceMargin * 2
            property real indicatorThickness: root.btnSize - root.activeWorkspaceMargin * 2

            x:             root.vertical ? null : indicatorPos
            y:             root.vertical ? indicatorPos : null
            implicitWidth:  root.vertical ? indicatorThickness : indicatorLen
            implicitHeight: root.vertical ? indicatorLen : indicatorThickness
        }

        // Layer 3: dots / numbers / icons
        Grid {
            z: 3
            anchors.fill: parent
            rowSpacing: 0; columnSpacing: 0
            columns: root.vertical ? 1 : root.workspacesShown
            rows:    root.vertical ? root.workspacesShown : 1

            Repeater {
                model: root.workspacesShown
                Item {
                    required property int index
                    width:  root.btnSize
                    height: root.btnSize

                    property int wsValue: root.workspaceGroup * root.workspacesShown + index + 1
                    property bool isActive: root.effectiveActiveWorkspaceId === wsValue
                    property var biggestWindow: HyprlandData.biggestWindowForWorkspace(wsValue)
                    property var iconSource: Quickshell.iconPath(AppSearch.guessIcon(biggestWindow?.class), "image-missing")

                    // Number text
                    Text {
                        anchors.centerIn: parent; z: 3
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment:   Text.AlignVCenter
                        font.pixelSize: Appearance.font.pixelSize.small - ((text.length - 1) * (text !== "10") * 2)
                        text: Config.options?.bar.workspaces.numberMap?.[parent.wsValue - 1] || parent.wsValue
                        elide: Text.ElideRight
                        opacity: root.showNumbers || (Config.options?.bar.workspaces.alwaysShowNumbers && (!Config.options?.bar.workspaces.showAppIcons || !parent.biggestWindow)) ? 1 : 0
                        color: parent.isActive ? Appearance.m3colors.m3onPrimary
                            : (root.workspaceOccupied[parent.index] ? Appearance.m3colors.m3onSecondaryContainer
                            : Appearance.colors.colOnLayer1Inactive)
                        Behavior on opacity { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this) }
                    }

                    // Dot
                    Rectangle {
                        id: wsDot
                        anchors.centerIn: parent
                        width: root.btnSize * 0.18; height: width; radius: width / 2
                        opacity: (Config.options?.bar.workspaces.alwaysShowNumbers || root.showNumbers
                            || (Config.options?.bar.workspaces.showAppIcons && parent.biggestWindow)) ? 0 : 1
                        visible: opacity > 0
                        color: parent.isActive ? Appearance.m3colors.m3onPrimary
                            : (root.workspaceOccupied[parent.index] ? Appearance.m3colors.m3onSecondaryContainer
                            : Appearance.colors.colOnLayer1Inactive)
                        Behavior on opacity { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this) }
                    }

                    // App icon
                    Item {
                        anchors.centerIn: parent
                        width: root.btnSize; height: root.btnSize
                        opacity: !Config.options?.bar.workspaces.showAppIcons ? 0
                            : (parent.biggestWindow && !root.showNumbers) ? 1
                            : parent.biggestWindow ? root.workspaceIconOpacityShrinked : 0
                        visible: opacity > 0

                        IconImage {
                            id: mainAppIcon
                            source: parent.parent.iconSource
                            implicitSize: (!root.showNumbers && Config.options?.bar.workspaces.showAppIcons)
                                ? root.workspaceIconSize : root.workspaceIconSizeShrinked
                            anchors.bottom: parent.bottom; anchors.right: parent.right
                            anchors.bottomMargin: (!root.showNumbers && Config.options?.bar.workspaces.showAppIcons)
                                ? (root.btnSize - root.workspaceIconSize) / 2 : root.workspaceIconMarginShrinked
                            anchors.rightMargin: (!root.showNumbers && Config.options?.bar.workspaces.showAppIcons)
                                ? (root.btnSize - root.workspaceIconSize) / 2 : root.workspaceIconMarginShrinked
                            Behavior on implicitSize         { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this) }
                            Behavior on anchors.bottomMargin { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this) }
                            Behavior on anchors.rightMargin  { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this) }
                        }

                        Loader {
                            active: Config.options.bar.workspaces.monochromeIcons
                            anchors.fill: mainAppIcon
                            sourceComponent: Item {
                                Desaturate { id: desat; visible: false; anchors.fill: parent; source: mainAppIcon; desaturation: 0.8 }
                                ColorOverlay { anchors.fill: desat; source: desat; color: ColorUtils.transparentize(wsDot.color, 0.9) }
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: Hyprland.dispatch(`workspace ${parent.wsValue}`)
                    }
                }
            }
        }
    }
}
