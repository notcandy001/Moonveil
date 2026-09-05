mod core;
mod wayland;

use anyhow::Result;
use tracing::info;

fn main() -> Result<()> {
    let config = core::config::Config::load_default()?;
    core::logging::init(&config.runtime.log_level)?;
    info!("starting adaptive-shell");

    let mut runtime = core::lifecycle::Runtime::new(config);
    runtime.start()?;

    let wayland = wayland::WaylandRuntime::connect()?;
    runtime.attach_wayland(wayland);
    runtime.run()
}
