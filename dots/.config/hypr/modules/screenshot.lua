--  ┏┓┏┓┳┓┏┓┏┓┳┓┏┓┳┓┏┓┏┳┓
--  ┗┓┃ ┣┫┣ ┣ ┃┃┗┓┣┫┃┃ ┃
--  ┗┛┗┛┛┗┗┛┗┛┛┗┗┛┛┗┗┛ ┻

-- Fullscreen screenshot saved to ~/Pictures
hl.bind("Print",       hl.dsp.exec_cmd("grim ~/Pictures/screenshot_$(date +%s).png"))

-- Select area and save
hl.bind("CTRL + Print", hl.dsp.exec_cmd("grim -g \"$(slurp)\" ~/Pictures/screenshot_$(date +%s).png"))

-- Select area to clipboard
hl.bind("ALT + Print",  hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | wl-copy"))
