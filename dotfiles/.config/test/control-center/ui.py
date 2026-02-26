import gi
gi.require_version("Gtk", "4.0")
from gi.repository import Gtk

from updater import update_moonveil, reload_environment
from bar_control import active_bar, start_waybar, start_moonshell
from about_view import AboutView
from keybinds_view import KeybindsView
from autostart_control import is_autostart_enabled, set_autostart  


class MainWindow(Gtk.ApplicationWindow):
    def __init__(self, app):
        super().__init__(application=app)

        self.set_title("Moonveil Control Center")
        self.set_default_size(900, 500)

        #---headerbar--- (ADDED)
        header = Gtk.HeaderBar()
        header.set_show_title_buttons(True)

        title = Gtk.Label(label="Moonveil Control Center")
        header.set_title_widget(title)

        self.autostart_switch = Gtk.Switch()
        self.autostart_switch.set_active(is_autostart_enabled())
        self.autostart_switch.set_tooltip_text(
            "Launch Moonveil Control Center on login"
        )
        self.autostart_switch.connect(
            "notify::active",
            lambda sw, *_: set_autostart(sw.get_active())
        )

        autostart_box = Gtk.Box(spacing=6)
        autostart_box.append(Gtk.Label(label="Autostart"))
        autostart_box.append(self.autostart_switch)

        header.pack_end(autostart_box)
        self.set_titlebar(header)
        #---end headerbar---

        #---root---
        root = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        self.set_child(root)

        #---sidebar---
        sidebar = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        sidebar.set_margin_top(12)
        sidebar.set_margin_bottom(12)
        sidebar.set_margin_start(12)
        sidebar.set_margin_end(12)
        sidebar.set_size_request(180, -1)
        root.append(sidebar)

        #---stack---
        self.stack = Gtk.Stack()
        self.stack.set_transition_type(Gtk.StackTransitionType.CROSSFADE)
        self.stack.set_transition_duration(200)
        root.append(self.stack)

        #---nav---
        self._add_nav_button(sidebar, "Overview", "overview")
        self._add_nav_button(sidebar, "Bars", "bars")
     #  self._add_nav_button(sidebar, "Wallpapers", "wallpapers")
        self._add_nav_button(sidebar, "Keybinds", "keybinds")
        self._add_nav_button(sidebar, "Updates", "updates")
        self._add_nav_button(sidebar, "About", "about")

        #---pages---
        self._add_overview_page()
        self._add_bars_page()
        self._add_updates_page()
        self._add_about_page()
        self.stack.add_named(KeybindsView(), "keybinds")
     #  self._add_simple_page("Wallpapers", "wallpapers")

    #---nav-helper---
    def _add_nav_button(self, sidebar, label, page):
        btn = Gtk.Button(label=label)
        btn.connect("clicked", lambda *_: self.stack.set_visible_child_name(page))
        sidebar.append(btn)

    #---simple-page---
    def _add_simple_page(self, title_text, name):
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=16)
        box.set_margin_top(24)
        box.set_margin_start(24)

        title = Gtk.Label(label=title_text)
        title.add_css_class("title-1")

        box.append(title)
        self.stack.add_named(box, name)

    #---overview---
    def _add_overview_page(self):
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=16)
        box.set_margin_top(24)
        box.set_margin_start(24)

        title = Gtk.Label(label="Moonveil")
        title.add_css_class("title-1")

        desc = Gtk.Label(
            label= "Moonveil began as a personal experiment and evolved into\na focused Hyprland setup designed for calm, clarity,\nand distraction-free workflows."
        )
        desc.set_wrap(True)

        box.append(title)
        box.append(desc)
        self.stack.add_named(box, "overview")

    #---bars---
    def _add_bars_page(self):
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=16)
        box.set_margin_top(24)
        box.set_margin_start(24)

        title = Gtk.Label(label="Bars")
        title.add_css_class("title-1")

        self.bar_status = Gtk.Label()
        self._update_bar_status()

        waybar_btn = Gtk.Button(label="Use Waybar")
        moonbar_btn = Gtk.Button(label="Use Moonshell")

        waybar_btn.connect("clicked", self._on_waybar)
        moonbar_btn.connect("clicked", self._on_moonshell)

        box.append(title)
        box.append(self.bar_status)
        box.append(waybar_btn)
        box.append(moonbar_btn)

        self.stack.add_named(box, "bars")

    def _update_bar_status(self):
        self.bar_status.set_text(f"Active bar: {active_bar()}")

    def _on_waybar(self, button):
        start_waybar()
        self._update_bar_status()

    def _on_moonshell(self, button):
        start_moonshell()
        self._update_bar_status()

    #---updates---
    def _add_updates_page(self):
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=16)
        box.set_margin_top(24)
        box.set_margin_start(24)

        title = Gtk.Label(label="Updates")
        title.add_css_class("title-1")

        self.update_status = Gtk.Label(label="Idle")

        update_btn = Gtk.Button(label="Update Moonveil")
        reload_btn = Gtk.Button(label="Reload Environment")

        update_btn.connect("clicked", self._on_update)
        reload_btn.connect("clicked", self._on_reload)

        box.append(title)
        box.append(self.update_status)
        box.append(update_btn)
        box.append(reload_btn)

        self.stack.add_named(box, "updates")

    def _on_update(self, button):
        self.update_status.set_text("Updating…")
        result = update_moonveil()
        self.update_status.set_text(result)

    def _on_reload(self, button):
        reload_environment()
        self.update_status.set_text("Environment reloaded")

    #---about---
    def _add_about_page(self):
        about = AboutView()
        self.stack.add_named(about, "about")
