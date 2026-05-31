--hyprctl clients - узнать class окон
--hyprctl activewindow - узнать о текущем активном окне
--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

---- create workspace ----
for i = 1, 5 do
  hl.workspace_rule({
    workspace  = tostring(i),
    -- monitor = "HDMI-A-1"
    persistent = true,
    default    = (i == 1), --стартовый монитор
  })
end

---- window rules ----
hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

-- Hyprland-run windowrule
hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },

    move  = "20 monitor_h-120",
    float = true,
})

