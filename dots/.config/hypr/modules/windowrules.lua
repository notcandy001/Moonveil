--  ┓ ┏┳┳┓┳┓┏┓┓ ┏  ┳┓┳┳ ┏┓┏┓
--  ┃┃┃┃┃┃┃┃┃┃┃┃┃  ┣┫┃┃┃ ┣ ┗┓
--  ┗┻┛┻┛┗┻┛┗┛┗┻┛  ┛┗┗┛┗┛┗┛┗┛

---- WINDOW RULES 


-- Fix XWayland dragging / focus bugs
hl.window_rule({
    name     = "fix-xwayland-no-focus",
    match    = { xwayland = true },
    no_focus = true,
})
hl.window_rule({
    name  = "fix-xwayland-float",
    match = { xwayland = true },
    float = true,
})

-- hyprland-run window
hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "^(hyprland-run)$" },
    float = true,
    move  = "20% 80%",
})

-- Remove right-click menu blur in Chromium browsers
hl.window_rule({
    name    = "no-blur-chromium",
    match   = { class = "^(brave|chromium|google-chrome|chrome)$" },
    no_blur = true,
})

-- File pickers floating & centered
hl.window_rule({
    name   = "float-file-pickers",
    match  = { title = "^(Open File|Open Folder|Open|Save|Save As|Export|Import|Choose File|Rename|script-fu|kdenlive|brave)$" },
    float  = true,
    center = true,
})

-- xdg-desktop-portal dialogs
hl.window_rule({
    name   = "float-xdg-portal",
    match  = { class = "^(xdg-desktop-portal-gtk|xdg-desktop-portal-hyprland)$" },
    float  = true,
    center = true,
})
hl.window_rule({
    name        = "no-border-xdg-portal",
    match       = { class = "^(xdg-desktop-portal-gtk)$" },
    border_size = 0,
})

-- Disable borders for swaync
hl.window_rule({
    name        = "no-border-swaync",
    match       = { class = "^(swaync)$" },
    border_size = 0,
})

-- Moonveil Control Center
hl.window_rule({
    name         = "moonveil-control-center",
    match        = { title = "^(Moonveil Control Center)$" },
    float        = true,
    center       = true,
    size         = "900 480",
    no_anim      = true,
    border_size  = 0,
    stay_focused = true,
})

-------------------------------------------------------------------------------
---- LAYER RULES --------------------------------------------------------------
-------------------------------------------------------------------------------

-- Waybar
hl.layer_rule({ name = "waybar-blur",    match = { namespace = "waybar" }, blur         = true })
hl.layer_rule({ name = "waybar-alpha",   match = { namespace = "waybar" }, ignore_alpha = 0.5  })
hl.layer_rule({ name = "waybar-no-anim", match = { namespace = "waybar" }, no_anim      = true })

-- SwayNC
hl.layer_rule({ name = "swaync-cc-blur",     match = { namespace = "swaync-control-center" },      blur         = true })
hl.layer_rule({ name = "swaync-notif-blur",  match = { namespace = "swaync-notification-window" }, blur         = true })
hl.layer_rule({ name = "swaync-cc-alpha",    match = { namespace = "swaync-control-center" },      ignore_alpha = 0.5  })
hl.layer_rule({ name = "swaync-notif-alpha", match = { namespace = "swaync-notification-window" }, ignore_alpha = 0.5  })

-- Logout dialog
hl.layer_rule({ name = "logout-anim", match = { namespace = "logout_dialog" }, animation = "fade" })
hl.layer_rule({ name = "logout-blur", match = { namespace = "logout_dialog" }, blur      = true   })

-- Rofi
hl.layer_rule({ name = "rofi-anim", match = { namespace = "rofi" }, animation = "popin 90%" })
