use anyhow::{Context, Result};
use serde::Deserialize;
use std::{fs, path::PathBuf};

#[derive(Debug, Clone, Default, Deserialize)]
pub struct Config {
    #[serde(default)]
    pub runtime: RuntimeConfig,
}

#[derive(Debug, Clone, Deserialize)]
pub struct RuntimeConfig {
    #[serde(default = "default_log_level")]
    pub log_level: String,
}

fn default_log_level() -> String {
    "info".into()
}

impl Default for RuntimeConfig {
    fn default() -> Self {
        Self {
            log_level: default_log_level(),
        }
    }
}

impl Config {
    pub fn load_default() -> Result<Self> {
        let Some(path) = config_path() else {
            return Ok(Self::default());
        };
        if !path.exists() {
            return Ok(Self::default());
        }
        let text = fs::read_to_string(&path)
            .with_context(|| format!("reading config {}", path.display()))?;
        toml::from_str(&text).with_context(|| format!("parsing config {}", path.display()))
    }
}

fn config_path() -> Option<PathBuf> {
    std::env::var_os("XDG_CONFIG_HOME")
        .map(PathBuf::from)
        .or_else(|| std::env::var_os("HOME").map(|h| PathBuf::from(h).join(".config")))
        .map(|base| base.join("adaptive-shell/config.toml"))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn default_config_uses_info_log_level() {
        assert_eq!(Config::default().runtime.log_level, "info");
    }

    #[test]
    fn parses_runtime_configuration() {
        let config: Config = toml::from_str(
            r#"
            [runtime]
            log_level = "debug"
            "#,
        )
        .unwrap();

        assert_eq!(config.runtime.log_level, "debug");
    }
}
