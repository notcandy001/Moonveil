mod core;
mod wayland;

use anyhow::Result;
use tracing::info;

fn main() -> Result<()> {
    core::logging::init()?;
    info!("starting adaptive-shell");

    let config = core::config::Config::load_default()?;
    let mut runtime = core::lifecycle::Runtime::new(config);
    runtime.start()?;

    let wayland = wayland::WaylandRuntime::connect()?;
    runtime.attach_wayland(wayland);
    runtime.run()
}
