#!/usr/bin/env bash
# Install Klipp (Arch Linux, per user, root only for packages)
#   ./install.sh            install / update
#   ./install.sh --remove   uninstall (clips are kept)
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB="$HOME/.local/lib/klipp"
BIN="$HOME/.local/bin/klipp"
APPS="$HOME/.local/share/applications"
ICONS="$HOME/.local/share/icons/hicolor/scalable/apps"
UNIT="$HOME/.config/systemd/user/klipp.service"
DEPS=(gpu-screen-recorder python python-gobject gtk4 libadwaita gst-plugins-good
      gst-libav ffmpeg wl-clipboard libnotify pipewire)

say() { printf '\033[1;35m::\033[0m %s\n' "$*"; }

if [[ "${1:-}" == "--remove" ]]; then
  systemctl --user disable --now klipp.service 2>/dev/null || true
  rm -rf "$LIB" "$BIN" "$UNIT" "$APPS/dev.klipp.Klipp.desktop" "$ICONS/dev.klipp.Klipp.svg"
  systemctl --user daemon-reload
  say "Klipp removed. Your clips and settings are still in ~/Videos/Klipp and ~/.config/klipp."
  exit 0
fi

missing=()
for p in "${DEPS[@]}"; do pacman -Qq "$p" &>/dev/null || missing+=("$p"); done
if ((${#missing[@]})); then
  say "Missing packages: ${missing[*]}"
  if ! sudo pacman -S --needed --noconfirm "${missing[@]}"; then
    echo "Could not install the packages. Run 'sudo pacman -Syu' first, then try again." >&2
    exit 1
  fi
fi

say "Copying Klipp to $LIB"
rm -rf "$LIB"
mkdir -p "$LIB" "$(dirname "$BIN")" "$APPS" "$ICONS" "$(dirname "$UNIT")"
cp -r "$SRC/klipp" "$LIB/"
find "$LIB" -name __pycache__ -prune -exec rm -rf {} +

cat > "$BIN" <<EOF
#!/bin/sh
export PYTHONPATH="$LIB\${PYTHONPATH:+:\$PYTHONPATH}"
exec /usr/bin/python3 -m klipp "\$@"
EOF
chmod +x "$BIN"

install -m644 "$SRC/data/dev.klipp.Klipp.desktop" "$APPS/"
sed -i "s|^Exec=klipp|Exec=$BIN|" "$APPS/dev.klipp.Klipp.desktop"
install -m644 "$SRC/data/dev.klipp.Klipp.svg" "$ICONS/"
install -m644 "$SRC/data/klipp.service" "$UNIT"
update-desktop-database "$APPS" &>/dev/null || true
gtk-update-icon-cache -q "$HOME/.local/share/icons/hicolor" &>/dev/null || true

say "Starting instant replay (it now starts automatically at login)"
systemctl --user daemon-reload
systemctl --user enable klipp.service &>/dev/null
systemctl --user restart klipp.service

sleep 2
"$BIN" status || true
say "Done. Open Klipp from your app launcher and press Alt+F10 in a game (you can change the hotkey in the settings)."
