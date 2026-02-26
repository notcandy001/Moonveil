# bar_control.py
import subprocess

WAYBAR_PROC = "waybar"
MOONSHELL_PROC = "moonshell"
MOONSHELL_CMD = ["moonbar-run"]

def is_running(proc):
    return subprocess.call(
        ["pgrep", "-x", proc],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL
    ) == 0

def active_bar():
    if is_running(MOONSHELL_PROC):
        return "Moonshell"
    if is_running(WAYBAR_PROC):
        return "Waybar"
    return "None"

def stop_all():
    subprocess.call(["pkill", "-x", WAYBAR_PROC])
    subprocess.call(["pkill", "-x", MOONSHELL_PROC])

def start_waybar():
    stop_all()
    subprocess.Popen(["waybar"])

def start_moonshell():
    stop_all()
    subprocess.Popen(MOONSHELL_CMD)
