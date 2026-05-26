---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout  = "us,ru",
        kb_variant = "",
        kb_model   = "",
        kb_options = "grp:alt_shift_toggle",
        kb_rules   = "",

        follow_mouse = 1,

        sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.

        touchpad = {
            natural_scroll = false,
        },
    },
})

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace"
})

---------------------
---- MY PROGRAMS ----
---------------------

local terminal    = "kitty"
local fileManager = "nautilus"
local browser     = "firefox"
local menu        = "rofi -show drun"
local ide         = "nvim"

---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER"

---- program ----
hl.bind(mainMod .. " + RETURN",     hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + N",          hl.dsp.exec_cmd(terminal .. " " .. ide))
hl.bind(mainMod .. " + E",          hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + B",          hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + R",          hl.dsp.exec_cmd(menu))
---- utils ----
hl.bind("Print",                    hl.dsp.exec_cmd("hyprshot --mode region --clipboard-only")) --PrintScrin в буфер
hl.bind("SHIFT + Print",            hl.dsp.exec_cmd("hyprshot --mode region --output-folder ~/Изображения")) --PrintScrin на диск
---- hotkase ----
hl.bind(mainMod .. " + Q",          hl.dsp.window.close())
hl.bind(mainMod .. " + V",          hl.dsp.window.float({ action = "toggle" })) --float
hl.bind(mainMod .. " + P",          hl.dsp.window.pseudo()) --переключение в маленький размер
hl.bind(mainMod .. " + SHIFT + J",  hl.dsp.layout("togglesplit")) --переключение сплита
hl.bind(mainMod .. " + SHIFT + R",  hl.dsp.exit())
---- focus ----
hl.bind(mainMod .. " + H",          hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + L",          hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + K",          hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + J",          hl.dsp.focus({ direction = "down" }))
---- workspace ----
for i = 1, 5 do
    local key = i % 10 -- 10 maps to key 0
    hl.dsp.exec_cmd("workspace " .. i)
    hl.bind(mainMod .. " + " .. key,             hl.dsp.focus({ workspace = i}))
    hl.bind(mainMod .. " + SHIFT + " .. key,     hl.dsp.window.move({ workspace = i }))
end
---- special workspace ----
hl.bind(mainMod .. " + S",          hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S",  hl.dsp.window.move({ workspace = "special:magic" }))
---- scroll workspace ----
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))
---- move/resize LMB/RMB ----
hl.bind(mainMod .. " + mouse:272",  hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273",  hl.dsp.window.resize(), { mouse = true })


