import os
import subprocess
import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, Gdk, GdkPixbuf, GLib

HOME = os.path.expanduser("~")
THEMES_DIR = os.path.join(HOME, ".config/moonveil/themes")


# --------------- apply theme ------------

def apply_theme(theme):
    theme_path = os.path.join(THEMES_DIR, theme)

    # HYPR
    os.makedirs(os.path.join(HOME, ".config/hypr"), exist_ok=True)
    with open(os.path.join(HOME, ".config/hypr/theme.conf"), "w") as f:
        f.write(f"source = {theme_path}/hypr.conf\n")

    # WAYBAR
    os.makedirs(os.path.join(HOME, ".config/waybar"), exist_ok=True)
    with open(os.path.join(HOME, ".config/waybar/theme.css"), "w") as f:
        f.write(f'@import "{theme_path}/waybar.css";\n')

    # KITTY
    os.makedirs(os.path.join(HOME, ".config/kitty"), exist_ok=True)
    with open(os.path.join(HOME, ".config/kitty/theme.conf"), "w") as f:
        f.write(f"include {theme_path}/kitty.conf\n")

    # GTK3
    gtk3_dir = os.path.join(HOME, ".config/gtk-3.0")
    os.makedirs(gtk3_dir, exist_ok=True)
    with open(os.path.join(gtk3_dir, "theme.css"), "w") as f:
        f.write(f'@import "{theme_path}/gtk3.css";\n')

    # GTK4
    gtk4_dir = os.path.join(HOME, ".config/gtk-4.0")
    os.makedirs(gtk4_dir, exist_ok=True)
    with open(os.path.join(gtk4_dir, "theme.css"), "w") as f:
        f.write(f'@import "{theme_path}/gtk4.css";\n')

    subprocess.run(["hyprctl", "reload"])
    subprocess.run(["killall", "-SIGUSR2", "waybar"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    subprocess.run(["pkill", "-USR1", "kitty"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


# --------------- Theme Card ------------

class ThemeCard(Gtk.EventBox):
    CARD_WIDTH = 220
    CARD_HEIGHT = 150

    def __init__(self, name, index, parent):
        super().__init__()
        self.name = name
        self.index = index
        self.parent = parent

        self.set_visible_window(False)

        frame = Gtk.Frame()
        frame.set_name("card-frame")

        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        box.set_margin_top(6)
        box.set_margin_bottom(6)
        box.set_margin_start(6)
        box.set_margin_end(6)

        preview = os.path.join(THEMES_DIR, name, "preview.png")

        if os.path.exists(preview):
            pixbuf = GdkPixbuf.Pixbuf.new_from_file(preview)
            scaled = pixbuf.scale_simple(
                180, 110,
                GdkPixbuf.InterpType.BILINEAR
            )
            image = Gtk.Image.new_from_pixbuf(scaled)
            box.pack_start(image, False, False, 0)

        label = Gtk.Label(label=name.capitalize())
        label.set_name("card-label")
        box.pack_start(label, False, False, 4)

        frame.add(box)
        self.add(frame)

        self.set_size_request(self.CARD_WIDTH, self.CARD_HEIGHT)

        # Mouse click
        self.connect("button-press-event", self.on_click)

    def on_click(self, *_):
        self.parent.index = self.index
        self.parent.center_selected()
        apply_theme(self.name)
        Gtk.main_quit()


# --------------- Selector ------------

class Selector(Gtk.Window):
    SPACING = 30

    def __init__(self):
        super().__init__()

        self.set_title("moonveil")
        self.set_default_size(720, 320)
        self.set_decorated(False)
        self.set_name("main-window")

        self.set_app_paintable(True)
        self.set_visual(self.get_screen().get_rgba_visual())

        self.themes = sorted(os.listdir(THEMES_DIR))
        self.index = 0
        self.current_x = 0

        overlay = Gtk.Overlay()
        self.add(overlay)

        container = Gtk.Box()
        container.set_halign(Gtk.Align.CENTER)
        container.set_valign(Gtk.Align.CENTER)
        overlay.add(container)

        self.fixed = Gtk.Fixed()
        container.pack_start(self.fixed, True, True, 0)

        self.carousel = Gtk.Box(
            orientation=Gtk.Orientation.HORIZONTAL,
            spacing=self.SPACING
        )

        self.fixed.put(self.carousel, 0, 80)

        self.cards = []
        for i, theme in enumerate(self.themes):
            card = ThemeCard(theme, i, self)
            self.cards.append(card)
            self.carousel.pack_start(card, False, False, 0)

        self.center_selected(initial=True)

        self.connect("key-press-event", self.on_key)
        self.connect("destroy", Gtk.main_quit)

        self.set_can_focus(True)
        self.grab_focus()

    # --------------- smooth slide ------------

    def center_selected(self, initial=False):
        card_full = ThemeCard.CARD_WIDTH + self.SPACING
        target_x = -self.index * card_full + 240

        if initial:
            self.current_x = target_x
            self.fixed.move(self.carousel, int(self.current_x), 80)
            self.update_highlight()
            return

        step = (target_x - self.current_x) / 10

        def animate():
            if abs(self.current_x - target_x) < 2:
                self.current_x = target_x
                self.fixed.move(self.carousel, int(self.current_x), 110)
                return False

            self.current_x += step
            self.fixed.move(self.carousel, int(self.current_x), 110)
            return True

        GLib.timeout_add(16, animate)
        self.update_highlight()

    # --------------- highlight ------------

    def update_highlight(self):
        for i, card in enumerate(self.cards):
            if i == self.index:
                card.set_name("active-card")
                card.set_opacity(1.0)
            else:
                card.set_name("inactive-card")
                card.set_opacity(0.4)

    # --------------- input ------------

    def on_key(self, widget, event):
        key = event.keyval

        if key == Gdk.KEY_Right:
            self.index = (self.index + 1) % len(self.themes)
            self.center_selected()

        elif key == Gdk.KEY_Left:
            self.index = (self.index - 1) % len(self.themes)
            self.center_selected()

        elif key == Gdk.KEY_Return:
            apply_theme(self.themes[self.index])
            Gtk.main_quit()

        elif key == Gdk.KEY_Escape:
            Gtk.main_quit()


# --------------- CSS ------------

def load_css():
    css = b"""
    #main-window {
        background: rgba(20, 24, 32, 0.8);
        border-radius: 18px;
    }

    #card-frame {
        background: rgba(40, 45, 55, 0.95);
        border-radius: 12px;
        padding: 4px;
    }

    #active-card #card-frame {
        border: 2px solid #89b4fa;
    }

    #inactive-card #card-frame {
        border: 1px solid #2a2f3a;
    }

    #card-label {
        color: #cdd6f4;
        font-size: 12px;
    }
    """

    provider = Gtk.CssProvider()
    provider.load_from_data(css)

    Gtk.StyleContext.add_provider_for_screen(
        Gdk.Screen.get_default(),
        provider,
        Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
    )


# --------------- main ------------

if __name__ == "__main__":
    load_css()
    win = Selector()
    win.show_all()
    Gtk.main()
