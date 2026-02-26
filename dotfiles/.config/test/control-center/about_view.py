import gi
gi.require_version("Gtk", "4.0")
from gi.repository import Gtk
import webbrowser
import platform
import os


class AboutView(Gtk.Box):
    def __init__(self):
        super().__init__(orientation=Gtk.Orientation.VERTICAL, spacing=16)

        self.set_margin_top(24)
        self.set_margin_bottom(24)
        self.set_margin_start(24)
        self.set_margin_end(24)

        # --- Title ---
        title = Gtk.Label(label="About Moonveil")
        title.add_css_class("title-1")
        title.set_xalign(0)
        self.append(title)

        # --- Description / Story ---
        desc = Gtk.Label(
            label=(
                "Moonveil started quietly, as a personal hobby — a place to experiment,\n"
                "learn, and shape a desktop that felt calm rather than overwhelming.\n\n"
                "Over time, it grew into a focused Hyprland-based environment, guided by\n"
                "small details: smooth motion, soft transitions, and a layout that stays\n"
                "out of the way when you just want to work.\n\n"
                "Moonveil is not about chasing features or visual noise. It is about\n"
                "building a space that feels steady, intentional, and comfortable to\n"
                "live in every day."
            )
        )
        desc.set_xalign(0)
        desc.set_wrap(True)
        self.append(desc)

        self.append(Gtk.Separator())

        # --- System info ---
        info = Gtk.Label(label=self._system_info())
        info.set_xalign(0)
        info.set_wrap(True)
        info.add_css_class("dim-label")
        self.append(info)

        self.append(Gtk.Separator())

        # --- GitHub button ---
        github_btn = Gtk.Button(label="Moonveil Dots")
        github_btn.connect("clicked", self._open_github)
        self.append(github_btn)

    def _open_github(self, button):
        webbrowser.open("https://github.com/notcandy001/Moonveil")

    def _system_info(self):
        user = os.getenv("USER", "unknown")
        return (
            f"User: {user}\n"
            f"OS: {platform.system()} {platform.release()}\n"
            f"Architecture: {platform.machine()}"
        )
