-----------------------
---- VELORA ARCH ----
-----------------------
-- Точка входа Hyprland (Lua). Подключается из ~/.config/hypr/hyprland.lua.
-- Модули ищутся в этой папке, а не в ~/.config/hypr: dofile не меняет configDir.

package.path = os.getenv("HOME") .. "/.config/hypr/velora/hypr/?.lua;" .. package.path

require("keybindings")
require("env")
require("visual")
require("misc")
require("windowrules")
require("layerrules")

------------------
---- MONITORS ----
------------------

-- Запасное правило: output = "" совпадает с любым монитором без своего правила.
-- Правила с именем имеют приоритет, поэтому порядок строк не важен.
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})

-- monitors.lua генерирует менеджер мониторов (не в git). Нет файла — работает запасное правило.
pcall(require, "monitors")

-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function ()
  hl.exec_cmd("~/.config/hypr/velora/appearance/dconf/apply.fish")
  hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE")
  hl.exec_cmd("systemctl --user start hyprpolkitagent")
  hl.exec_cmd("awww-daemon")
  hl.exec_cmd("udiskie --no-automount --no-tray --notify --config ~/.config/hypr/velora/udiskie/config.yml")
  hl.exec_cmd("hypridle -c ~/.config/hypr/velora/hypridle/hypridle.conf")
  hl.exec_cmd("qs -p ~/.config/hypr/kanagawa-paper/quickshell")
  hl.exec_cmd("hyprlock --config ~/.config/hypr/velora/hyprlock/hyprlockStart.conf")
  hl.exec_cmd("firefox", { workspace = "1 silent" })
end)

---------------
---- LAYOUT ----
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

--------------------------------
---- FOCUS-ON-OPEN HANDLERS ----
--------------------------------
local focusOnOpen = {
  -- "viewnior",
  -- "showtime",        -- если понадобится
  -- "file-roller",     -- если понадобится
  -- "impression",      -- если понадобится
}

hl.on("window.open", function(w)
  for _, cls in ipairs(focusOnOpen) do
    if w.class == cls then
      hl.dispatch(hl.dsp.focus({ window = w }))
      return
    end
  end
end)
