import QtQuick
import Quickshell.Services.UPower

// Thin wrapper around Quickshell's UPower service.
//
// UPower.displayDevice already emits property-changed signals on its own —
// there is no manual polling here. This item just exposes the bits Pill.qml
// needs (percentage text + a rough icon) as plain properties, and only
// exists at all while it is instantiated by a Loader (i.e. while the pill
// is visible), so there is no battery-watching cost while Trez is hidden.
Item {
    id: root

    readonly property var device: UPower.displayDevice
    readonly property bool available: device !== null && device.ready
    readonly property real percentage: available ? device.percentage : 0
    readonly property bool charging: available && device.state === UPowerDeviceState.Charging

    readonly property string percentText: available
        ? Math.round(percentage * 100) + "%"
        : "--"

    // Coarse 5-step icon selection; swapped for real assets/icon font later.
    readonly property string icon: {
        if (!available) return "\uf590" // battery-unknown-ish glyph
        if (charging) return "\uf585"
        const p = percentage
        if (p >= 0.9) return "\uf578"
        if (p >= 0.6) return "\uf581"
        if (p >= 0.3) return "\uf57e"
        if (p >= 0.15) return "\uf57a"
        return "\uf58d"
    }
}
