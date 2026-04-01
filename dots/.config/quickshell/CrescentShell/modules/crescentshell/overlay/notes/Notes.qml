import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules
import qs.modules.crescentshell.overlay

StyledOverlayWidget {
    id: root
    title: Translation.tr("Notes")
    showCenterButton: true

    contentItem: NotesContent {
        radius: root.contentRadius
        isClickthrough: root.clickthrough
    }
}
