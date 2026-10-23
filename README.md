# Klipp

Instant-replay game clips for Linux, in the spirit of Medal or ShadowPlay. Klipp keeps the last few seconds of your screen in RAM, and one hotkey turns them into a clip that lands in a library sorted by game.

It is a small GTK4/libadwaita app on top of [GPU Screen Recorder](https://git.dec05eba.com/gpu-screen-recorder/), which does the actual capture on the GPU (NVENC, VAAPI), so recording in the background costs almost no FPS.

> The UI is in German. Commands, config and this README are in English.

## Features

- **Always-on instant replay.** The last 30 seconds (5 to 600, configurable) stay in a RAM buffer. Nothing touches the disk until you save.
- **One hotkey.** `Alt+F10` by default, changeable in the settings. Saving plays a shutter sound and shows a notification with a thumbnail; clicking it opens the clip.
- **Sorted by game.** Steam games are recognized by their app ID, Proton titles included. Anything else is named after its window. Terminals, browsers, Discord and friends go to `Desktop`.
- **Library.** Thumbnail grid, search (`Ctrl+F`), favorites, and a sidebar listing every game.
- **Folders.** Album-style folders you create yourself. Add clips by right-clicking or by dragging a card onto a folder. A clip can be in several folders, and the files never move.
- **Player with trimming.** Drag the handles (or set them to the playhead with the `[` and `]` buttons), then hit *Schnitt speichern*. The cut is saved as a new file next to the original.
- **Discord-ready.** *Für Discord* compresses a clip (or just the trimmed range) to 10, 50 or 500 MB and copies it to the clipboard; paste it into Discord with `Ctrl+V`. You can also drag a card straight into a Discord window.

## Requirements

- Linux on Wayland. Built and tested on **Arch Linux + Hyprland**.
- A GPU that GPU Screen Recorder supports (NVIDIA, AMD or Intel).
- PipeWire for audio.
- Python 3.11 or newer, GTK 4, libadwaita 1.6 or newer.

On Hyprland everything works out of the box. Other compositors can record as well, but Klipp gets the hotkey by reading the keyboard directly there (see [Hotkey](#hotkey)), and game detection falls back to `Desktop`, because it asks `hyprctl` for the active window.

## Install

```sh
sudo pacman -Syu
git clone https://github.com/Silvertree2010/klipp.git ~/klipp
cd ~/klipp
./install.sh
```

The installer:

1. installs missing packages with pacman (`gpu-screen-recorder`, `python-gobject`, `gtk4`, `libadwaita`, `gst-plugins-good`, `gst-libav`, `ffmpeg`, `wl-clipboard`, `libnotify`, `pipewire`),
2. copies Klipp to `~/.local/lib/klipp` and puts a `klipp` launcher in `~/.local/bin`,
3. adds the desktop entry and icon,
4. enables and starts the `klipp.service` user unit, so instant replay runs whenever you log in.

No root is needed beyond the package step, and nothing has to go into your Hyprland config.

**Update:** `git pull && ./install.sh`
**Uninstall:** `./install.sh --remove` (clips and settings are kept)

### Other distributions

`install.sh` relies on pacman. Elsewhere, install the equivalents of the packages above yourself, comment out the pacman block and run the script, or start Klipp straight from the checkout:

```sh
python3 -m klipp daemon   # recorder in the foreground
python3 -m klipp          # library
```

## Usage

Open **Klipp** from your app launcher. The switch at the bottom left of the sidebar turns instant replay on or off, and *Clip speichern* saves a clip without the hotkey.

| Command | What it does |
|---|---|
| `klipp` | Open the library |
| `klipp save [SEC]` | Save a clip, optionally only the last `SEC` seconds |
| `klipp open FILE` | Open a clip in the player |
| `klipp status` | Show whether instant replay is running (exit code 3 if not) |
| `klipp start` / `stop` / `restart` | Control the `klipp.service` unit |
| `klipp daemon` | Run the recorder in the foreground (used by systemd) |

### Hotkey

The background daemon owns the hotkey, so it works even while the library window is closed.

- **Hyprland:** Klipp registers a runtime bind through `hyprctl keyword bind`. Hyprland drops runtime binds on `hyprctl reload`, so the daemon checks every few seconds and puts it back.
- **Everything else:** Klipp reads the keyboard from `/dev/input`. Your user needs read access, which usually means joining the `input` group (`sudo usermod -aG input $USER`, then log in again).

To change the hotkey, open *Einstellungen*, click the hotkey row and press the new combination. Backspace removes the hotkey; Esc cancels. Klipp warns you if Hyprland already uses that combination for something else.

If you would rather bind it yourself, set the hotkey to nothing and bind `klipp save` in your compositor.

## Configuration

Everything is in the settings dialog (menu, *Einstellungen*, or `Ctrl+,`). It is stored in `~/.config/klipp/config.toml`:

```toml
clip_seconds = 30          # length of the replay buffer
fps = 60
quality = "very_high"      # medium | high | very_high | ultra
codec = "h264"             # h264 | hevc | av1
monitor = "auto"           # auto = largest landscape monitor, or e.g. "DP-1"
desktop_audio = true
microphone = false
cursor = true
hotkey = "ALT+F10"         # empty string = no hotkey
library = "~/Videos/Klipp"
discord_limit_mb = 10      # 10 | 50 | 500
notifications = true
sound = true
```

Changes to recording settings restart the recorder automatically. If you edit the file by hand, run `klipp restart`.

H.264 is the default because Discord and every browser can play it. HEVC and AV1 make smaller files, but they may not preview in Discord.

## Where things live

| What | Where |
|---|---|
| Clips | `~/Videos/Klipp/<Game>/` |
| Discord exports | `~/Videos/Klipp/.discord/` |
| Settings | `~/.config/klipp/config.toml` |
| Favorites, folders, metadata | `~/.local/share/klipp/index.json` |
| Thumbnails | `~/.cache/klipp/thumbs/` |
| Runtime state, recorder socket | `$XDG_RUNTIME_DIR/klipp/` |
| Logs | `journalctl --user -u klipp` |

Clips are plain MP4 files, so you can move, rename or delete them in your file manager; the library shows the change the next time you open it.

## Troubleshooting

**Instant replay stays off.** Run `klipp status` and look at `journalctl --user -u klipp -e`. The message GPU Screen Recorder printed last also shows up under the switch in the sidebar.

**"Warte auf Wayland-Sitzung …"** The user service started before your compositor exported its environment to systemd. Hyprland does this on its own; on other compositors, add `systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP` (or `dbus-update-activation-environment --systemd --all`) to your autostart.

**The hotkey does nothing.** The subtitle of the hotkey row in the settings shows whether it is bound through Hyprland or the keyboard, or why it failed. Outside Hyprland, check that you are in the `input` group.

**Trimming or Discord export is slow.** Klipp re-encodes with NVENC when it is available and falls back to x264 otherwise, which runs on the CPU.

## License

MIT
