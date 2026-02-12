import os
import subprocess
import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk

HOME = os.path.expanduser("~")
THEMES_DIR = os.path.join(HOME, ".config/moonveil/themes")
STATE_FILE = os.path.join(HOME, ".config/moonveil/current_theme")


# --------------- helpers ------------

def safe_write(path, content):
    with open(path, "w") as f:
        f.write(content)


def safe_run(cmd):
    try:
        subprocess.run(cmd, check=True)
    except:
        pass


# --------------- hypr ------------

def ensure_hypr():
    main_path = os.path.join(HOME, ".config/hypr/hyprland.conf")
    inject_line = "source = ~/.config/hypr/theme.conf"
    theme_conf = os.path.join(HOME, ".config/hypr/theme.conf")

    os.makedirs(os.path.dirname(main_path), exist_ok=True)

    if not os.path.exists(main_path):
        open(main_path, "w").close()

    with open(main_path, "r") as f:
        lines = f.readlines()

    found = False
    new_lines = []

    for line in lines:
        if "theme.conf" in line:
            new_lines.append(inject_line + "\n")
            found = True
        else:
            new_lines.append(line)

    if not found:
        new_lines.append("\n" + inject_line + "\n")

    with open(main_path, "w") as f:
        f.writelines(new_lines)

    if not os.path.exists(theme_conf):
        open(theme_conf, "w").close()


# --------------- waybar ------------

def ensure_waybar():
    main_path = os.path.join(HOME, ".config/waybar/style.css")
    theme_file = os.path.join(HOME, ".config/waybar/theme.css")
    inject_line = '@import "theme.css";'

    os.makedirs(os.path.dirname(main_path), exist_ok=True)

    if not os.path.exists(main_path):
        open(main_path, "w").close()

    with open(main_path, "r") as f:
        lines = f.readlines()

    found = False
    new_lines = []

    for line in lines:
        if 'theme.css' in line:
            new_lines.append(inject_line + "\n")
            found = True
        else:
            new_lines.append(line)

    if not found:
        new_lines.insert(0, inject_line + "\n")

    with open(main_path, "w") as f:
        f.writelines(new_lines)

    if not os.path.exists(theme_file):
        open(theme_file, "w").close()


# --------------- kitty ------------

def ensure_kitty():
    main_path = os.path.join(HOME, ".config/kitty/kitty.conf")
    theme_file = os.path.join(HOME, ".config/kitty/theme.conf")
    inject_line = "include theme.conf"

    os.makedirs(os.path.dirname(main_path), exist_ok=True)

    if not os.path.exists(main_path):
        open(main_path, "w").close()

    with open(main_path, "r") as f:
        lines = f.readlines()

    found = False
    new_lines = []

    for line in lines:
        if "theme.conf" in line:
            new_lines.append(inject_line + "\n")
            found = True
        else:
            new_lines.append(line)

    if not found:
        new_lines.append("\n" + inject_line + "\n")

    with open(main_path, "w") as f:
        f.writelines(new_lines)

    if not os.path.exists(theme_file):
        open(theme_file, "w").close()


# --------------- gtk ------------

def ensure_gtk(version):
    folder = os.path.join(HOME, f".config/gtk-{version}.0")
    main_file = os.path.join(folder, "gtk.css")
    theme_file = os.path.join(folder, "theme.css")
    inject_line = '@import "theme.css";'

    os.makedirs(folder, exist_ok=True)

    if not os.path.exists(main_file):
        open(main_file, "w").close()

    with open(main_file, "r") as f:
        lines = f.readlines()

    found = False
    new_lines = []

    for line in lines:
        if 'theme.css' in line:
            new_lines.append(inject_line + "\n")
            found = True
        else:
            new_lines.append(line)

    if not found:
        new_lines.insert(0, inject_line + "\n")

    with open(main_file, "w") as f:
        f.writelines(new_lines)

    if not os.path.exists(theme_file):
        open(theme_file, "w").close()


# --------------- apply theme ------------

def apply_theme(theme):
    theme_path = os.path.join(THEMES_DIR, theme)

    # hypr
    safe_write(
        os.path.join(HOME, ".config/hypr/theme.conf"),
        f"source = {theme_path}/hypr.conf\n"
    )

    # waybar
    safe_write(
        os.path.join(HOME, ".config/waybar/theme.css"),
        f'@import "{theme_path}/waybar.css";\n'
    )

    # kitty
    safe_write(
        os.path.join(HOME, ".config/kitty/theme.conf"),
        f"include {theme_path}/kitty.conf\n"
    )

    # live reload kitty colors
    safe_run([
        "kitty", "@", "set-colors", "--all",
        os.path.join(theme_path, "kitty.conf")
    ])

    # gtk3
    safe_write(
        os.path.join(HOME, ".config/gtk-3.0/theme.css"),
        f'@import "{theme_path}/gtk3.css";\n'
    )

    # gtk4
    safe_write(
        os.path.join(HOME, ".config/gtk-4.0/theme.css"),
        f'@import "{theme_path}/gtk4.css";\n'
    )

    # wallpaper
    wallpaper = os.path.join(theme_path, "wallpaper.jpg")
    if os.path.exists(wallpaper):
        safe_run(["swww", "img", wallpaper])

    # reload services
    safe_run(["hyprctl", "reload"])
    safe_run(["killall", "-SIGUSR2", "waybar"])
    safe_run(["pkill", "-USR2", "swaync"])

    safe_write(STATE_FILE, theme)


# --------------- setup ------------

def initial_setup():
    ensure_hypr()
    ensure_waybar()
    ensure_kitty()
    ensure_gtk(3)
    ensure_gtk(4)


# --------------- ui ------------

class ThemeButton(Gtk.Button):
    def __init__(self, name):
        super().__init__(label=name.capitalize())
        self.name = name
        self.connect("clicked", self.on_click)

    def on_click(self, *_):
        apply_theme(self.name)
        Gtk.main_quit()


class Selector(Gtk.Window):
    def __init__(self):
        super().__init__(title="Moonveil Themer")
        self.set_default_size(600, 400)

        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        self.add(box)

        for theme in os.listdir(THEMES_DIR):
            box.pack_start(ThemeButton(theme), False, False, 0)

        self.connect("destroy", Gtk.main_quit)


# --------------- main ------------

if __name__ == "__main__":
    initial_setup()
    win = Selector()
    win.show_all()
    Gtk.main()

