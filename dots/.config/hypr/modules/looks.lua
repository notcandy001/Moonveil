--  ┳┓┏┓┏┓┏┓┳┓┏┓┏┳┓┳┏┓┳┓┏┓
--  ┃┃┣ ┃ ┃┃┣┫┣┫ ┃ ┃┃┃┃┃┗┓
--  ┻┛┗┛┗┛┗┛┛┗┛┗ ┻ ┻┗┛┛┗┗┛

-- Sourcing matugen colors (already required from hyprland.lua)
-- See https://wiki.hypr.land/Configuring/Basics/Variables/

hl.config({
    general = {
        gaps_in  = 3,
        gaps_out = 10,

        border_size = 2,

        col = {
            active_border   = primary,
            inactive_border = surface,
        },

        resize_on_border = false,
        allow_tearing    = false,
        layout           = "dwindle",
    },

    decoration = {
        rounding       = 18,
        rounding_power = 2.4,

        -- active_opacity   = 1.0,
        -- inactive_opacity = 0.9,

        blur = {
            enabled                   = true,
            xray                      = true,
            special                   = false,
            new_optimizations         = true,
            size                      = 6,
            passes                    = 2,
            brightness                = 1,
            noise                     = 0.05,
            contrast                  = 0.89,
            vibrancy                  = 0.5,
            vibrancy_darkness         = 0.5,
            popups                    = false,
            popups_ignorealpha        = 0.6,
            input_methods             = true,
            input_methods_ignorealpha = 0.8,
        },

      shadow = {
      enabled      = true,
      range        = 50,
      offset       = "0 4",
      render_power = 10,
      color        = "rgba(00000027)",
},

        dim_inactive = true,
        dim_strength = 0.05,
        dim_special  = 0.07,
    },
})

-- Dwindle layout
-- See https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/
hl.config({
    dwindle = {
        preserve_split = true,
    },
})
