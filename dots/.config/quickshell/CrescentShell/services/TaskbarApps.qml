pragma Singleton

import qs.modules
import qs.services
import QtQuick
import Quickshell
import Quickshell.Wayland

Singleton {
    id: root

    // Re-evaluate apps list when daemon comes up or goes down
    Connections {
        target: RodctlService
        function onRunningChanged() { root.appsChanged() }
    }

    function isPinned(appId) {
        return Config.options.dock.pinnedApps.indexOf(appId) !== -1;
    }

    function togglePin(appId) {
        if (root.isPinned(appId)) {
            Config.options.dock.pinnedApps = Config.options.dock.pinnedApps.filter(id => id !== appId)
        } else {
            Config.options.dock.pinnedApps = Config.options.dock.pinnedApps.concat([appId])
        }
    }

    property list<var> apps: {
        var map = new Map();

        // Pinned apps — always show
        const pinnedApps = Config.options?.dock.pinnedApps ?? [];
        for (const appId of pinnedApps) {
            if (!map.has(appId.toLowerCase())) map.set(appId.toLowerCase(), ({
                pinned: true,
                toplevels: []
            }));
        }

        // Separator
        if (pinnedApps.length > 0) {
            map.set("SEPARATOR", { pinned: false, toplevels: [] });
        }

        // Open windows — only populate when rodctl daemon is running
        if (RodctlService.running) {
            const ignoredRegexStrings = Config.options?.dock.ignoredAppRegexes ?? [];
            const ignoredRegexes = ignoredRegexStrings.map(pattern => new RegExp(pattern, "i"));
            for (const toplevel of ToplevelManager.toplevels.values) {
                if (ignoredRegexes.some(re => re.test(toplevel.appId))) continue;
                if (!map.has(toplevel.appId.toLowerCase())) map.set(toplevel.appId.toLowerCase(), ({
                    pinned: false,
                    toplevels: []
                }));
                map.get(toplevel.appId.toLowerCase()).toplevels.push(toplevel);
            }
        }

        var values = [];
        for (const [key, value] of map) {
            values.push(appEntryComp.createObject(null, { appId: key, toplevels: value.toplevels, pinned: value.pinned }));
        }
        return values;
    }

    component TaskbarAppEntry: QtObject {
        id: wrapper
        required property string appId
        required property list<var> toplevels
        required property bool pinned
    }
    Component {
        id: appEntryComp
        TaskbarAppEntry {}
    }
}
