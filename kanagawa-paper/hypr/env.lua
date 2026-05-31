-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("CLUTTER_BACKEND", "wayland")

hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_QPA_PLATFORMTHEME", "qt5ct")

hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("MOZ_ENABLE_WAYLAND", "1")

---- Desktop ----
--hl.env("GBM_BACKEND", "nvidia-drm")
--hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
--hl.env("LIBVA_DRIVER_NAME", "nvidia")
--hl.env("NVD_BACKEND", "direct")


---- Laptop ----
hl.env("LIBVA_DRIVER_NAME", "iHD")
hl.env("VDPAU_DRIVER", "va_gl") --нужен пакет libvdpau-va-gl

---- awww ----
hl.env("AWWW_TRANSITION", "fade")
hl.env("AWWW_TRANSITION_DURATION", "3")
hl.env("AWWW_TRANSITION_FPS", "60")
