<h1 align="center">Klipp</h1>

<p align="center">
  Instant replay for Linux gaming: press a hotkey and the last 30 seconds
  become a clip, sorted by game, ready to trim and send to Discord.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Linux-Wayland-2b2b2b?logo=linux&amp;logoColor=white" alt="Linux, Wayland">
  <img src="https://img.shields.io/badge/Hyprland-ready-58E1FF?logo=hyprland&amp;logoColor=black" alt="Hyprland ready">
  <img src="https://img.shields.io/badge/Arch%20Linux-install.sh-1793D1?logo=archlinux&amp;logoColor=white" alt="Arch Linux">
  <img src="https://img.shields.io/badge/Python-3.11%2B-3776AB?logo=python&amp;logoColor=white" alt="Python 3.11+">
  <img src="https://img.shields.io/badge/GTK-4%20%C2%B7%20libadwaita-4A86CF?logo=gtk&amp;logoColor=white" alt="GTK 4 and libadwaita">
  <img src="https://img.shields.io/badge/status-beta-cc785c" alt="Status: beta">
  <a href="LICENSE"><img src="https://img.shields.io/github/license/Silvertree2010/klipp" alt="License: MIT"></a>
</p>

Klipp is Medal or ShadowPlay for the Linux desktop. It keeps the last few
seconds of your screen in RAM, and one key press saves them as a clip. The
capture runs on the GPU through [GPU Screen Recorder][gsr], so leaving it on
all the time costs almost no FPS.

