# 🎮 Installing and Running Games

> A guide to the gaming stack on Arch Linux: Steam, Proton, Lutris, Heroic and
> MangoHud. Covers all hardware configurations (NVIDIA / AMD / Intel).

[![Russian](https://img.shields.io/badge/lang-Russian-lightgrey)](Gaming_setup.md) ![English](https://img.shields.io/badge/lang-English-1793d1)

<!-- TABLE OF CONTENTS -->
<a name="Table-of-Contents"></a>

## 📚 Contents

+ [Stage 1 — Base install (Steam + Proton)](#Stage-1)
+ [Stage 2 — Lutris + Heroic](#Stage-2)
+ [Stage 3 — MangoHud](#Stage-3)

> 📝 The guide assumes the **GPU driver is already installed** during system
> setup (see [`Arch_linux_install.en.md`](Arch_linux_install.en.md), the
> graphics-card section). Only the **32-bit part** of the driver is added here —
> it's required for Steam and most games, because Steam and many games still use
> 32-bit components.

---

<a name="Stage-1"></a>
## Stage 1. Base install (Steam + Proton)

### 1. Update the system

```bash
sudo pacman -Syu
```

### 2. Enable the multilib repository

Steam and 32-bit libraries live in the `multilib` repository, which is disabled
by default. Open `/etc/pacman.conf`:

```bash
sudo vim /etc/pacman.conf
```

Find these two lines and **uncomment** them (remove the `#` at the start of both):

```ini
[multilib]
Include = /etc/pacman.d/mirrorlist
```

Refresh package databases after enabling:

```bash
sudo pacman -Syu
```

### 3. Install the 32-bit driver for your hardware

The 64-bit driver is already installed from system setup. Now add its 32-bit
counterpart — **strictly for your GPU**. Pick your block.

> ⚠️ **Important:** when installing `steam` (step 4), pacman will ask about the
> `lib32-vulkan-driver` provider and default to `lib32-nvidia-utils` (first in
> the list). If you're **not** on NVIDIA — don't accept the default, pick your
> driver's number. The wrong provider completely breaks Vulkan. Installing the
> 32-bit driver in advance (this step) avoids the prompt altogether.

<details>
<summary><b>🟢 NVIDIA</b> (proprietary / open)</summary>

```bash
sudo pacman -S --needed lib32-nvidia-utils
```

- For NVIDIA there is **no separate** `lib32-vulkan-*` package — 32-bit Vulkan
  ships inside `lib32-nvidia-utils`.
- Works for both `nvidia-open-dkms` and `nvidia-dkms` — the 32-bit part is
  shared.

</details>

<details>
<summary><b>🔴 AMD</b></summary>

```bash
sudo pacman -S --needed lib32-mesa lib32-vulkan-radeon
```

- `lib32-mesa` — 32-bit OpenGL.
- `lib32-vulkan-radeon` — 32-bit Vulkan for Radeon.

</details>

<details>
<summary><b>🔵 Intel iGPU</b></summary>

```bash
sudo pacman -S --needed lib32-mesa lib32-vulkan-intel
```

- `lib32-mesa` — 32-bit OpenGL.
- `lib32-vulkan-intel` — 32-bit Vulkan for Intel.

</details>

### 4. Install Steam and gaming utilities

```bash
sudo pacman -S --needed steam gamemode lib32-gamemode
```

- `steam` — the client itself (official package from multilib).
- `gamemode` / `lib32-gamemode` — a daemon that optimizes the system while
  gaming (CPU governor, priorities). Many games and Proton activate it
  automatically.

> If pacman asks about `lib32-vulkan-driver` and you **didn't** install the
> driver in step 3 — pick the package number for your hardware (NVIDIA →
> `lib32-nvidia-utils`, AMD → `lib32-vulkan-radeon`, Intel → `lib32-vulkan-intel`),
> **don't** blindly accept the default.

### 5. Verify Vulkan works

```bash
vulkaninfo --summary
```

If the command is missing — install `vulkan-tools`. The output should list your
GPU (GeForce / Radeon / Intel), not just the software `llvmpipe`. This confirms
the driver and Vulkan are picked up.

### 6. Enable Steam Play (Proton)

Launch Steam, sign in, then:

**Steam → Settings → Compatibility:**
- enable **Enable Steam Play for supported titles** — Proton for games officially
  verified by Valve;
- enable **Enable Steam Play for all other titles** — Proton for all remaining
  Windows games (needed for most unverified titles);
- from the dropdown, pick the latest available **Proton** version.

Done — you can install Windows games from your library. They'll run through
Proton automatically.

### 7. Choosing a Proton version per game (if needed)

Not every game runs equally well on the same Proton version. If a game won't
launch on the default:

**Library → right-click the game → Properties → Compatibility →** tick **Force
the use of a specific Steam Play compatibility tool** and pick another Proton
version. Checking compatibility reports on ProtonDB is useful.

> 💡 **Proton-GE** (a custom build by GloriousEggroll with extra fixes) is
> installed in Stage 2 and also appears in this list. Stock Proton is enough for
> many games, but Proton-GE often fixes problematic titles.

---

<a name="Stage-2"></a>
## Stage 2. Lutris + Heroic

Lutris and Heroic let you run third-party launchers and games outside Steam:
Lutris — for GOG, Battle.net, Ubisoft and standalone installers; Heroic — for
the Epic Games Store, GOG and Amazon.

### 1. Install Wine and its dependencies

Lutris can download Wine builds itself, but the official recommendation is to
install a base Wine from the repository so all its dependencies are present.
`wine-staging` is the version with extra patches, preferred for gaming:

```bash
sudo pacman -S --needed wine-staging
```

> 💡 **NTSync.** In current Arch Wine packages (`wine`/`wine-staging`), the
> NTSync kernel module (thread-synchronization speedup — noticeably helps in
> games) loads automatically if the kernel supports it. To check it's working
> during a game: `lsof /dev/ntsync`. If the module doesn't load on its own, you
> can install `ntsync-autoload` — but this usually isn't needed.

### 2. Extra dependencies for DXVK/VKD3D

Lutris usually installs DXVK (Direct3D → Vulkan) and VKD3D (DirectX 12 → Vulkan)
per game itself. But the 32-bit Vulkan stack must be present in the system — you
already have it from Stage 1 (step 3). Nothing extra needs installing if Stage 1
is done.

> If a specific game complains about missing DXVK/VKD3D — their binary versions
> install system-wide via the `dxvk-bin` and `vkd3d-proton-bin` packages (from
> AUR). But this is a fallback — by default Lutris manages them itself.

### 3. Install Lutris

Lutris is in the official repository:

```bash
sudo pacman -S --needed lutris
```

Launch it from the application menu or with the `lutris` command.

### 4. Install Heroic (for Epic / GOG / Amazon)

On Arch, Heroic is **AUR-only** — there's no package in the official
repositories, so `pacman -S heroic-games-launcher` won't work. Install the
binary version (the only officially supported AUR package) via yay:

```bash
yay -S heroic-games-launcher-bin
```

### 5. Configure Lutris

**a) Check runners.** Open Lutris → **Preferences → Runners**. Wine should be
available. Via **Manage versions** you can download specific builds (including
GE-Proton), but the defaults are enough to start — Lutris pulls what's needed
when you install your first game.

**b) Games directory.** In **Preferences → Game directories** you can set where
games install. If you have a dedicated game disk — put its path here.

**c) Installing a game.** Games install via installer scripts: search for the
game in Lutris → pick an installer script → follow the dialogs. For storefronts
(GOG, Battle.net, Ubisoft) sign-in happens in an embedded window with the
official login page, including 2FA.

### 6. Configure Heroic and sign in to Epic

**a) First launch — install a runtime.** A fresh Heroic has **no** Proton/Wine by
default. This is the most common cause of "game crashes on launch" — a skipped
runtime step. Open the **Wine Manager** (left sidebar) and download the latest
**GE-Proton** build — it becomes the default compatibility layer.

**b) Sign in to Epic.** Go to the **Epic** section (or GOG / Amazon) → sign in via
the official Epic login page in the window that opens (including 2FA). After
logging in, your Epic library appears in Heroic.

