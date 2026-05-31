-----------------
---- MODULES ----
-----------------

require("keybindings")
require("env")
require("visual")
require("misc")
require("windowrules")
require("layerrules")

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
    scale    = "1.33",
})

-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function ()
  hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE")
  hl.exec_cmd("systemctl --user start hyprpolkitagent")
  hl.exec_cmd("awww-daemon")
  hl.exec_cmd("hypridle")
  hl.exec_cmd("qs -p ~/.config/hypr/kanagawa-paper/quickshell")
  hl.exec_cmd("hyprlock --config ~/.config/hypr/kanagawa-paper/hyprlock/hyprlockStart.conf")
end)

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
