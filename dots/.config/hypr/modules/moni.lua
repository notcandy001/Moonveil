--  ┳┳┓┏┓┳┓┳┏┳┓┏┓┳┓┏┓
--  ┃┃┃┃┃┃┃┃ ┃ ┃┃┣┫┗┓
--  ┛ ┗┗┛┛┗┻ ┻ ┗┛┛┗┗┛

-- See https://wiki.hypr.land/Configuring/Basics/Monitors/

hl.monitor({
    output   = "eDP-1",
    mode     = "1366x768@60",
    position = "0x0",
    scale    = 1,
})

hl.monitor({
    output   = "DP-1",
    mode     = "1280x720@60",
    position = "1366x0",
    scale    = "auto",
})