> [!NOTE]
> Klipp is built and tested on Arch Linux with Hyprland. Other Wayland
> compositors work, with two limits described under
> [Good to know](#good-to-know).

If Klipp saves you a clip worth keeping, a star on GitHub helps other Linux
gamers find it.

## What's inside

- **Always-on instant replay.** The last 30 seconds (5 to 600, your choice)
  stay in a RAM buffer. Nothing is written to disk until you save.
- **One hotkey.** `Alt+F10` by default. Saving plays a shutter sound and shows
  a notification with a thumbnail; click it to watch the clip.
- **Sorted by game.** Steam games are recognised by their app ID, Proton
  titles included. Other games are named after their window, and terminals,
  browsers or Discord go to *Desktop*.
- **Library** with thumbnails, search (`Ctrl+F`), favourites and a sidebar
  listing every game.
- **Folders** that work like albums. Right-click a clip or drag it onto a
  folder. A clip can sit in several folders, and the file never moves.
- **Player with trimming.** Drag the handles, or set them to the playhead with the
  `[` and `]` buttons, then click **Save cut**. The cut is a new file; the original
  stays.
- **For Discord.** One click compresses the clip (or the trimmed part) to
  10, 50 or 500 MB and copies it to the clipboard. Paste it with `Ctrl+V`, or
  drag a card straight into Discord.
- **Start at login** through a systemd user service, switchable in the
  settings.

## Install

You need **Linux on Wayland**, a GPU that GPU Screen Recorder supports
(NVIDIA, AMD or Intel) and PipeWire.

**Arch Linux.** The installer pulls in the missing packages and sets up
everything else:

```sh
sudo pacman -Syu
git clone https://github.com/Silvertree2010/klipp.git ~/klipp
cd ~/klipp
./install.sh
```

It copies Klipp to `~/.local/lib/klipp`, puts a `klipp` launcher in
`~/.local/bin`, adds the app to your launcher and enables `klipp.service`, so
instant replay runs from the moment you log in. Root is only used for pacman,
and nothing goes into your Hyprland config.

```sh
git pull && ./install.sh   # update
./install.sh --remove      # uninstall, clips and settings are kept
```

**Other distributions.** Install the equivalents of `gpu-screen-recorder`,
`python-gobject`, `gtk4`, `libadwaita` (1.6 or newer), `gst-plugins-good`,
`gst-libav`, `ffmpeg`, `wl-clipboard` and `libnotify`, then run Klipp from the
checkout:

```sh
python3 -m klipp daemon   # recorder
python3 -m klipp          # library
```

## Usage

Open **Klipp** from your app launcher. The switch at the bottom left turns
instant replay on and off, and **Save clip** below it saves without the
hotkey.

| Command | Does |
| --- | --- |
| `klipp` | Open the library |
| `klipp save [SEC]` | Save a clip, optionally only the last `SEC` seconds |
| `klipp open FILE` | Open a clip in the player |
| `klipp status` | Is instant replay running? (exit code 3 if not) |
| `klipp start` / `stop` / `restart` | Control the background service |
| `klipp daemon` | Run the recorder in the foreground |

| Keys | Does |
| --- | --- |
| `Alt+F10` | Save a clip (changeable) |
| `Ctrl+F` | Search clips |
| `Ctrl+,` | Settings |
| `Space`, `←` `→` | Play/pause and skip 2 s in the player |
| `Ctrl+Q` | Quit the library (recording keeps running) |

## Settings

Everything is in **Menu → Settings**. Changes to recording restart the
recorder on their own. The file behind it is `~/.config/klipp/config.toml`:

```toml
clip_seconds = 30          # length of the replay buffer
fps = 60
quality = "very_high"      # medium | high | very_high | ultra
codec = "h264"             # h264 | hevc | av1
monitor = "auto"           # auto = largest landscape monitor, or e.g. "DP-1"
desktop_audio = true
microphone = false
cursor = true
hotkey = "ALT+F10"         # "" = no hotkey
library = "~/Videos/Klipp"
discord_limit_mb = 10      # 10 | 50 | 500
notifications = true
sound = true
```

After editing it by hand, run `klipp restart`. H.264 is the default because
Discord and every browser play it; HEVC and AV1 make smaller files but may not
preview in Discord.

## Good to know

**The hotkey.** The background service owns it, so it works with the library
closed and in fullscreen games. On Hyprland, Klipp adds a runtime bind with
`hyprctl` and puts it back after a `hyprctl reload`. Everywhere else it reads
the keyboard from `/dev/input`, which needs the `input` group
(`sudo usermod -aG input $USER`, then log in again). To pick a new hotkey,
click the hotkey row in the settings and press it; Klipp warns you if Hyprland
already uses it. Set it to nothing if you would rather bind `klipp save`
yourself.

**Game detection** asks Hyprland which window is active. On other compositors
every clip lands in *Desktop*.

**Where things live.**

| What | Where |
| --- | --- |
| Clips | `~/Videos/Klipp/<Game>/` |
| Discord exports | `~/Videos/Klipp/.discord/` |
| Settings | `~/.config/klipp/config.toml` |
| Favourites, folders | `~/.local/share/klipp/index.json` |
| Thumbnails | `~/.cache/klipp/thumbs/` |
| Logs | `journalctl --user -u klipp` |

Clips are plain MP4 files. Move, rename or delete them in your file manager
and the library shows it the next time you open it.

**Privacy.** No accounts, no telemetry, no network traffic. Clips leave your
computer only when you paste them somewhere.

**Instant replay stays off?** The last error from GPU Screen Recorder shows
under the switch, and `journalctl --user -u klipp -e` has the rest. If it says
*Waiting for the Wayland session*, your compositor didn't export its
environment to systemd. Hyprland does this itself; elsewhere, add
`dbus-update-activation-environment --systemd --all` to your autostart.

**Trimming and export** use NVENC when it works and fall back to x264 on the
CPU, which is slower.

## Credits

- [GPU Screen Recorder][gsr] by dec05eba does the recording.
- [FFmpeg][ffmpeg] for trimming, thumbnails and Discord exports.
- Built with [GTK 4][gtk] and [libadwaita][adw].

## AI disclosure

<img src="https://img.shields.io/badge/Built%20with-Claude-D97757?logo=claude&amp;logoColor=white" alt="Built with Claude">

Klipp was built by me together with Claude. I decide what goes in and test it
on my own setup; Claude writes most of the code, commits and documentation.

## License

[MIT](LICENSE) © 2026 Silvertree2010.

[gsr]: https://git.dec05eba.com/gpu-screen-recorder/about/
[ffmpeg]: https://ffmpeg.org/
[gtk]: https://www.gtk.org/
[adw]: https://gnome.pages.gitlab.gnome.org/libadwaita/
