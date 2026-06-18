#!/usr/bin/env fish

if not command -q gsettings
    logger -t kanagawa-theming "gsettings not found, skipping dconf apply"
    exit 1
end

set -l iface_schema "org.gnome.desktop.interface"

set -l settings \
    "color-scheme:prefer-dark" \
    "gtk-theme:adw-gtk3-dark" \
    "icon-theme:Papirus-Dark" \
    "cursor-theme:XCursor-Pro-Hyprcursor-Dark" \
    "cursor-size:24" \
    "font-name:Adwaita Sans 11" \
    "document-font-name:Adwaita Sans 12" \
    "monospace-font-name:JetBrainsMono Nerd Font 12"

set -l errors 0
for pair in $settings
    set -l key (string split -m1 ':' $pair)[1]
    set -l val (string split -m1 ':' $pair)[2]
    if not gsettings set $iface_schema $key "$val" 2>/dev/null
        logger -t kanagawa-theming "failed to set $key=$val"
        set errors (math $errors + 1)
    end
end

if test $errors -eq 0
    logger -t kanagawa-theming "applied $iface_schema settings successfully"
    exit 0
else
    logger -t kanagawa-theming "applied with $errors errors"
    exit 2
end
