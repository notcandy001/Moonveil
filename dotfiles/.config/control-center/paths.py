# paths.py
import os

HOME = os.path.expanduser("~")
MOONVEIL = os.path.join(HOME, "Moonveil")

CONFIG = os.path.join(MOONVEIL, "config")
BIN    = os.path.join(MOONVEIL, "bin")
SHARE  = os.path.join(MOONVEIL, "share")

CONTROL_CENTER = os.path.join(MOONVEIL, "control-center")

# binaries (symlinked to ~/.local/bin)
MOONBAR_CMD = "moonbar-run"
WAYBAR_CMD  = "waybar"

# sanity check helper
def assert_paths():
    if not os.path.isdir(MOONVEIL):
        raise RuntimeError("Moonveil directory not found")
