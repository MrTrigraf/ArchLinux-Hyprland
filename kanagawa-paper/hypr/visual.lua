-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
    general = {
        gaps_in  = 3,
        gaps_out = 4, --{10, 20, 10, 20} top,right,bottom,left

        border_size = 2,

        col = {
            active_border   = { colors = {"rgba(96ada7ff)", "rgba(b4a7b5ee)", "rgba(c4b28acc)"}, angle = 45 },
            inactive_border = "rgba(36366466)",
        },


        resize_on_border = false,

        allow_tearing = false,
    },

    decoration = {
        rounding       = 8,
        rounding_power = 10,

        active_opacity   = 1.0,
        inactive_opacity = 0.92,

        shadow = {
            enabled      = true,
            range        = 15,
            render_power = 3,
            color        = 0xee0a0a10,
        },

        blur = {
            enabled   = true,
            size      = 4,
            passes    = 1,
            vibrancy  = 0.4696,
        },
    },

    animations = {
        enabled = true,
    },
})

hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}    } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}       } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1}    } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })

hl.curve("easy",           { type = "spring", mass = 1,   stiffness = 71.2633, dampening = 15.8273644 })
hl.curve("snappySpring",   { type = "spring", mass = 0.8, stiffness = 250,     dampening = 22 })

hl.animation({ leaf = "global",        enabled = true,  speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true,  speed = 5.39, bezier = "easeOutQuint" })

hl.animation({ leaf = "windows",       enabled = true,  speed = 4.79, spring = "easy" })
hl.animation({ leaf = "windowsIn",     enabled = true,  speed = 4.1,  spring = "easy",         style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true,  speed = 1.49, bezier = "linear",       style = "popin 87%" })

-- Перетаскивание/swap окон — из авторского, плавное движение
hl.animation({ leaf = "windowsMove",   enabled = true,  speed = 6,    bezier = "easeOutQuint", style = "slidefade 15%" })

hl.animation({ leaf = "fadeIn",        enabled = true,  speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true,  speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true,  speed = 3.03, bezier = "quick" })

hl.animation({ leaf = "layers",        enabled = true,  speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true,  speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true,  speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true,  speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true,  speed = 1.39, bezier = "almostLinear" })

hl.animation({ leaf = "workspaces",    enabled = true,  speed = 5,    bezier = "easeOutQuint", style = "slidefade 15%" })
hl.animation({ leaf = "workspacesIn",  enabled = true,  speed = 5,    bezier = "easeOutQuint", style = "slidefade 15%" })
hl.animation({ leaf = "workspacesOut", enabled = true,  speed = 5,    bezier = "easeOutQuint", style = "slidefade 15%" })

hl.animation({ leaf = "zoomFactor",    enabled = true,  speed = 7,    bezier = "quick" })
