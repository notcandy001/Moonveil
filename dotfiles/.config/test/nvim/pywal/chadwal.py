#!/usr/bin/env python3

import hashlib
import os
import shutil
import subprocess
import sys
import time
import errno
from pathlib import Path

from watchdog.events import FileSystemEventHandler
from watchdog.observers import Observer

# Constants
SCRIPT_DIR = Path(__file__).parent.resolve()
HOME_DIR = Path.home()
TEMPLATE_SRC = {"dark": SCRIPT_DIR / "dark.lua", "light": SCRIPT_DIR / "light.lua"}
TEMPLATE_DST = {
    "dark": HOME_DIR / ".config/wal/templates/base46-dark.lua",
    "light": HOME_DIR / ".config/wal/templates/base46-light.lua",
}
CACHE_SRC = {
    "dark": HOME_DIR / ".cache/wal/base46-dark.lua",
    "light": HOME_DIR / ".cache/wal/base46-light.lua",
}
CACHE_DST = HOME_DIR / ".local/share/nvim/lazy/base46/lua/base46/themes/chadwal.lua"
FALLBACK_THEME = (
    HOME_DIR / ".local/share/nvim/lazy/base46/lua/base46/themes/gruvchad.lua"
)
LOCK_FILE = Path("/tmp/wal_nvim_lock")
COLORS_FILE = HOME_DIR / ".cache/wal/colors"

# State tracking
last_processed_hash = None
processing = False


def get_file_hash(filepath):
    """Calculate SHA256 hash of a file."""
    try:
        with open(filepath, "rb") as f:
            return hashlib.sha256(f.read()).hexdigest()
    except (FileNotFoundError, PermissionError):
        return None


def is_dark(hex_color):
    """Determine if the color is dark based on luminance."""
    hex_color = hex_color.lstrip("#")
    try:
        r, g, b = (int(hex_color[i : i + 2], 16) for i in (0, 2, 4))
        brightness = (r * 299 + g * 587 + b * 114) / 1000
        return brightness < 128
    except (ValueError, IndexError):
        print(f"Warning: Invalid color format '{hex_color}', defaulting to dark theme")
        return True


def get_hex_from_colors_file():
    """Read the first color from the colors file."""
    try:
        with open(COLORS_FILE, "r") as file:
            color = file.readline().strip()
            if not color:
                raise ValueError("Colors file is empty")
            return color
    except FileNotFoundError:
        sys.exit(f"Error: Colors file not found: {COLORS_FILE}")
    except ValueError as e:
        sys.exit(f"Error reading colors file: {e}")


def acquire_lock():
    """Create a lock file to prevent multiple instances. Without recursion."""
    retries = 3
    while retries > 0:
        try:
            lock_fd = os.open(LOCK_FILE, os.O_CREAT | os.O_EXCL | os.O_WRONLY)
            os.write(lock_fd, str(os.getpid()).encode())
            os.close(lock_fd)
            return
        except OSError as e:
            if e.errno != errno.EEXIST:
                raise
        try:
            with open(LOCK_FILE, "r") as f:
                content = f.read().strip()
                if not content:
                     raise ValueError("Empty lock file")
                pid = int(content)

            if os.path.exists(f"/proc/{pid}"):
                sys.exit(0)
        except (FileNotFoundError, ValueError):
            pass
        try:
            LOCK_FILE.unlink()
        except FileNotFoundError:
            pass

        retries -= 1
        time.sleep(0.1) 
    sys.exit("Error: Could not acquire lock after multiple retries.")


def release_lock():
    """Remove the lock file."""
    try:
        LOCK_FILE.unlink(missing_ok=True)
    except Exception as e:
        print(f"Warning: Could not remove lock file: {e}")


def copy_file(src, dst, skip_if_exists=False):
    """Copy a file from src to dst, optionally skipping if dst exists."""
    src = Path(src)
    dst = Path(dst)

    if skip_if_exists and dst.exists():
        print(f"File already exists at {dst}, skipping copy.")
        return True

    if not src.exists():
        print(f"Warning: Source file not found: {src}")
        return False

    try:
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dst)  # copy2 preserves metadata
        print(f"File copied from {src} to {dst}.")
        return True
    except Exception as e:
        print(f"Error copying file from {src} to {dst}: {e}")
        return False


