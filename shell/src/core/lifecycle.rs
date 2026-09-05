use anyhow::Result;
use tracing::{info, warn};

use crate::wayland::WaylandRuntime;

use super::{
    config::Config,
    event::{Event, EventBus},
};

pub struct Runtime {
    config: Config,
    events: EventBus,
    wayland: Option<WaylandRuntime>,
    running: bool,
}

impl Runtime {
    pub fn new(config: Config) -> Self {
        Self {
            config,
            events: EventBus::new(),
            wayland: None,
            running: false,
        }
    }

    pub fn start(&mut self) -> Result<()> {
        self.running = true;
        info!(log_level = %self.config.runtime.log_level, "shell runtime started");
        Ok(())
    }

    pub fn attach_wayland(&mut self, wayland: WaylandRuntime) {
        self.wayland = Some(wayland);
    }

    pub fn request_shutdown(&self) -> Result<()> {
        self.events
            .sender()
            .send(Event::Shutdown)
            .map_err(|err| anyhow::anyhow!("sending shutdown event: {err}"))
    }

    fn process_events(&mut self) {
        while let Some(event) = self.events.try_recv() {
            match event {
                Event::Shutdown => self.running = false,
            }
        }
    }

    pub fn run(&mut self) -> Result<()> {
        while self.running {
            self.process_events();
            if !self.running {
                break;
            }

            if let Some(wl) = self.wayland.as_mut() {
                if let Err(err) = wl.dispatch_pending() {
                    warn!(error = %err, "Wayland dispatch failed; stopping runtime");
                    self.request_shutdown()?;
                }
            } else {
                self.request_shutdown()?;
            }

            self.process_events();

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

    #[test]
    fn shutdown_event_stops_running_runtime() {
        let mut runtime = Runtime::new(Config::default());
        runtime.start().unwrap();
        runtime.request_shutdown().unwrap();
        runtime.process_events();
        assert!(!runtime.running);
    }
}
