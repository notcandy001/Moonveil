import QtQuick
import Quickshell

import qs.core
import qs.shell.bar
import qs.shell.background
import qs.shell.cheatsheet
import qs.shell.dock
import qs.shell.lock
import qs.shell.mediaControls
import qs.shell.notificationPopup
import qs.shell.osd
import qs.shell.onScreenKeyboard
import qs.shell.launcher
import qs.shell.polkit
import qs.shell.regionSelector
import qs.shell.screenCorners
import qs.shell.session
import qs.shell.controlCenter
import qs.shell.notifications
import qs.shell.overlay
import qs.shell.verticalBar
import qs.shell.wallpaperSelector

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
