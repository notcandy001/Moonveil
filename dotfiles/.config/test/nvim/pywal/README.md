<h1 align="center">Base46: Pywal Edition</h1>

<p align="center"><i>Pywal and Matugen support for NvChad!</i></p>

> [!NOTE]
> Support for Pywal requires these Python libraries to be installed:
> - `pywal`
> - `watchdog`

## Installation
```bash
cd ~/.config/nvim
git clone https://github.com/NvChad/pywal
```
Add this at the end of your `init.lua` file:
```lua
os.execute("python ~/.config/nvim/pywal/chadwal.py &> /dev/null &")

local autocmd = vim.api.nvim_create_autocmd

autocmd("Signal", {
  pattern = "SIGUSR1",
  callback = function()
    require('nvchad.utils').reload()
  end
})
```
Now you need to generate your Pywal theme again using `wal -i <image>`. If not, `chadwal` will default to `gruvchad` colors.

### Matugen support
Add this your `~/.config/matugen/config.toml` file:
```toml
[templates.nvim]
input_path = '~/.config/nvim/pywal/matugen.lua'
output_path = '~/.cache/wal/base46-dark.lua'

[templates.nvimlight]
input_path = '~/.config/nvim/pywal/matugen.lua'
output_path = '~/.cache/wal/base46-light.lua'

[templates.pywal]
input_path = '~/.config/nvim/pywal/waltemplate'
output_path = '~/.cache/wal/colors'

[config.custom_colors.red]
color = "#FF0000"
blend = true

[config.custom_colors.green]
color = "#00FF00"
blend = true

[config.custom_colors.yellow]
color = "#FFFF00"
blend = true

[config.custom_colors.blue]
color = "#0000FF"
blend = true

[config.custom_colors.magenta]
color = "#FF00FF"
blend = true

[config.custom_colors.cyan]
color = "#00FFFF"
blend = true

[config.custom_colors.white]
color = "#FFFFFF"
blend = true
```

Just like with Pywal, you need to generate your theme again using `matugen image <image>`. If not, `chadwal` will default to `gruvchad` colors.

Select `chadwal` theme and enjoy!

## Demo
https://github.com/user-attachments/assets/933c97f2-4566-406c-8c04-e2e9f0f3f6da
