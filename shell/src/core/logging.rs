use anyhow::{Context, Result};
use tracing_subscriber::{EnvFilter, layer::SubscriberExt, util::SubscriberInitExt};

pub fn init(configured_level: &str) -> Result<()> {
    let filter = match std::env::var_os("RUST_LOG") {
        Some(_) => EnvFilter::try_from_default_env().context("parsing RUST_LOG")?,
        None => EnvFilter::try_new(format!("adaptive_shell={configured_level}"))
            .with_context(|| format!("invalid configured log level: {configured_level}"))?,
    };

    tracing_subscriber::registry()
        .with(filter)
        .with(tracing_subscriber::fmt::layer())
        .try_init()?;
    Ok(())
}
