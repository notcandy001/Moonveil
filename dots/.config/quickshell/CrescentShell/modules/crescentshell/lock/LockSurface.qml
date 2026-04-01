pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell.Services.Pam
import qs
import qs.services
import qs.modules
import qs.modules.uikit
import qs.modules.functions
import qs.modules.panels.lock
import Quickshell

Item {
    id: root
    required property LockContext context

    property bool error: false
    property string inputBuffer: ""
    property string maskedBuffer: ""
    property bool unlocking: false
    readonly property var kokomi: ["k","o","k","o","m","i"]

    function forceFieldFocus() { inputRect.forceActiveFocus() }
    Connections {
        target: root.context
        function onShouldReFocus() { root.forceFieldFocus() }
    }
    Component.onCompleted: root.forceFieldFocus()

    // ── Wallpaper ─────────────────────────────────────────────
    Image {
        anchors.fill: parent
        source: Config.options.background.wallpaperPath
        fillMode: Image.PreserveAspectCrop
        cache: false; smooth: true; asynchronous: true
        layer.enabled: true
        layer.effect: FastBlur {
            id: wallBlur
            radius: 0; cached: true
            NumberAnimation on radius {
                from: 0; to: 54; duration: 600
                easing.type: Easing.InOutQuad; running: true
            }
            NumberAnimation {
                target: wallBlur; property: "radius"
                from: 54; to: 0; duration: 500
                easing.type: Easing.InOutQuad
                running: root.unlocking
            }
        }
    }

    // ── Barcode ───────────────────────────────────────────────
    Item {
        anchors.centerIn: parent
        clip: true
        height: kokomiText.contentHeight
        width: pam.active ? 0 : kokomiText.contentWidth

        Behavior on width {
            NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
        }

        Rectangle {
            id: gradientRect
            anchors.fill: kokomiText
            visible: false
            gradient: Gradient {
                GradientStop {
                    color: root.error
                        ? Appearance.m3colors.m3error
                        : Appearance.colors.colPrimary
                    position: 0.0
                }
                GradientStop {
                    color: root.error
                        ? Qt.darker(Appearance.m3colors.m3error, 1.3)
                        : (Appearance.m3colors.m3tertiary ?? Appearance.colors.colPrimary)
                    position: 1.0
                }
            }
        }

        Text {
            id: kokomiText
            anchors.centerIn: parent
            anchors.verticalCenterOffset: contentHeight * 0.2
            font.bold: true
            font.family: "Libre Barcode 128"
            font.pointSize: 400
            layer.enabled: true
            layer.smooth: true
            renderType: Text.NativeRendering
            text: root.maskedBuffer
            visible: false
        }

        OpacityMask {
            anchors.fill: gradientRect
            source: gradientRect
            maskSource: kokomiText
        }
    }

    // ── Input pill ────────────────────────────────────────────
    Rectangle {
        id: inputRect
        anchors.centerIn: parent
        clip: true
        focus: true
        height: 40
        radius: 20
        width: inputRow.implicitWidth
        color: root.error
            ? Appearance.m3colors.m3error
            : root.unlocking
                ? Appearance.colors.colPrimary
                : Appearance.colors.colLayer1

        Behavior on color { ColorAnimation { duration: 200 } }
        Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

        NumberAnimation on opacity {
            from: 0; to: 1; duration: 400
            easing.type: Easing.InOutQuad; running: true
        }

        SequentialAnimation {
            running: root.unlocking
            PauseAnimation { duration: 600 }
            NumberAnimation {
                target: inputRect; property: "opacity"
                from: 1; to: 0; duration: 300
                easing.type: Easing.Linear
            }
        }

        Keys.onPressed: event => {
            if (pam.active) return

            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                pam.start(); return
            }
            if (event.key === Qt.Key_Backspace) {
                if (event.modifiers & Qt.ControlModifier) {
                    root.inputBuffer = ""; root.maskedBuffer = ""; return
                }
                root.inputBuffer = root.inputBuffer.slice(0, -1)
                root.maskedBuffer = root.maskedBuffer.slice(0, -1)
                return
            }
            if (event.key === Qt.Key_Escape) {
                root.inputBuffer = ""; root.maskedBuffer = ""; return
            }
            if (event.text) {
                root.inputBuffer += event.text
                root.maskedBuffer += root.kokomi[Math.floor(Math.random() * 6)]
            }
        }

        MouseArea {
            id: rowMarea
            anchors.centerIn: parent
            height: inputRow.height
            width: inputRow.width
            hoverEnabled: true

            RowLayout {
                id: inputRow
                anchors.centerIn: parent
                height: inputRect.height
                spacing: 0

                // Sleep (hover only)
                Item {
                    Layout.fillHeight: true
                    implicitWidth: height
                    opacity: rowMarea.containsMouse ? 1 : 0
                    visible: true

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "bedtime"; iconSize: 18; fill: 1
                        color: root.error ? Appearance.m3colors.m3onError
                            : root.unlocking ? Appearance.m3colors.m3onPrimary
                            : Appearance.colors.colOnLayer1
                    }
                    MouseArea {
                        anchors.fill: parent; anchors.margins: 4
                        onClicked: Session.suspend()
                    }
                }

                // Lock icon (always visible, spins when checking)
                Item {
                    Layout.fillHeight: true
                    implicitWidth: height

                    MaterialSymbol {
                        id: lockIcon
                        anchors.centerIn: parent
                        text: "lock"; iconSize: 18
                        fill: pam.active ? 1 : 0
                        color: root.error ? Appearance.m3colors.m3onError
                            : root.unlocking ? Appearance.m3colors.m3onPrimary
                            : Appearance.colors.colOnLayer1
                        Behavior on color { ColorAnimation { duration: 200 } }
                        Behavior on rotation {
                            NumberAnimation { duration: 500; easing.type: Easing.Linear }
                        }
                    }

                    Timer {
                        id: lockRotateTimer
                        interval: 500; repeat: true
                        running: pam.active; triggeredOnStart: true
                        onRunningChanged: {
                            if (lockIcon.rotation < 180) lockIcon.rotation = 360
                            else lockIcon.rotation = 0
                        }
                        onTriggered: lockIcon.rotation += 50
                    }
                }

                // Fingerprint (when available)
                Item {
                    Layout.fillHeight: true
                    implicitWidth: height
                    visible: pam.message.includes("fingerprint")

                    Connections {
                        target: pam
                        function onMessageChanged() {
                            if (pam.message.includes("Failed")) {
                                fpIcon.text = "fingerprint_off"
                                reFingerTimer.start()
                            }
                        }
                    }
                    Timer {
                        id: reFingerTimer; interval: 300
                        onTriggered: fpIcon.text = "fingerprint"
                    }

                    MaterialSymbol {
                        id: fpIcon
                        anchors.centerIn: parent
                        text: "fingerprint"; iconSize: 18
                        color: root.error ? Appearance.m3colors.m3onError
                            : root.unlocking ? Appearance.m3colors.m3onPrimary
                            : reFingerTimer.running ? Appearance.m3colors.m3error
                            : Appearance.colors.colOnLayer1
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }
                }

                // Login (hover only)
                Item {
                    Layout.fillHeight: true
                    implicitWidth: height
                    opacity: (rowMarea.containsMouse && !pam.active && !root.unlocking) ? 1 : 0
                    visible: true

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "login"; iconSize: 18; fill: 1
                        color: root.error ? Appearance.m3colors.m3onError
                            : root.unlocking ? Appearance.m3colors.m3onPrimary
                            : Appearance.colors.colOnLayer1
                    }
                    MouseArea {
                        anchors.fill: parent; anchors.margins: 4
                        onClicked: pam.start()
                    }
                }
            }
        }
    }

    // ── PAM ───────────────────────────────────────────────────
    PamContext {
        id: pam
        onCompleted: res => {
            if (res === PamResult.Success) {
                root.unlocking = true
                root.inputBuffer = ""
                root.maskedBuffer = ""
                return
            }
            root.error = true
            revertColors.running = true
        }
        onResponseRequiredChanged: {
            if (!responseRequired) return
            respond(root.inputBuffer)
            root.inputBuffer = ""
            root.maskedBuffer = ""
        }
    }

    Timer { id: revertColors; interval: 2000; onTriggered: root.error = false }

    Timer {
        interval: 800
        running: root.unlocking
        onTriggered: GlobalStates.screenLocked = false
    }
}