**c) Install and run.** Pick a game → install → Heroic runs it via GE-Proton/umu.
All compatibility management happens inside Heroic; nothing needs symlinking
manually.

> ⚠️ **Anti-cheat.** Games with kernel-level anti-cheat (many online titles)
> usually **won't launch** through Heroic/Wine/Proton regardless of the chosen
> runtime — this is a limitation of the anti-cheat itself, not Heroic. Check a
> game's status on areweanticheatyet.com.

---

<a name="Stage-3"></a>
## Stage 3. MangoHud (monitoring overlay)

MangoHud is an in-game overlay showing FPS, CPU/GPU load and temperatures,
clocks, memory usage, a frametime graph and more.

### 1. Install MangoHud

```bash
sudo pacman -S --needed mangohud lib32-mangohud
```

- `mangohud` — the 64-bit version; `lib32-mangohud` — for 32-bit games (needed
  so the overlay works in older/32-bit titles too).

### 2. How to launch MangoHud

MangoHud doesn't activate on its own — you attach it to the game's launch:

- **Steam:** right-click the game → **Properties** → in the **Launch Options**
  field enter:
  ```
  mangohud %command%
  ```
- **Lutris:** in the game's settings (or globally) enable the **MangoHud** toggle,
  or add `mangohud` to the **Command prefix**.
