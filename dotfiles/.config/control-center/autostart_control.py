import os

AUTOSTART_FILE = os.path.expanduser(
    "~/.config/hypr/modules/autostart.conf"
)

ENTRY = "exec-once = moonveil-control-center --auto"

def _read():
    if not os.path.exists(AUTOSTART_FILE):
        return []
    with open(AUTOSTART_FILE, "r") as f:
        return f.readlines()

def _write(lines):
    with open(AUTOSTART_FILE, "w") as f:
        f.writelines(lines)

def is_autostart_enabled():
    for line in _read():
        if ENTRY in line and not line.strip().startswith("#"):
            return True
    return False

def set_autostart(enable: bool):
    lines = _read()
    new = []
    found = False

    for line in lines:
        if ENTRY in line:
            found = True
            new.append(f"{ENTRY}\n" if enable else f"# {ENTRY}\n")
        else:
            new.append(line)

    if not found and enable:
        new.append(f"{ENTRY}\n")

    _write(new)
