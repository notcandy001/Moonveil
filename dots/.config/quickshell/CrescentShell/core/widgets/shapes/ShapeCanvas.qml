import QtQuick
Rectangle {
    id: root
    property var shape
    property double implicitSize: 32
    property bool polygonIsNormalized: true
    property var roundedPolygon
    implicitWidth: implicitSize
    implicitHeight: implicitSize
    radius: width / 2
    color: "transparent"
}
