import subprocess
import os
from pathlib import Path

MOONVEIL_DIR = Path.home() / "moonveil"


def update_moonveil():
    if not MOONVEIL_DIR.exists():
        return "Moonveil directory not found"

    try:
        subprocess.run(
            ["git", "pull"],
            cwd=MOONVEIL_DIR,
            check=True
        )
        return "Moonveil updated successfully"
    except subprocess.CalledProcessError:
        return "Update failed"


def reload_environment():
    # reload hyprland safely
    subprocess.Popen(["hyprctl", "reload"])
