import json
import subprocess
import threading
from typing import Optional


class Signal:
    """Simple signal implementation for monitor focus service."""
    
    def __init__(self):
        self._callbacks = []
    
    def connect(self, callback):
        """Connect a callback to this signal."""
        self._callbacks.append(callback)
    
    def emit(self, *args, **kwargs):
        """Emit the signal to all connected callbacks."""
        for callback in self._callbacks:
            try:
                callback(*args, **kwargs)
            except Exception as e:
                print(f"Error in signal callback: {e}")


class MonitorFocusService:
    """
    Service to track monitor focus changes through Hyprland events.
    
    Listens to 'focusedmon' and 'workspace' events and emits signals
    when monitor focus changes.
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
        self._monitor_name_to_id = {}
        self._monitor_info = {}  # Store rich monitor information
        self._current_workspace = 1
        self._current_monitor_name = ""
        self._listening = False
        self._thread = None
        
        # Signals
        self.monitor_focused = Signal()
        self.workspace_changed = Signal()
        
        self._update_monitor_mapping()
        self.start_listening()
    
    def _update_monitor_mapping(self):
        """Update the monitor name to ID mapping with rich monitor information."""
        try:
            # Import here to avoid circular imports
            from utils.monitor_manager import get_monitor_manager
            manager = get_monitor_manager()
            monitors = manager.get_monitors()
            
            self._monitor_name_to_id = {}
            self._monitor_info = {}  # Store rich monitor information
            for monitor in monitors:
                monitor_name = monitor['name']
                monitor_id = monitor['id']
                self._monitor_name_to_id[monitor_name] = monitor_id
                self._monitor_info[monitor_id] = {
                    'name': monitor_name,
                    'width': monitor.get('width', 1920),
                    'height': monitor.get('height', 1080),
                    'x': monitor.get('x', 0),
                    'y': monitor.get('y', 0),
                    'scale': monitor.get('scale', 1.0),
                    'focused': monitor.get('focused', False)
                }
        except ImportError:
            # Fallback if monitor manager not available yet
            self._monitor_name_to_id = {}
            self._monitor_info = {}
    
    def start_listening(self):
        """Start listening to Hyprland events in a separate thread."""
        if self._listening:
            return
        
        self._listening = True
        self._thread = threading.Thread(target=self._listen_to_hyprland, daemon=True)
        self._thread.start()
    
    def stop_listening(self):
        """Stop listening to Hyprland events."""
        self._listening = False
        if self._thread and self._thread.is_alive():
            self._thread.join(timeout=1.0)
    
    def _listen_to_hyprland(self):
        """Listen to Hyprland events via socat."""
        try:
            process = subprocess.Popen(
                ["socat", "-U", "-", "UNIX-CONNECT:/tmp/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                bufsize=1
            )
            
            while self._listening and process.poll() is None:
                if process.stdout:
                    line = process.stdout.readline()
                    if line:
                        self._handle_hyprland_event(line.strip())
                    
        except (subprocess.SubprocessError, FileNotFoundError) as e:
            print(f"MonitorFocusService: Error listening to Hyprland: {e}")
        except Exception as e:
            print(f"MonitorFocusService: Unexpected error: {e}")
    
    def _handle_hyprland_event(self, event_line: str):
        """Parse and handle Hyprland event."""
        try:
            if '>>' not in event_line:
                return
            
            parts = event_line.split('>>')
            if len(parts) < 2:
                return
            
            event_type = parts[0]
            event_data = parts[1]
            
            if event_type == "focusedmon":
                self._handle_focused_monitor(event_data)
            elif event_type == "workspace":
                self._handle_workspace_change(event_data)
                
        except Exception as e:
            print(f"MonitorFocusService: Error handling event '{event_line}': {e}")
    
    def _handle_focused_monitor(self, data: str):
        """Handle focusedmon event: monitor_name,workspace_name"""
        try:
            parts = data.split(',')
            if len(parts) >= 2:
                monitor_name = parts[0]
                workspace_name = parts[1]
                
                # Update monitor mapping if needed
                if monitor_name not in self._monitor_name_to_id:
                    self._update_monitor_mapping()
                
                monitor_id = self._monitor_name_to_id.get(monitor_name, 0)
                
                # Extract workspace ID from name
                try:
                    workspace_id = int(workspace_name)
                except ValueError:
                    workspace_id = 1
                
                self._current_monitor_name = monitor_name
                self._current_workspace = workspace_id
                
                # Emit signal
                self.monitor_focused.emit(monitor_name, monitor_id, workspace_id)
                
        except Exception as e:
            print(f"MonitorFocusService: Error in _handle_focused_monitor: {e}")
    
    def _handle_workspace_change(self, data: str):
        """Handle workspace event: workspace_name"""
        try:
            workspace_name = data.strip()
            
            # Extract workspace ID
            try:
                workspace_id = int(workspace_name)
            except ValueError:
                workspace_id = 1
            
            self._current_workspace = workspace_id
            
            # Emit signal
            self.workspace_changed.emit(workspace_id, self._current_monitor_name)
            
        except Exception as e:
            print(f"MonitorFocusService: Error in _handle_workspace_change: {e}")
    
    def get_current_monitor_id(self) -> int:
        """Get current monitor ID."""
        return self._monitor_name_to_id.get(self._current_monitor_name, 0)
    
    def get_current_workspace(self) -> int:
        """Get current workspace ID."""
        return self._current_workspace
    
    def get_monitor_id_by_name(self, monitor_name: str) -> Optional[int]:
        """Get monitor ID by name."""
        return self._monitor_name_to_id.get(monitor_name)
    
    def get_monitor_info(self, monitor_id: int) -> Optional[dict]:
        """Get rich monitor information by ID."""
        return self._monitor_info.get(monitor_id)
    
    def get_current_monitor_info(self) -> Optional[dict]:
        """Get rich information for current monitor."""
        current_id = self.get_current_monitor_id()
        return self.get_monitor_info(current_id)
    
    def get_monitor_scale(self, monitor_id: int) -> float:
        """Get monitor scale factor by ID."""
        info = self.get_monitor_info(monitor_id)
        return info.get('scale', 1.0) if info else 1.0
    
    def get_current_monitor_scale(self) -> float:
        """Get current monitor scale factor."""
        return self.get_monitor_scale(self.get_current_monitor_id())


# Singleton accessor
_monitor_focus_service_instance = None

def get_monitor_focus_service() -> MonitorFocusService:
    """Get the global MonitorFocusService instance."""
    global _monitor_focus_service_instance
    if _monitor_focus_service_instance is None:
        _monitor_focus_service_instance = MonitorFocusService()
    return _monitor_focus_service_instance