# app.py
import gi
gi.require_version("Gtk", "4.0")
from gi.repository import Gtk, Gio

from ui import MainWindow
from paths import assert_paths

class MoonveilApp(Gtk.Application):
    def __init__(self):
        super().__init__(
            application_id="io.moonveil.ControlCenter",
            flags=Gio.ApplicationFlags.FLAGS_NONE,
        )

    def do_activate(self):
        assert_paths()
        win = MainWindow(self)
        win.present()
