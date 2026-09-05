use anyhow::Result;
use tracing::{info, warn};
use crate::wayland::WaylandRuntime;
use super::{config::Config, event::{Event, EventBus}};

pub struct Runtime {
    _config: Config,
    events: EventBus,
    wayland: Option<WaylandRuntime>,
    running: bool,
}

impl Runtime {
    pub fn new(config: Config) -> Self {
        Self { _config: config, events: EventBus::new(), wayland: None, running: false }
    }

    pub fn start(&mut self) -> Result<()> {
        self.running = true;
        info!("shell runtime started");
        Ok(())
    }

    pub fn attach_wayland(&mut self, wayland: WaylandRuntime) { self.wayland = Some(wayland); }

    pub fn run(&mut self) -> Result<()> {
        while self.running {
            if let Some(event) = self.events.try_recv() {
                match event {
                    Event::Shutdown => self.running = false,
                }
            }
            if let Some(wl) = self.wayland.as_mut() {
                if let Err(err) = wl.dispatch_pending() {
                    warn!(error = %err, "Wayland dispatch failed; stopping runtime");
                    self.running = false;
                }
            } else {
                self.running = false;
            }
            std::thread::sleep(std::time::Duration::from_millis(10));
        }
        info!("shell runtime stopped");
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn runtime_starts_stopped_state_then_starts() {
        let mut runtime = Runtime::new(Config::default());
        assert!(!runtime.running);
        runtime.start().unwrap();
        assert!(runtime.running);
    }
}
