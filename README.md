# Getting Fallout: London running on Arch Linux

A **complete, beginner-friendly** guide to playing the total conversion **Fallout: London**
on **Arch Linux** (or CachyOS/Manjaro/EndeavourOS) with **Steam's Fallout 4 under Proton** —
including every pitfall that *will* show up on Linux, and exactly how to fix it.

> **Who is this for?** Anyone on an Arch-based system who wants to play Fallout: London and is
> comfortable copy-pasting into a terminal. Every edge case we hit is documented below in
> **[Troubleshooting](#troubleshooting)**.

This is community knowledge, not an official product. You need **legally owned copies** of the games
(see prerequisites).

---

## Contents

1. [How it all works (2 minutes of theory)](#how-it-all-works)
2. [Prerequisites](#prerequisites)
3. [Step 1 – Prepare the system (Arch-specific)](#step-1--prepare-the-system)
4. [Step 2 – Downgrade Fallout 4](#step-2--downgrade-fallout-4)
5. [Step 3 – Install Heroic & download Fallout London](#step-3--heroic--fallout-london)
6. [Step 4 – Deploy London into Fallout 4](#step-4--deploy-london)
7. [Step 5 – The launch option (the crucial trick)](#step-5--the-launch-option)
8. [Step 6 – First launch & verification](#step-6--first-launch--verification)
9. [Installing mods (optional)](#installing-mods)
10. [Troubleshooting](#troubleshooting)
11. [Credits & sources](#credits--sources)

---

## How it all works

Fallout: London is a **mod for Fallout 4** — not a standalone game. For it to run, three things must
line up:

- **Fallout 4 at exactly version `1.10.163.0`.** The "Next-Gen update" from April 2024 changed the
  `Fallout4.exe`. London depends on **F4SE** (Fallout 4 Script Extender), and F4SE hooks into fixed
  memory addresses in the EXE — those shift with every update. So Fallout 4 must be **downgraded** to
  the last pre-Next-Gen version.
- **F4SE must actually load under Proton.** This is where most Linux attempts fail — Steam doesn't
  launch the F4SE loader, it launches the normal launcher. We solve that with a small wrapper script.
- **The Fallout London game files** (here obtained via GOG/Heroic) have to go into the Fallout 4 install.

> **Why Steam for FO4 and GOG for London?** Fallout: London is available as a free download on GOG
> (you need Fallout 4 there). On Steam, FO4 would otherwise keep re-updating itself. This guide covers
> the most common combination: **Fallout 4 on Steam, Fallout London on GOG.**

---

## Prerequisites

| What | Details |
|------|---------|
| **Arch-based Linux** | Arch, CachyOS, EndeavourOS, Manjaro … |
| **Steam** installed | with the `multilib` repo enabled (almost always true for Steam users) |
| **Fallout 4 (GOTY / all DLC)** on Steam | **without** the High-Resolution Texture Pack (it causes crashes) |
| **Fallout: London** claimed on GOG | free if you own Fallout 4 GOTY on GOG |
| **~40 GB free space** | FO4 (~38 GB) + London download (~40 GB) |
| **Time** | the downgrade alone takes 40 min – 2 h |

> If you own Fallout 4 **on GOG**: the downgrade is unnecessary (GOG never updated to Next-Gen) —
> just install FO4 through Heroic and skip [Step 2](#step-2--downgrade-fallout-4).

---

## Step 1 – Prepare the system

The downgrader uses **SteamCMD** (32-bit) and a small Qt GUI. Install the dependencies:

```bash
sudo pacman -S --needed lib32-gcc-libs python-pyqt5 curl unrar git
```

- `lib32-gcc-libs` — 32-bit libraries for SteamCMD (**requires the `multilib` repo**, see below)
- `python-pyqt5`, `curl` — for the downgrader
- `unrar`, `git` — for extracting / cloning

<details>
<summary>Enable multilib (if you haven't already)</summary>

In `/etc/pacman.conf` these two lines must be present **without the `#`**:

```
[multilib]
Include = /etc/pacman.d/mirrorlist
```

Then run `sudo pacman -Sy`. Check with: `grep -A1 '^\[multilib\]' /etc/pacman.conf`
</details>

You'll also need an **AUR helper** later for Heroic. If you don't have one, `paru` is a good choice.

---

## Step 2 – Downgrade Fallout 4

**Goal:** bring Fallout 4 from Next-Gen back down to `1.10.163.0`.

1. **Install Fallout 4 via Steam** — with **all DLC**, but **without** the
   "High Resolution Texture Pack" (deselect it under DLC in Steam).

2. **Get the Linux downgrader** (by Team FOLON):

   ```bash
   git clone https://github.com/Fallout-London/FOLON-FO4Downgrader.git
   cd FOLON-FO4Downgrader
   ```

3. **Run the downgrader** — not via `Run.sh` (its venv can't see your system PyQt5), but directly with
   system Python and forced XWayland:

   ```bash
   QT_QPA_PLATFORM=xcb WAYLAND_DISPLAY= python3 ./FOLON-Downgrader.py --linux
   ```

4. In the terminal you'll be asked for:
   - **Path to Fallout 4:** `~/.local/share/Steam/steamapps/common/Fallout 4`
   - **Steam username + password** (password is entered hidden)
   - **Steam Guard:** for the mobile authenticator, the current 5-character code from the Steam app;
     confirm the login in the app if prompted.

   The downgrader now pulls the old depot via SteamCMD (**40 min – 2 h**) and lays it over your
   install. It removes Creation Club content and the HiRes DLC automatically.

5. **Verify the version:**

   ```bash
   grep -aoE '1\.10\.[0-9]+\.[0-9]+' "$HOME/.local/share/Steam/steamapps/common/Fallout 4/Fallout4.exe" | sort -u
   ```
   Must print **`1.10.163.0`**. (Next-Gen would be `1.10.980.0`.)

> ### ⚠️ Important: don't let Steam undo the downgrade
> Steam → right-click **Fallout 4** → **Properties** → **Updates** →
> "**Only update this game when I launch it**". And **never** "Verify integrity of game files" —
> that pulls the Next-Gen version right back.

6. **Launch Fallout 4 once** (via Steam) to the main menu, then quit. This creates the Proton prefix
   and the config files we'll need shortly.

<details>
<summary>🔧 If the downgrader crashes during "MOVING FILES" (NotADirectoryError)</summary>

Known bug: the tool trips over SteamCMD's `state_*.patch` files. But the download is already complete
at that point. You can finish moving the files yourself via hardlinks (instant, no second download):

```bash
FO4="$HOME/.local/share/Steam/steamapps/common/Fallout 4"
APP="$FO4/SteamFiles/linux32/steamapps/content/app_377160"
for d in "$APP"/depot_*/; do cp -rlf "$d." "$FO4/"; done
# remove Creation Club and HiRes leftovers:
find "$FO4/Data" -maxdepth 1 -name 'cc*' -delete
find "$FO4/Data" -maxdepth 1 -name 'DLCUltraHighResolution*' -delete
rm -rf "$FO4/SteamFiles"
```
Then verify the version with the `grep` command from step 5.
</details>

---

## Step 3 – Heroic & Fallout London

Fallout: London comes via the **Heroic Games Launcher**. Use the **native AUR version**
(not Flatpak — the Flatpak sandbox can't cleanly reach your Steam folder):

```bash
paru -S heroic-games-launcher-bin
```

Then in Heroic:

1. **Log in to GOG** (Stores/Login → opens a browser).
2. **Library** → **Fallout: London** → **Install** (default path `~/Games/Heroic/Fallout London`).
   The download is large (~40 GB).

> No need to launch the game from Heroic — we only need the downloaded files.

---

## Step 4 – Deploy London

The London folder contains the game files **loosely extracted** (`Data/`, F4SE, `WinHTTP.dll`,
`xSE PluginPreloader.xml`, configs). We copy them into the (downgraded) Steam Fallout 4 install.

Easiest with the included script:

```bash
cd fallout-london-arch-linux   # this repo
./scripts/install-london.sh "$HOME/Games/Heroic/Fallout London" \
    "$HOME/.local/share/Steam/steamapps/common/Fallout 4"
```

The script handles:
- `Data/*` → `Fallout 4/Data` (hardlink merge)
- F4SE + `WinHTTP.dll` + `xSE PluginPreloader.xml` + `CustomControlMap.txt` → game root
- Preloader load method set to **`OnProcessAttach`** (required under Wine, otherwise Buffout loads too late)
- `CustomControlMap.txt` also into `Data/F4SE/` (so later console rebinds take effect)
- `__Config/*.ini` and `__AppData/*` into the **Proton prefix** (AppID 377160)

<details>
<summary>Prefer to do it by hand? (what the script does)</summary>

```bash
LON="$HOME/Games/Heroic/Fallout London"
FO4="$HOME/.local/share/Steam/steamapps/common/Fallout 4"
PFX="$HOME/.local/share/Steam/steamapps/compatdata/377160/pfx/drive_c/users/steamuser"

cp -rlf "$LON/Data/." "$FO4/Data/"
cp -f "$LON"/f4se_*.* "$LON/WinHTTP.dll" "$LON/xSE PluginPreloader.xml" "$LON/CustomControlMap.txt" "$FO4/"
sed -i 's/<LoadMethod Name="ImportAddressHook">/<LoadMethod Name="OnProcessAttach">/' "$FO4/xSE PluginPreloader.xml"
mkdir -p "$FO4/Data/F4SE" "$PFX/Documents/My Games/Fallout4" "$PFX/AppData/Local/Fallout4"
cp -f "$LON/CustomControlMap.txt" "$FO4/Data/F4SE/CustomControlMap.txt"
cp -f "$LON/__Config/"*.ini "$PFX/Documents/My Games/Fallout4/"
cp -f "$LON/__AppData/"*    "$PFX/AppData/Local/Fallout4/"
```
</details>

---

## Step 5 – The launch option

**This is the part almost everyone gets stuck on.** When you hit "Play", Steam doesn't launch
`Fallout4.exe` directly — it launches **`Fallout4Launcher.exe`**, and **never** the F4SE loader.
Without a fix: the intro plays, but the first big loading screen **crashes**, because F4SE and its
plugins were never loaded.

The fix is the `scripts/folon-launch.sh` wrapper from this repo. It:

1. loads `winhttp` as a **native** DLL (→ the preloader loads Buffout early), and
2. replaces the launcher with **`f4se_loader.exe`** (→ the F4SE core and all plugins load).

**Set it up:**

1. In Steam → right-click **Fallout 4** → **Properties** → **Compatibility** → force
   "Proton Experimental" (or 9.0).
2. Under **General → Launch Options**, enter this (adjust the path to your username!):

   ```
   /home/YOURNAME/fallout-london-arch-linux/scripts/folon-launch.sh %command%
   ```

Done. No fragile `sed`/`eval` juggling inside the launch options — the script does everything
deterministically.

---

## Step 6 – First launch & verification

**Launch Fallout 4 via Steam.** Expected: the **Fallout London intro/main menu** (not vanilla FO4).

To confirm F4SE and all plugins actually loaded, check the log:

```bash
cat "$HOME/.local/share/Steam/steamapps/compatdata/377160/pfx/drive_c/users/steamuser/Documents/My Games/Fallout4/F4SE/f4se.log"
```

If the file exists and lists `Buffout4`, `x-cell`, `HighFPSPhysicsFix` and the `FOLON_*` plugins as
"loaded correctly" → **everything's right**. Enjoy London! 🇬🇧☢️

---

## Installing mods

Without a mod manager, the most robust approach on Linux is **manual**: extract the mod archive, copy
its contents into `Fallout 4/Data/`, activate the plugin in `Plugins.txt`.

- **Plugins.txt** lives here: `…/compatdata/377160/pfx/drive_c/users/steamuser/AppData/Local/Fallout4/Plugins.txt`
  Active plugins have a `*` prefix. Load order: masters (`.esm`) at the top, bugfix patches (UFO4P/CFM)
  early, graphics/weather last.
- **F4SE DLL plugins** go into **exactly one** folder: `Data/F4SE/plugins/` (London's folder is
  **lowercase** — see case-sensitivity below).

> ### The three golden Linux modding rules for London
> 1. **Always Old-Gen (1.10.163)**, never Next-Gen (1.10.980) for F4SE DLL mods (MCM, Buffout, plugins).
>    "id not found" / "incompatible during query" while version 1.10.163.0 is correctly detected = the
>    wrong (NG) file.
> 2. **Exactly one `plugins` folder.** Linux is case-sensitive: `Plugins` ≠ `plugins`. Two folders →
>    DLLs can't find the Address Library.
> 3. **The right language file.** `-CHS`/`-CHT`/… in the filename = a Chinese/other translation →
>    item names render as **boxes** ("tofu"). Always take the English base file.

**What does NOT work:** **Sim Settlements 1/2** is built for the Commonwealth (its own quest start,
workshop settlement system) and is **not compatible** with London's worldspace — stay away.
**High FPS Physics Fix** is already bundled with London — do not install it twice.

---

## Troubleshooting

Sorted by symptom. Most of these we actually ran into.

### Intro plays, but crash on the first big loading screen
The F4SE core isn't loading. Check in order:
- **Launch option set?** The `folon-launch.sh` wrapper must be active (→ [Step 5](#step-5--the-launch-option)).
- **No `f4se.log`?** Then the F4SE loader isn't running → check the wrapper (are you passing `%command%`?).
- **Only `Buffout4` in the log, nothing else?** Then you're launching `Fallout4.exe` directly instead of
  `f4se_loader.exe` → the wrapper isn't redirecting the launcher (see the script's `*/Fallout4Launcher.exe` case).

### Popup: "failed to open: …/version-1-10-163-0.bin"
An F4SE DLL can't find the **Address Library** — usually **case-sensitivity**: both
`Data/F4SE/plugins/` (lowercase) **and** `Data/F4SE/Plugins/` (uppercase) exist. Merge them:

```bash
F="$HOME/.local/share/Steam/steamapps/common/Fallout 4/Data/F4SE"
[ -d "$F/Plugins" ] && { mv "$F/Plugins/"* "$F/plugins/"; rmdir "$F/Plugins"; }
```

### Popup: "id … not found! game version: 1.10.163.0" or "incompatible during query"
The DLL is the **Next-Gen version**. On the mod page, grab the **Old-Gen / pre-Next-Gen (1.10.163)**
file specifically (often an older version number). Classically affects **MCM** and various F4SE plugins.
The **Old-Gen MCM** is e.g. version **1.39**.

### Some item names are blocks of squares ("tofu")
Missing glyphs. Almost always: you installed a **translation file** (`-CHS` = Chinese, etc.) instead of
the English base mod. Check and use the English version. (Single missing characters rather than whole
names → London's slim font; remedy: the "Original Fallout 4 Font" mod.)

### The console (`~`) won't open
The console is **enabled** (`bAllowConsole=1`), but the key is wrong: London binds it to VK `0xC0`,
which — depending on the Wine layout — sits on a different physical key. Robust fix: rebind it to a
**letter** (layout-independent), e.g. `L`. In `Fallout 4/Data/F4SE/CustomControlMap.txt` change both
`Console` lines from `0xc0` to `0x4c` (= L):

```bash
CM="$HOME/.local/share/Steam/steamapps/common/Fallout 4/Data/F4SE/CustomControlMap.txt"
sed -i '/^Console[[:space:]]/ s/0xc0/0x4c/' "$CM"
```
Important: the file must live under **`Data/F4SE/`** (F4SE reads it there, not from the game root),
and you must launch via `f4se_loader`.

### After using a terminal: can't move or save, only jump
Controls are stuck in **gamepad input mode** (Steam Input presents a virtual controller). Two fixes
together:
- Steam → Fallout 4 → **Controller** → set "Steam Input" to **Disabled**.
- In `…/My Games/Fallout4/Fallout4Prefs.ini`: set `bGamepadEnable=0` and add `bBackgroundMouse=1`
  under `[Controls]`.

### No audio
Usually fine under Proton (FAudio is included). If silent: try a different Proton version or install
`xact` via **protontricks** (`protontricks 377160 xact xact_x64`).

---

## Credits & sources

This guide stands on the shoulders of others — thanks to:

- **Team FOLON** for Fallout: London and the Linux downgrader
  (<https://github.com/Fallout-London/FOLON-FO4Downgrader>)
- **afwolfe/fallout-london-linux-installer** — reference for the Steam/Proton approach
- **overkill.wtf** "Ultimate Fallout London Installation Guide for Steam Deck / Linux"
- **SteamDeckHQ** and the **Heroic Games Launcher wiki** guide for Fallout: London
- the **xSE PluginPreloader** and **Buffout 4 / X-Cell** authors

What this repo adds: it's **Arch-specific** (`multilib`, `paru`, `lib32-gcc-libs`) and documents the
**concrete Linux pitfalls** (launcher redirect, case-sensitivity, Old-Gen DLLs, console rebind,
gamepad lock, tofu/translation trap) that are missing or scattered elsewhere.

*Not an official Team FOLON or Bethesda product. You need legally owned copies of the games.*

## License

MIT — see [LICENSE](LICENSE).
