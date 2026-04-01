pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs
import qs.services
import qs.modules
import qs.modules.uikit

Item {
    id: root
    signal appLaunched()
    property string query: ""

    ColumnLayout {
        anchors.fill: parent
        spacing: 14

        // Search bar
        Rectangle {
            Layout.fillWidth: true
            height: 40
            radius: 20
            color: "#1e1e2a"
            border.width: 1
            border.color: searchField.activeFocus ? "#6060cc" : "#333340"
            Behavior on border.color { ColorAnimation { duration: 150 } }

            Row {
                anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                spacing: 10
                Text {
                    text: "🔍"
                    font.pixelSize: 14
                    anchors.verticalCenter: parent.verticalCenter
                }
                TextField {
                    id: searchField
                    width: parent.width - 34
                    anchors.verticalCenter: parent.verticalCenter
                    placeholderText: "Search apps..."
                    placeholderTextColor: "#555"
                    color: "white"
                    font.pixelSize: 13
                    background: null
                    onTextChanged: root.query = text
                    Keys.onEscapePressed: root.query = ""
                    Component.onCompleted: forceActiveFocus()
                }
            }
        }

        // App grid
        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: appGrid.implicitHeight
            clip: true
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            Grid {
                id: appGrid
                width: parent.width
                columns: Math.max(1, Math.floor(width / 180))
                spacing: 8

                Repeater {
                    model: {
                        const all = DesktopEntries.applications.values
                        const q   = root.query.toLowerCase().trim()
                        if (q === "") return all.filter(e => e.noDisplay !== true)
                        return all.filter(e =>
                            e.noDisplay !== true && (
                                (e.name  || "").toLowerCase().includes(q) ||
                                (e.genericName || "").toLowerCase().includes(q) ||
                                (e.comment || "").toLowerCase().includes(q)
                            )
                        )
                    }

                    delegate: Rectangle {
                        required property var modelData
                        width:  (appGrid.width - appGrid.spacing * (appGrid.columns - 1)) / appGrid.columns
                        height: 72
                        radius: 14
                        color:  appHover.containsMouse ? "#28283a" : "#18181f"
                        Behavior on color { ColorAnimation { duration: 100 } }

                        Row {
                            anchors { fill: parent; margins: 12 }
                            spacing: 12

                            IconImage {
                                source: modelData.icon !== "" ? Quickshell.iconPath(modelData.icon, "application-x-executable") : ""
                                implicitSize: 36
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 3
                                width: parent.width - 36 - 12

                                Text {
                                    text: modelData.name || ""
                                    color: "white"
                                    font.pixelSize: 13
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                                Text {
                                    text: modelData.genericName || modelData.comment || ""
                                    color: "#777"
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                    width: parent.width
                                    visible: text !== ""
                                }
                            }
                        }

                        MouseArea {
                            id: appHover
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                modelData.launch()
                                root.query = ""
                                root.appLaunched()
                            }
                        }
                    }
                }
            }
        }
    }
}
