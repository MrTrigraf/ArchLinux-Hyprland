#!/usr/bin/env fish

# ════════════════════════════════════════════════════════════════════
#  game-mode.fish — вкл/выкл игрового режима Hyprland.
#
#  Гасит тяжёлые для GPU эффекты на время игры: анимации, блюр, тени,
#  прозрачность окон. Вызывается хуками gamemode (start → on, end → off).
#
#  on  — гасим эффекты ОДНИМ eval-вызовом (в памяти, hyprland.lua не
#        трогаем). Один вызов, а не несколько подряд — синхронные
#        hyprctl-вызовы дают стуттер (см. man hyprctl, раздел --batch).
#  off — hyprctl reload: Hyprland перечитывает hyprland.lua и возвращает
#        все значения как в конфиге (включая inactive_opacity = 0.92).
#        Не нужно вручную помнить исходные значения.
# ════════════════════════════════════════════════════════════════════

switch $argv[1]
    case on
        hyprctl eval 'hl.config({ animations = { enabled = false }, decoration = { blur = { enabled = false }, shadow = { enabled = false }, active_opacity = 1.0, inactive_opacity = 1.0 } })'
    case off
        hyprctl reload
    case '*'
        echo "usage: game-mode.fish [on|off]"
        exit 1
end
