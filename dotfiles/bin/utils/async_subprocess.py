"""
Utility functions for running subprocess operations asynchronously without blocking the UI.
This module provides helper functions to prevent UI freezes when executing external processes.
"""

import subprocess
from typing import Callable, List, Optional, Union
from gi.repository import GLib


def run_async_subprocess(
    command: Union[str, List[str]], 
    on_success: Optional[Callable] = None,
    on_error: Optional[Callable[[Exception], None]] = None,
    on_complete: Optional[Callable[[], None]] = None,
    thread_name: str = "async-subprocess"
) -> None:
    """
    Run a subprocess command asynchronously in a background thread.
    
    Args:
        command: Command to execute (string or list of strings)
        on_success: Callback function to call on successful completion
        on_error: Callback function to call when an error occurs (receives exception)
        on_complete: Callback function to call when operation completes (success or error)
        thread_name: Name for the background thread
    """
    def worker_thread(user_data):
        """Background thread worker function"""
        try:
            if isinstance(command, str):
                subprocess.run(command, shell=True, check=True)
            else:
                subprocess.run(command, check=True)
            
            # Schedule success callback on main thread
            if on_success:
                GLib.idle_add(lambda: (on_success(), False))
                
        except Exception as e:
            # Schedule error callback on main thread
            if on_error:
                GLib.idle_add(lambda: (on_error(e), False))
        finally:
            # Schedule completion callback on main thread
            if on_complete:
                GLib.idle_add(lambda: (on_complete(), False))
    
    GLib.Thread.new(thread_name, worker_thread, None)


def check_process_async(
    process_name: str,
    on_running: Optional[Callable[[], None]] = None,
    on_not_running: Optional[Callable[[], None]] = None,
    on_error: Optional[Callable[[Exception], None]] = None,
    thread_name: str = "check-process"
) -> None:
    """
    Check if a process is running asynchronously.
    
    Args:
        process_name: Name of the process to check (used with pgrep)
        on_running: Callback function to call if process is running
        on_not_running: Callback function to call if process is not running
        on_error: Callback function to call when an error occurs
        thread_name: Name for the background thread
    """
    def worker_thread(user_data):
        """Background thread worker function"""
        try:
            subprocess.check_output(["pgrep", process_name])
            # Process is running
            if on_running:
                GLib.idle_add(lambda: (on_running(), False))
        except subprocess.CalledProcessError:
            # Process is not running
            if on_not_running:
                GLib.idle_add(lambda: (on_not_running(), False))
        except Exception as e:
            # Other error occurred
            if on_error:
                GLib.idle_add(lambda: (on_error(e), False))
    
    GLib.Thread.new(thread_name, worker_thread, None)


def run_command_with_output_async(
    command: Union[str, List[str]],
    on_success: Optional[Callable[[bytes], None]] = None,
    on_error: Optional[Callable[[Exception], None]] = None,
    thread_name: str = "command-output"
) -> None:
    """
    Run a command and capture its output asynchronously.
    
    Args:
        command: Command to execute (string or list of strings)
        on_success: Callback function to call with command output on success
        on_error: Callback function to call when an error occurs
        thread_name: Name for the background thread
    """
    def worker_thread(user_data):
        """Background thread worker function"""
        try:
            if isinstance(command, str):
                result = subprocess.run(command, shell=True, capture_output=True, check=True)
            else:
                result = subprocess.run(command, capture_output=True, check=True)
            
            # Schedule success callback with output on main thread
            if on_success:
                GLib.idle_add(lambda: (on_success(result.stdout), False))
                
        except Exception as e:
            # Schedule error callback on main thread
            if on_error:
                GLib.idle_add(lambda: (on_error(e), False))
    
    GLib.Thread.new(thread_name, worker_thread, None)