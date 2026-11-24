package.path = package.path .. ";" .. os.getenv("HOME") .. "/.config/hypr/velora/hypr/?.lua"
dofile(os.getenv("HOME") .. "/.config/hypr/velora/hypr/hyprland.lua")
