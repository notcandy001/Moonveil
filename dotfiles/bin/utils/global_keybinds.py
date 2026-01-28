from typing import Optional


class GlobalKeybindHandler:
    """
    Handler for global keybinds that redirects commands to the focused monitor.
    
    This class provides methods to open notch modules, access widgets, and
    perform other actions on the currently focused monitor.
    """
    
    _instance = None
    
    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance
    
    def __init__(self):
        if hasattr(self, '_initialized'):
            return
        
        self._initialized = True
        self._monitor_manager = None
    
    def set_monitor_manager(self, monitor_manager):
        """Set the monitor manager reference."""
        self._monitor_manager = monitor_manager
    
    def open_notch_module(self, module_name: str) -> bool:
        """
        Open a notch module on the currently focused monitor.
        
        Args:
            module_name: Name of the module to open
            
        Returns:
            True if successful, False otherwise
        """
        if not self._monitor_manager:
            return False
        
        focused_monitor_id = self._monitor_manager.get_focused_monitor_id()
        
        # Close any open notches on other monitors
        self._monitor_manager.close_all_notches_except(focused_monitor_id)
        
        # Get notch instance for focused monitor
        notch = self._monitor_manager.get_focused_instance('notch')
        if notch and hasattr(notch, 'open_module'):
            try:
                notch.open_module(module_name)
                self._monitor_manager.set_notch_state(focused_monitor_id, True, module_name)
                return True
            except Exception as e:
                print(f"GlobalKeybindHandler: Error opening module '{module_name}': {e}")
        
        return False
    
    def toggle_notch(self) -> bool:
        """
        Toggle notch on the currently focused monitor.
        
        Returns:
            True if successful, False otherwise
        """
        if not self._monitor_manager:
            return False
        
        focused_monitor_id = self._monitor_manager.get_focused_monitor_id()
        is_open = self._monitor_manager.is_notch_open(focused_monitor_id)
        
        notch = self._monitor_manager.get_focused_instance('notch')
        if notch:
            try:
                if is_open:
                    if hasattr(notch, 'close'):
                        notch.close()
                    self._monitor_manager.set_notch_state(focused_monitor_id, False)
                else:
                    if hasattr(notch, 'open'):
                        notch.open()
                    self._monitor_manager.set_notch_state(focused_monitor_id, True)
                return True
            except Exception as e:
                print(f"GlobalKeybindHandler: Error toggling notch: {e}")
        
        return False
    
    def get_dashboard_wallpapers_widget(self):
        """
        Get the dashboard wallpapers widget from the focused monitor.
        
        Returns:
            Wallpapers widget instance or None
        """
        if not self._monitor_manager:
            return None
        
        notch = self._monitor_manager.get_focused_instance('notch')
        if notch and hasattr(notch, 'dashboard'):
            dashboard = notch.dashboard
            if hasattr(dashboard, 'widgets') and hasattr(dashboard.widgets, 'wallpapers'):
                return dashboard.widgets.wallpapers
        
        return None
    
    def get_dashboard_widget(self, widget_name: str):
        """
        Get a specific dashboard widget from the focused monitor.
        
        Args:
            widget_name: Name of the widget to get
            
        Returns:
            Widget instance or None
        """
        if not self._monitor_manager:
            return None
        
        notch = self._monitor_manager.get_focused_instance('notch')
        if notch and hasattr(notch, 'dashboard'):
            dashboard = notch.dashboard
            if hasattr(dashboard, 'widgets'):
                return getattr(dashboard.widgets, widget_name, None)
        
        return None
    
    def open_launcher(self) -> bool:
        """Open launcher on focused monitor."""
        return self.open_notch_module('launcher')
    
    def open_overview(self) -> bool:
        """Open overview on focused monitor."""
        return self.open_notch_module('overview')
    
    def open_dashboard(self) -> bool:
        """Open dashboard on focused monitor."""
        return self.open_notch_module('dashboard')
    
    def open_power_menu(self) -> bool:
        """Open power menu on focused monitor."""
        return self.open_notch_module('power')
    
    def open_toolbox(self) -> bool:
        """Open toolbox on focused monitor."""
        return self.open_notch_module('tools')
    
    def open_emoji_picker(self) -> bool:
        """Open emoji picker on focused monitor."""
        return self.open_notch_module('emoji')
    
    def open_clipboard_history(self) -> bool:
        """Open clipboard history on focused monitor."""
        return self.open_notch_module('cliphist')
    
    def get_focused_monitor_info(self) -> Optional[dict]:
        """
        Get information about the currently focused monitor.
        
        Returns:
            Monitor info dict or None
        """
        if not self._monitor_manager:
            return None
        
        return self._monitor_manager.get_focused_monitor()
    
    def get_all_monitors_info(self) -> list:
        """
        Get information about all monitors.
        
        Returns:
            List of monitor info dicts
        """
        if not self._monitor_manager:
            return []
        
        return self._monitor_manager.get_monitors()
    
    def toggle_bar(self) -> bool:
        """
        Toggle bar visibility and force notch/dock to occlusion mode.
        
        Returns:
            True if successful, False otherwise
        """
        if not self._monitor_manager:
            return False

        monitors = self._monitor_manager.get_monitors()

        for monitor in monitors:
            bar = self._monitor_manager.get_instance(monitor['id'], 'bar')
            notch = self._monitor_manager.get_instance(monitor['id'], 'notch')
        
            if bar and notch:
                try:
                    current_visibility = bar.get_visible()
                    bar.set_visible(not current_visibility)
                    
                    if not current_visibility:
                        # Bar is being shown - restore from occlusion
                        notch.restore_from_occlusion()
                        # Also restore docks on all monitors
                        try:
                            from modules.dock import Dock
                            for dock_instance in Dock._instances:
                                if hasattr(dock_instance, 'restore_from_occlusion'):
                                    dock_instance.restore_from_occlusion()
                        except ImportError:
                            pass
                    else:
                        # Bar is being hidden - force occlusion
                        notch.force_occlusion()
                        # Also force occlusion on docks on all monitors
                        try:
                            from modules.dock import Dock
                            for dock_instance in Dock._instances:
                                if hasattr(dock_instance, 'force_occlusion'):
                                    dock_instance.force_occlusion()
                        except ImportError:
                            pass
                    
                except Exception as e:
                    print(f"GlobalKeybindHandler: Error toggling bar: {e}")
                    return False
        
        return True


# Singleton accessor
_global_keybind_handler_instance = None

def get_global_keybind_handler() -> GlobalKeybindHandler:
    """Get the global GlobalKeybindHandler instance."""
    global _global_keybind_handler_instance
    if _global_keybind_handler_instance is None:
        _global_keybind_handler_instance = GlobalKeybindHandler()
    return _global_keybind_handler_instance

def init_global_keybind_objects():
    """Initialize global keybind handler with monitor manager."""
    try:
        from utils.monitor_manager import get_monitor_manager
        
        handler = get_global_keybind_handler()
        manager = get_monitor_manager()
        handler.set_monitor_manager(manager)
        
        return handler
    except ImportError as e:
        print(f"Error initializing global keybind objects: {e}")
        return None