- **Heroic:** the game settings have a dedicated MangoHud toggle.
- **Manually from the terminal:**
  ```bash
  mangohud <game-launch-command>
  ```
  For OpenGL games, if the overlay doesn't appear, add `--dlsym`:
  `mangohud --dlsym <command>`.

### 3. Where the config lives

The main configuration file:

```
~/.config/MangoHud/MangoHud.conf
```

Create the folder and file if they don't exist:

```bash
mkdir -p ~/.config/MangoHud
vim ~/.config/MangoHud/MangoHud.conf
```

> You can also set a per-game config: the file
> `~/.config/MangoHud/<executable-name>.conf` overrides the global one for that
> specific game.

### 4. Hotkeys (defaults)

- **Show/hide overlay:** `Shift_R + F12`
- **Reload config** (without restarting the game): `Shift_L + F4`
- **Start/stop logging:** `Shift_L + F2`

Keys are reassignable via the `toggle_hud=`, `reload_cfg=`, `toggle_logging=`
parameters.

### 5. What MangoHud can display (main parameters)

Parameters are enabled line-by-line in `MangoHud.conf`. `parameter=0` disables an
on/off parameter.

**Performance:**
- `fps` — FPS counter; `frametime` — frame time (ms); `frame_timing` — frametime
  graph (clearly shows microstutters).
- `fps_limit=0,60,144` — FPS cap (cycles through values); `0` — unlimited.
- `vsync=` / `gl_vsync=` — vertical-sync control.

**CPU:**
- `cpu_stats` — CPU load; `cpu_temp` — temperature; `cpu_power` — power draw;
  `cpu_mhz` — frequency; `core_load` — per-core load.

**GPU:**
- `gpu_stats` — GPU load; `gpu_temp` — temperature; `gpu_core_clock` — core
  clock; `gpu_mem_clock` — memory clock; `gpu_power` — power draw; `vram` — video
  memory usage.
- `gpu_junction_temp` — hotspot temperature (useful for monitoring heavily loaded
  cards).

**Memory and system:**
- `ram` — RAM usage; `swap` — swap; `procmem` — process memory.
- `resolution` — current resolution; `time` — system time;
  `gpu_name` / `cpu_name` — hardware models; `vulkan_driver` — driver version.

**Appearance:**
- `position=top-left` (or `top-right`, `bottom-left`, `bottom-right`) — position;
  `font_size=24` — font size; `alpha=0.5` — foreground opacity;
  `background_alpha=0.4` — background opacity.
- `full` — enable almost all parameters at once; `fps_only` — show FPS only
  (minimal mode).

### 6. A working config for your system

Below is a balanced config: informative but not cluttering the screen. Copy it
into `~/.config/MangoHud/MangoHud.conf`.

```ini
### Position and appearance
position=top-left
font_size=22
background_alpha=0.4
round_corners=8

### FPS and frametime
fps
frametime
frame_timing
fps_limit=0

### CPU
cpu_stats
cpu_temp
cpu_mhz
cpu_power

### GPU (works for both NVIDIA and Intel — parameters are the same)
gpu_stats
gpu_temp
gpu_core_clock
gpu_mem_clock
gpu_power
vram

### Memory
ram

### Info
gpu_name
resolution
vulkan_driver
```

> 💡 The same config works on both machines. On an Intel laptop some metrics
> (e.g. `gpu_power`) may not show if the driver doesn't expose those sensors —
> that's normal, MangoHud simply skips what's unavailable. On the NVIDIA desktop
> all listed parameters are available.

### 7. Logging and benchmarks (optional)

MangoHud can write frametime logs for performance analysis. Add an output folder
to the config:

```ini
output_folder=/home/<user>/mangohud-logs
```

Logging toggles on the fly with `Shift_L + F2`. The resulting logs can be
visualized (frametime graph, 1% lows, average FPS) locally or by uploading to
FlightlessMango.com.
