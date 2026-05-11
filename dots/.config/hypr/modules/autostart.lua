--  ┏┓┳┳┏┳┓┏┓┏┓┏┳┓┏┓┳┓┏┳┓
--  ┣┫┃┃ ┃ ┃┃┗┓ ┃ ┣┫┣┫ ┃
--  ┛┗┗┛ ┻ ┗┛┗┛ ┻ ┛┗┛┗ ┻

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

hl.on("hyprland.start", function()
    hl.exec_cmd("awww-daemon &")
    hl.exec_cmd("swaync")
    hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &")
    hl.exec_cmd("quickshell --config ~.config/quickshell/Moonsshell")
    hl.exec_cmd("~/.local/bin/moonveil-control-center")
end)
