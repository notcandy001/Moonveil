import subprocess
import urllib.parse

import gi
from fabric.widgets.button import Button
from fabric.widgets.label import Label
from gi.repository import GLib

gi.require_version("Gtk", "3.0")
import config.data as data
from . import icons as icons


class Weather(Button):
    def __init__(self, **kwargs) -> None:
        super().__init__(name="weather", orientation="h", spacing=8, **kwargs)
        self.label = Label(name="weather-label", markup=icons.loader)
        self.add(self.label)
        self.show_all()
        self.enabled = False  # Will be set by apply_component_props
        self.has_weather_data = False
        self.fetching = False  # Prevent concurrent fetches
        # Fetch weather every 10 minutes (600 seconds)
        GLib.timeout_add_seconds(600, self.fetch_weather)
        # Delay initial fetch to allow visibility config to be applied first (runs only once)
        GLib.timeout_add(100, self._initial_fetch)

    def set_visible(self, visible):
        """Override to track external visibility setting"""
        self.enabled = visible

        # If being disabled, always hide
        if not visible:
            super().set_visible(False)
            return

        # If being enabled, only show if we have weather data
        if hasattr(self, "has_weather_data") and self.has_weather_data:
            super().set_visible(True)
        # If no weather data yet, remain hidden until fetch completes

    def _initial_fetch(self):
        """Initial fetch that runs only once"""
        self.fetch_weather()
        return False  # Don't repeat this timeout

    def fetch_weather(self):
        # Prevent concurrent fetches
        if self.fetching:
            return True

        self.fetching = True
        GLib.Thread.new("weather-fetch", self._fetch_weather_thread, None)
        return True

    def _fetch_weather_thread(self, user_data):
        url = (
            "https://wttr.in/?format=%c+%t"
            if not data.VERTICAL
            else "https://wttr.in/?format=%c"
        )

        tooltip_url = "https://wttr.in/?format=%l:+%C,+%t+(%f),+Humidity:+%h,+Wind:+%w"

        try:
            # Use curl to fetch weather data
            result = subprocess.run(
                ["curl", "-sf", "--max-time", "5", url],
                capture_output=True,
                text=True,
                timeout=6,
            )

            if result.returncode == 0 and result.stdout:
                weather_data = result.stdout.strip()
                if "Unknown" in weather_data:
                    self.has_weather_data = False
                    GLib.idle_add(self.set_visible, False)
                else:
                    self.has_weather_data = True

                    # Fetch tooltip data
                    tooltip_result = subprocess.run(
                        ["curl", "-sf", "--max-time", "5", tooltip_url],
                        capture_output=True,
                        text=True,
                        timeout=6,
                    )
                    if tooltip_result.returncode == 0 and tooltip_result.stdout:
                        tooltip_text = tooltip_result.stdout.strip()
                        GLib.idle_add(self.set_tooltip_text, tooltip_text)

                    GLib.idle_add(self.set_visible, self.enabled)
                    GLib.idle_add(self.label.set_label, weather_data.replace(" ", ""))
            else:
                self.has_weather_data = False
                GLib.idle_add(self.label.set_markup, f"{icons.cloud_off} Unavailable")
                GLib.idle_add(self.set_visible, False)
        except Exception as e:
            self.has_weather_data = False
            print(f"Error fetching weather: {e}")
            GLib.idle_add(self.label.set_markup, f"{icons.cloud_off} Error")
            GLib.idle_add(self.set_visible, False)
        finally:
            # Always reset fetching flag when done
            self.fetching = False
