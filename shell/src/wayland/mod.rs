use anyhow::{Context, Result};
use wayland_client::{Connection, EventQueue};

pub struct WaylandRuntime {
    connection: Connection,
    event_queue: EventQueue<()>,
}

impl WaylandRuntime {
    pub fn connect() -> Result<Self> {
        let connection =
            Connection::connect_to_env().context("connecting to Wayland compositor")?;
        let event_queue = connection.new_event_queue();
        Ok(Self {
            connection,
            event_queue,
        })
    }

    pub fn dispatch_pending(&mut self) -> Result<()> {
        self.event_queue
            .dispatch_pending(&mut ())
            .context("dispatching Wayland events")?;
        self.connection
            .flush()
            .context("flushing Wayland requests")?;
        Ok(())
    }
}