def wait_for_file_stability(filepath, timeout=2.0, check_interval=0.1):
    """Wait until file stops being modified."""
    filepath = Path(filepath)
    if not filepath.exists():
        return False

    last_hash = get_file_hash(filepath)
    elapsed = 0

    while elapsed < timeout:
        time.sleep(check_interval)
        elapsed += check_interval
        current_hash = get_file_hash(filepath)

        if current_hash == last_hash:
            return True
        last_hash = current_hash

    return True  # Proceed anyway after timeout


def on_file_modified():
    """Handle file modifications based on current color scheme."""
    global last_processed_hash, processing

    # Prevent concurrent processing
    if processing:
        print("Already processing an update, skipping...")
        return

    processing = True
    try:
        # Wait for the file to stabilize
        time.sleep(0.2)  # Initial delay

        is_dark_theme = is_dark(get_hex_from_colors_file())
        mode = "dark" if is_dark_theme else "light"

        print(f"Detected {mode} theme")

        # Wait for the cache file to be fully written
        wait_for_file_stability(CACHE_SRC[mode])

        # Check if we've already processed this exact file
        current_hash = get_file_hash(CACHE_SRC[mode])
        if current_hash == last_processed_hash:
            print("No changes detected, skipping update")
            return

        # Copy fallback theme if needed (only once)
        copy_file(FALLBACK_THEME, CACHE_SRC[mode], skip_if_exists=True)

        # Copy template
        if not copy_file(TEMPLATE_SRC[mode], TEMPLATE_DST[mode]):
            print(f"Warning: Failed to copy template for {mode} mode")

        # Wait a bit to ensure pywal has finished processing
        time.sleep(0.3)
        wait_for_file_stability(CACHE_SRC[mode])

        # Copy to final destination
        if copy_file(CACHE_SRC[mode], CACHE_DST):
            last_processed_hash = get_file_hash(CACHE_DST)
            print("Theme update completed successfully")

            # Signal running nvim instances
            result = subprocess.run(
                ["pkill", "-SIGUSR1", "nvim"], capture_output=True, timeout=1
            )
            if result.returncode == 0:
                print("Signaled nvim instances to reload")
        else:
            print("Warning: Failed to copy theme to final destination")

    except Exception as e:
        print(f"Error during file modification handling: {e}")
    finally:
        processing = False


class ThemeChangeHandler(FileSystemEventHandler):
    """Handler for file system events."""

    def __init__(self):
        self.last_event_time = 0
        self.debounce_seconds = 0.5

    def on_modified(self, event):
        """Handle file modification events with debouncing."""
        if event.is_directory:
            return

        # Check both dark and light cache files
        if event.src_path in [str(CACHE_SRC["dark"]), str(CACHE_SRC["light"])]:
            current_time = time.time()
            if current_time - self.last_event_time < self.debounce_seconds:
                return

            self.last_event_time = current_time
            print(f"\nDetected change in {event.src_path}")
            on_file_modified()


def is_nvim_running():
    """Check if any nvim instances are running."""
    try:
        result = subprocess.run(["pgrep", "-x", "nvim"], capture_output=True, timeout=1)
        return result.returncode == 0
    except subprocess.TimeoutExpired:
        return False


def monitor_files():
    """Monitor cache files for changes."""
    event_handler = ThemeChangeHandler()
    observer = Observer()

    # Monitor both cache directories
    for cache_file in CACHE_SRC.values():
        watch_dir = cache_file.parent
        if watch_dir.exists():
            observer.schedule(event_handler, str(watch_dir), recursive=False)
            print(f"Monitoring {watch_dir}")

    observer.start()
    print("Monitoring started. Press Ctrl+C to stop.")

    try:
        while True:
            time.sleep(5)
            if not is_nvim_running():
                print("\nNo running nvim instances found. Exiting.")
                break
    except KeyboardInterrupt:
        print("\nKeyboard interrupt received. Exiting.")
    finally:
        observer.stop()
        observer.join(timeout=2)


def main():
    """Main entry point."""
    # Acquire lock and start monitoring
    acquire_lock()

    # Perform initial setup
    print("Starting Pywal-Neovim theme synchronization...")
    on_file_modified()
    try:
        monitor_files()
    finally:
        release_lock()
        print("Cleanup completed. Goodbye!")


if __name__ == "__main__":
    main()
