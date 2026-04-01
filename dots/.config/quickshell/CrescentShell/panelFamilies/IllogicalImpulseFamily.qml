import QtQuick
import Quickshell

import qs.modules
import qs.modules.crescentshell.background
import qs.modules.crescentshell.bar
import qs.modules.crescentshell.cheatsheet
import qs.modules.crescentshell.dock
import qs.modules.crescentshell.lock
import qs.modules.crescentshell.mediaControls
import qs.modules.crescentshell.notificationPopup
import qs.modules.crescentshell.onScreenDisplay
import qs.modules.crescentshell.onScreenKeyboard
import qs.modules.crescentshell.overview
import qs.modules.crescentshell.polkit
import qs.modules.crescentshell.regionSelector
import qs.modules.crescentshell.screenCorners
import qs.modules.crescentshell.sessionScreen
import qs.modules.crescentshell.sidebarLeft
import qs.modules.crescentshell.sidebarRight
import qs.modules.crescentshell.overlay
import qs.modules.crescentshell.verticalBar
import qs.modules.crescentshell.wallpaperSelector

Scope {
    PanelLoader { extraCondition: !Config.options.bar.vertical; component: Bar {} }
    PanelLoader { component: Background {} }
    PanelLoader { component: Cheatsheet {} }
    PanelLoader { extraCondition: Config.options.dock.enable; component: Dock {} }
    PanelLoader { component: Lock {} }
    PanelLoader { component: MediaControls {} }
    PanelLoader { component: NotificationPopup {} }
    PanelLoader { component: OnScreenDisplay {} }
    PanelLoader { component: OnScreenKeyboard {} }
    PanelLoader { component: Overlay {} }
    PanelLoader { component: Overview {} }
    PanelLoader { component: Polkit {} }
    PanelLoader { component: RegionSelector {} }
    PanelLoader { component: ScreenCorners {} }
    PanelLoader { component: SessionScreen {} }
    PanelLoader { component: SidebarLeft {} }
    PanelLoader { component: SidebarRight {} }
    PanelLoader { extraCondition: Config.options.bar.vertical; component: VerticalBar {} }
    PanelLoader { component: WallpaperSelector {} }
}
