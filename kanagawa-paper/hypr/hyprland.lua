-----------------
---- MODULES ----
-----------------

require("keybindings")
require("env")
require("visual")
require("misc")
require("windowrules")

------------------
---- MONITORS ----
------------------

--monitor.Deskstop
--hl.monitor({
--   output   = "HDMI-A-1",
--    mode     = "1920x1080@144",
--    position = "auto",
--    scale    = "1.0",
--})

--monitor.Laptop
hl.monitor({
    output   = "eDP-1",
    mode     = "2160x1440@60",
    position = "auto",
    scale    = "1.0",
})

---------------------
---- MY PROGRAMS ----
---------------------

local terminal    = "kitty"
local fileManager = "nautilus"
local browser     = "firefox"
local menu        = "rofi -show drun"

-------------------
---- AUTOSTART ----
-------------------

-- hl.on("hyprland.start", function ()
--   hl.exec_cmd(terminal)
--   hl.exec_cmd("nm-applet")
--   hl.exec_cmd("waybar & hyprpaper & firefox")
-- end)

---------------
---- LAYOT ----
---------------

hl.config({
    general = {
    layout = "dwindle"
    },

    dwindle = {
        preserve_split = true, -- You probably want this
    },
})

hl.config({
    master = {
        new_status = "master",
    },
})

hl.config({
    scrolling = {
        fullscreen_on_one_column = true,
    },
})
