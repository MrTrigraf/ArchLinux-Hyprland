# Arch Linux + Hyprland

> Ready-to-use Arch Linux system with the Hyprland window manager, `kanagawa-paper` theme, and a complete set of pre-configured applications.

[![Russian](https://img.shields.io/badge/lang-Russian-lightgrey)](README.md) ![English](https://img.shields.io/badge/lang-English-1793d1)

![status](https://img.shields.io/badge/status-active-brightgreen) ![Hyprland](https://img.shields.io/badge/Hyprland-0.55.4-blue) ![Arch](https://img.shields.io/badge/Arch-Rolling-1793d1)

<!-- SYSTEM PARAMETERS -->
<h2 align="left">💻 System parameters</h2>

<table>
<tr>
<td valign="top" width="55%">

- **OS:** [**`Arch Linux`**](https://archlinux.org/)
- **WM:** [**`Hyprland`**](https://hyprland.org/) (Wayland, 0.55+ on Lua)
- **Bar / Popups / Notifications:** [**`Quickshell`**](https://quickshell.org/)
- **Terminal:** [**`kitty`**](https://sw.kovidgoyal.net/kitty/)
- **App Launcher:** [**`rofi`**](https://github.com/davatorium/rofi)
- **Lock / Idle:** [**`hyprlock`**](https://github.com/hyprwm/hyprlock) + [**`hypridle`**](https://github.com/hyprwm/hypridle)
- **Wallpaper:** [**`awww`**](https://github.com/LGFae/awww)
- **Shell:** [**`fish`**](https://fishshell.com/)
- **Theme:** `kanagawa-paper`

</td>
<td valign="top" width="45%">

<img src="docs/screenshots/main.png" alt="main screenshot" />

</td>
</tr>
</table>

<!-- GALLERY -->
<a name="Gallery"></a>
<h2 align="center">🖼️ Gallery</h2>

<table>
<tr>
<td align="center" width="33%">
  <img src="docs/screenshots/popups.png" alt="popups"><br>
  <b>Popups</b>
</td>
<td align="center" width="33%">
  <img src="docs/screenshots/rofi.png" alt="rofi"><br>
  <b>Rofi</b>
</td>
</tr>
<tr>
<td align="center" width="33%">
  <img src="docs/screenshots/hyprlock.png" alt="hyprlock"><br>
  <b>Lock-screen</b>
</td>
<td align="center" width="33%">
  <img src="docs/screenshots/cmus.png" alt="cmus"><br>
  <b>cmus</b>
</td>
</tr>
</table>

<!-- TABLE OF CONTENTS -->
<a name="Table-of-Contents"></a>

# 📚 Table of Contents

+ [Installation](#Installation)
  + [Install Arch Linux](#Install-Arch-Linux)
  + [SSH Key for GitHub](#SSH-Key-for-GitHub)
  + [Deploy the Setup](#Install-Hyprland-Config)
+ [About the System](#About-System)
  + [Architecture](#Architecture)
  + [Features](#Features)
  + [HotKeys](#HotKeys)
  + [Installed Packages](#Packages)

---

<!-- ===================== INSTALLATION ===================== -->
<a name="Installation"></a>
<h2 align="center">⚡ Installation</h2>

<a name="Install-Arch-Linux"></a>
### 1. Install Arch Linux

Detailed instructions — [`docs/Arch_linux_install.en.md`](docs/Arch_linux_install.en.md).

**Short overview:**

- Disk partitioning (GPT): EFI (1G) + swap (≈ RAM) + btrfs
- Creating subvolumes `@` and `@home` on btrfs
- Base system installation: `base base-devel linux-zen ...`
- Locale, time, and network setup
- systemd-boot bootloader installation
- User creation with `wheel` group

> 💡 **Important:** on NVIDIA desktops, `nvidia-drm.modeset=1` must be added to the kernel parameters.

<a name="SSH-Key-for-GitHub"></a>
### 2. SSH Key Setup for GitHub

Instructions — [`docs/Setting_SSH_key.en.md`](docs/Setting_SSH_key.en.md).

**TL;DR:**

```bash
ssh-keygen -t ed25519 -C "your_comment"
cat ~/.ssh/id_ed25519.pub   # copy the output
```

→ Add the key at [GitHub Settings → SSH keys](https://github.com/settings/keys).

Verify:

```bash
ssh -T git@github.com
```

Configure git (use a **private no-reply email**):

```bash
git config --global user.name "Your Name"
git config --global user.email "12345678+github@users.noreply.github.com"
```

<a name="Install-Hyprland-Config"></a>
### 3. Deploy the Setup

```bash
# Clone the repository (entire repo into ~/.config/hypr — including the hyprland.lua entry point)
git clone git@github.com:MrTrigraf/ArchLinux-Hyprland.git ~/.config/hypr

# Run bootstrap (as a regular user, NOT via sudo)
cd ~/.config/hypr
./bootstrap.sh
```

After `bootstrap.sh` completes — exit the tty (`exit`) and log in again. Fish will auto-launch Hyprland via `exec start-hyprland`.

[⬆ Back to the Top](#Table-of-Contents)

---

<!-- ===================== ABOUT SYSTEM ===================== -->
<a name="About-System"></a>
<h2 align="center">⚙️ About the System</h2>

<a name="Architecture"></a>
<h3 align="center">🏗️ Architecture</h3>

- `hyprland.lua` — Hyprland entry point (short `dofile` to the active theme)
- `bootstrap.sh` — package installation and symlink creation
- `kanagawa-paper/hypr/` — Hyprland Lua modules (input, keybinds, windowrules, animations)
- `kanagawa-paper/quickshell/` — status bar, popups, notifications (QML, Qt 6)
- `kanagawa-paper/hypridle/`, `kanagawa-paper/hyprlock/` — sleep and lock (hyprlang)
- `kanagawa-paper/rofi/` — launcher (`drun` + `files` + `ssh`)
- `kanagawa-paper/kitty/`, `kanagawa-paper/fish/`, `kanagawa-paper/starship/`, `kanagawa-paper/cmus/` — application configs
- `kanagawa-paper/theming/` — GTK / Qt / cursor / dconf
- `kanagawa-paper/wallpaper/` — wallpapers

[⬆ Back to the Top](#Table-of-Contents)

<a name="Features"></a>
<h3 align="center">🚀 Features</h3>

- Hyprland 0.55+ on the new Lua API (not on the legacy hyprlang).
- Status bar, popups, and notifications — custom implementation on Quickshell, no Waybar / mako / nm-applet / blueman-applet.
- One repository for two machines: laptop vs desktop split in `bootstrap.sh`.
- Modular config — theme switching via editing a single line in the entry point.
- Theme `kanagawa-paper` — muted palette without neon.

[⬆ Back to the Top](#Table-of-Contents)

<a name="HotKeys"></a>
<h3 align="center">⌨️ HotKeys</h3>

- **Terminal (kitty)** — `super + enter`
- **kitty with nvim** — `super + n`
- **File manager (nautilus)** — `super + e`
- **Browser (firefox)** — `super + b`
- **App launcher (rofi)** — `super + r`
- **Close window** — `super + q`
- **Toggle float** — `super + v`
- **togglesplit (dwindle)** — `super + shift + j`
- **Lock-screen (hyprlock)** — `super + shift + l`
- **cmus in floating kitty** — `super + shift + p`
- **Exit Hyprland** — `super + shift + r`
- **Reload Quickshell** — `super + ctrl + r`
- **Window focus (vim-style)** — `super + h / j / k / l`
- **Switch workspace** — `super + 1..5`
- **Move window to workspace** — `super + shift + 1..5`
- **Scroll through workspaces** — `super + wheel`
- **Special workspace `magic`** — `super + s` / `super + shift + s`
- **Window drag / resize** — `super + lmb / rmb`
- **Screenshot → clipboard** — `print`
- **Screenshot → file** — `shift + print`

Full list — in `~/.config/hypr/kanagawa-paper/hypr/keybindings.lua`.

[⬆ Back to the Top](#Table-of-Contents)

<a name="Packages"></a>
<h3 align="center">📦 Installed Packages</h3>

<details>
<summary><b>📦 Pacman — common (~58 packages)</b></summary>

**Hyprland core + infrastructure:**
`hyprland` · `hyprlock` · `hyprshot` · `hypridle` · `hyprpolkitagent` · `xdg-desktop-portal-hyprland` · `xdg-desktop-portal-gtk` · `xorg-xwayland` · `qt5-wayland` · `qt6-wayland` · `qt5ct` · `qt6ct` · `lua` · `quickshell` · `awww`

**Fonts:** `noto-fonts` · `noto-fonts-emoji` · `ttf-jetbrains-mono-nerd`

**Audio:** `pipewire` · `pipewire-pulse` · `pipewire-jack` · `wireplumber` · `pavucontrol` · `playerctl`

**GStreamer codecs:** `gst-plugins-base` · `gst-plugins-good` · `gst-plugins-bad` · `gst-plugins-ugly` · `gst-libav` · `gst-plugin-pipewire`

**Shell and prompt:** `fish` · `starship` · `lsd`

**CLI utilities:** `git` · `less` · `fastfetch` · `btop` · `wl-clipboard`

**Launcher:** `rofi`

**GUI applications:** `firefox` · `telegram-desktop` · `obsidian` · `nautilus` · `sushi` · `file-roller` · `viewnior` · `showtime` · `cmus` · `impression`

**Theming:** `papirus-icon-theme` · `adw-gtk-theme`

**Network:** `nm-connection-editor` · `networkmanager-openvpn`

**Notifications:** `sound-theme-freedesktop` · `libnotify`

**Auto-mount:** `udiskie`

**Base:** `kitty` · `polkit`

</details>

<details>
<summary><b>💻 Laptop-only — conditional via <code>is_laptop</code> (5 packages)</b></summary>

- `power-profiles-daemon` — power profile switching
- `brightnessctl` — brightness control
- `bluez` · `bluez-utils` · `blueman` — Bluetooth stack

</details>

<details>
<summary><b>🌐 AUR — via <code>yay-bin</code> (4 packages)</b></summary>

- `vesktop-bin` — Discord client on Electron with patches
- `ttf-material-symbols-variable-git` — Material Symbols (variable FILL/weight)
- `xcursor-pro-hyprcursor` — cursor theme for hyprcursor
- `papirus-folders-git` — colored folders for Papirus-Dark

</details>

[⬆ Back to the Top](#Table-of-Contents)
