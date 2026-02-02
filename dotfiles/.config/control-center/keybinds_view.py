import gi
gi.require_version("Gtk", "4.0")
from gi.repository import Gtk
import tomllib
import os


KEYBINDS_FILE = os.path.expanduser(
    "~/.config/keybinds.toml"
)


class KeybindsView(Gtk.ScrolledWindow):
    def __init__(self):
        super().__init__()

        self.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC)

        self.box = Gtk.Box(
            orientation=Gtk.Orientation.VERTICAL,
            spacing=16
        )
        self.box.set_margin_top(24)
        self.box.set_margin_start(24)
        self.box.set_margin_end(24)

        self.set_child(self.box)

        self._load_keybinds()

    # ---------------- Keybind loading ---------------- #

    def _load_keybinds(self):
        if not os.path.exists(KEYBINDS_FILE):
            self.box.append(Gtk.Label(label="Keybinds file not found"))
            return

        with open(KEYBINDS_FILE, "rb") as f:
            data = tomllib.load(f)

        keybinds = data.get("keybind", [])

        categories = {}
        for bind in keybinds:
            cat = bind.get("category", "Other")
            categories.setdefault(cat, []).append(bind)

        for category, binds in categories.items():
            self._add_category(category, binds)

    # ---------------- UI helpers ---------------- #

    def _add_category(self, name, binds):
        title = Gtk.Label(label=name)
        title.add_css_class("title-2")
        title.set_xalign(0)

        self.box.append(title)

        for bind in binds:
            self._add_bind_row(bind)

    def _add_bind_row(self, bind):
        row = Gtk.Box(
            orientation=Gtk.Orientation.HORIZONTAL,
            spacing=12
        )

        combo = Gtk.Label(label=bind.get("combo", ""))
        combo.set_xalign(0)
        combo.set_hexpand(True)
        combo.add_css_class("monospace")

        action = Gtk.Label(label=bind.get("action", ""))
        action.set_xalign(0)
        action.set_wrap(True)

        row.append(combo)
        row.append(action)

        self.box.append(row)
