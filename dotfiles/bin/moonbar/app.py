import os
import gi

gi.require_version("GLib", "2.0")

import setproctitle
from fabric import Application
from gi.repository import GLib

from fabric.utils import exec_shell_command_async

from config.data import (
    APP_NAME,
    APP_NAME_CAP,
    CACHE_DIR,
    CONFIG_FILE,
)

from moonbar.moonbar import Bar
from moonbar.modules.corners import Corners
from moonbar.modules.dock import Dock
from moonbar.modules.notch import Notch
from moonbar.modules.notifications import NotificationPopup
from moonbar.modules.updater import run_updater


# ----------------------------
# Paths
# ----------------------------
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
fonts_updated_file = f"{CACHE_DIR}/fonts_updated"


# ----------------------------
# Main
# ----------------------------
if __name__ == "__main__":
    setproctitle.setproctitle(APP_NAME)

    # Generate config if missing
    if not os.path.isfile(CONFIG_FILE):
        config_script_path = os.path.join(BASE_DIR, "config", "config.py")
        exec_shell_command_async(f"python {config_script_path}")

    # Ensure wallpaper symlink exists
    current_wallpaper = os.path.expanduser("~/.current.wall")
    if not os.path.exists(current_wallpaper):
        example_wallpaper = os.path.expanduser(
            f"~/.config/{APP_NAME_CAP}/assets/wallpapers_example/example-1.jpg"
        )
        if os.path.exists(example_wallpaper):
            os.symlink(example_wallpaper, current_wallpaper)

    # Load config
    from config.data import load_config
    config = load_config()

    # Updater
    GLib.idle_add(run_updater)
    GLib.timeout_add(3600000, run_updater)

    # ----------------------------
    # Monitor handling
    # ----------------------------
    try:
        from utils.monitor_manager import get_monitor_manager
        from services.monitor_focus import get_monitor_focus_service

        monitor_manager = get_monitor_manager()
        monitor_focus_service = get_monitor_focus_service()
        monitor_manager.set_monitor_focus_service(monitor_focus_service)

        all_monitors = monitor_manager.get_monitors()
        multi_monitor_enabled = True
    except Exception:
        all_monitors = [{"id": 0, "name": "default"}]
        monitor_manager = None
        multi_monitor_enabled = False

    selected_monitors = config.get("selected_monitors", [])
    if not selected_monitors:
        monitors = all_monitors
        print("Ax-Shell: No specific monitors selected, showing on all monitors")
    else:
        monitors = [
            m for m in all_monitors
            if m.get("name", f"monitor-{m['id']}") in selected_monitors
        ] or all_monitors

    # ----------------------------
    # Components
    # ----------------------------
    app_components = []
    corners = None
    notification = None

    for monitor in monitors:
        monitor_id = monitor["id"]

        # Corners only once
        if monitor_id == 0:
            corners = Corners()
            corners.set_visible(config.get("corners_visible", True))
            app_components.append(corners)

        if multi_monitor_enabled:
            bar = Bar(monitor_id=monitor_id)
            notch = Notch(monitor_id=monitor_id)
            dock = Dock(monitor_id=monitor_id)
        else:
            bar = Bar()
            notch = Notch()
            dock = Dock()

        # Wire island <-> bar
        bar.notch = notch
        notch.bar = bar

        if monitor_id == 0:
            notification = NotificationPopup(
                widgets=notch.dashboard.widgets
            )
            app_components.append(notification)

        if monitor_manager:
            monitor_manager.register_monitor_instances(
                monitor_id,
                {
                    "bar": bar,
                    "notch": notch,
                    "dock": dock,
                    "corners": corners if monitor_id == 0 else None,
                },
            )

        app_components.extend([bar, notch, dock])

    # ----------------------------
    # Application
    # ----------------------------
    app = Application(APP_NAME, *app_components)

    # ✅ FIXED CSS LOADER (THIS WAS YOUR BIG ISSUE)
    def set_css():
        css_path = os.path.join(BASE_DIR, "main.css")
        app.set_stylesheet_from_file(css_path)

    app.set_css = set_css
    app.set_css()

    app.run()
