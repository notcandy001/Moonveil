# paths.py
import os

HOME = os.path.expanduser("~")

# ~/.config
CONFIG = os.path.join(HOME, ".config")

# Control Center path (FIXED)
CONTROL_CENTER = os.path.join(CONFIG, "control-center")

# binaries
MOONBAR_CMD = "moonbar-run"
WAYBAR_CMD = "waybar"

# sanity check
def assert_paths():
    if not os.path.isdir(CONTROL_CENTER):
        raise RuntimeError("Control Center directory not found")
