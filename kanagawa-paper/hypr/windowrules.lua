-- hyprctl clients     - узнать class всех окон
-- hyprctl activewindow - узнать о текущем активном окне

-- ============================================================================
-- WORKSPACES
-- ============================================================================

-- Persistent workspaces 1..5.
for i = 1, 5 do
  hl.workspace_rule({
    workspace  = tostring(i),
    persistent = true,
  })
end

-- Стартовый воркспейс на каждом мониторе — ws 3.
hl.workspace_rule({
  workspace = "3",
  monitor   = "HDMI-A-1", -- десктоп
  default   = true,
})

hl.workspace_rule({
  workspace = "3",
  monitor   = "eDP-1",    -- ноут
  default   = true,
})

-- ============================================================================
-- GLOBAL RULES
-- ============================================================================

hl.window_rule({
  name           = "suppress-maximize-events",
  match          = { class = ".*" },
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

hl.window_rule({
  name  = "move-hyprland-run",
  match = { class = "hyprland-run" },
  move  = "20 monitor_h-120",
  float = true,
})

-- ============================================================================
-- PER-APPLICATION RULES
-- ============================================================================

---- blueman-manager ----
hl.window_rule({
  name   = "blueman-manager",
  match  = { class = "^(blueman-manager)$" },
  float  = true,
  size   = { "(monitor_w*0.6)", "(monitor_h*0.65)" },
  center = true,
})

---- cmus ----
hl.window_rule({
  name   = "cmus-floating",
  match  = { class = "^(cmus-floating)$" },
  float  = true,
  size   = { "(monitor_w*0.6)", "(monitor_h*0.65)" },
  center = true,
})

---- file-roller ----
hl.window_rule({
  name   = "file-roller",
  match  = { class = "^(org.gnome.FileRoller)$" },
  float  = true,
  size   = { "(monitor_w*0.6)", "(monitor_h*0.65)" },
  center = true,
})

---- firefox ----
-- PiP (Picture-in-Picture): малое окно, прижатое к правому нижнему углу,
-- видимое на всех воркспейсах.
hl.window_rule({
  name  = "firefox-pip",
  match = { class = "^(firefox)$", title = "Картинка в картинке|Picture-in-Picture" },
  float = true,
  size  = { "(monitor_w*0.3)", "(monitor_h*0.25)" },
  move  = { "monitor_w-window_w-25", "monitor_h-window_h-55" },
  pin   = true,
})

---- hyprpolkitagent ----
hl.window_rule({
  name   = "hyprpolkitagent",
  match  = { class = "^(hyprpolkitagent)$" },
  float  = true,
  size   = { "(monitor_w*0.4)", "(monitor_h*0.3)" },
  center = true,
})

---- impression ----
hl.window_rule({
  name   = "impression",
  match  = { class = "^(io.gitlab.adhami3310.Impression)$" },
  float  = true,
  size   = { "(monitor_w*0.6)", "(monitor_h*0.65)" },
  center = true,
})

---- kitty ----
-- floating-kitty: специальный класс для floating-терминалов из бара/скриптов.
-- Запуск: kitty --class floating-kitty ...
hl.window_rule({
  name   = "bar-floating-kitty",
  match  = { class = "^floating-kitty$" },
  float  = true,
  size   = { "(monitor_w*0.6)", "(monitor_h*0.65)" },
  center = true,
})

---- nautilus ----
-- Основное окно файлового менеджера.
hl.window_rule({
  name   = "nautilus",
  match  = { class = "^(org.gnome.Nautilus|nautilus)$" },
  float  = true,
  size   = { "(monitor_w*0.6)", "(monitor_h*0.65)" },
  center = true,
})

-- Sushi: preview-окно nautilus (вызывается пробелом на файле).
hl.window_rule({
  name   = "sushi-preview",
  match  = { class = "^(org.gnome.NautilusPreviewer)$" },
  float  = true,
  size   = { "(monitor_w*0.6)", "(monitor_h*0.65)" },
  center = true,
})

---- nm-connection-editor ----
hl.window_rule({
  name   = "nm-connection-editor",
  match  = { class = "^(nm-connection-editor)$" },
  float  = true,
  size   = { "(monitor_w*0.6)", "(monitor_h*0.65)" },
  center = true,
})

---- showtime ----
hl.window_rule({
  name  = "showtime",
  match = { class = "^(org.gnome.Showtime)$" },
  float = true,
  size  = { "(monitor_w*0.75)", "(monitor_h*0.8)" },
})

---- viewnior ----
hl.window_rule({
  name  = "viewnior",
  match = { class = "^(viewnior)$" },
  float = true,
  size  = { "(monitor_w*0.6)", "(monitor_h*0.65)" },
})
