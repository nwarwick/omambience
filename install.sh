#!/bin/bash
# Installer for omambience.
# Copies scripts, audio files, and the Hyprland keybinding snippet into place.
# Prints the waybar pieces for manual paste — JSONC and CSS can't be merged
# safely without risking the user's existing config.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

BIN_DIR="${HOME}/.local/bin"
DATA_DIR="${HOME}/.local/share/omambience"
HYPR_DIR="${HOME}/.config/hypr"

bold()  { printf '\033[1m%s\033[0m\n' "$*"; }
warn()  { printf '\033[33m! %s\033[0m\n' "$*"; }
info()  { printf '  %s\n' "$*"; }
ok()    { printf '\033[32m✓ %s\033[0m\n' "$*"; }

check_dep() {
  if ! command -v "$1" >/dev/null 2>&1; then
    warn "Missing dependency: $1"
    return 1
  fi
}

bold "Checking dependencies"
missing=0
for dep in mpv socat waybar; do
  check_dep "$dep" || missing=1
done
if [ "$missing" -eq 1 ]; then
  warn "Install missing packages and re-run. On Arch:  pacman -S mpv socat waybar"
  exit 1
fi
ok "All dependencies present"
echo

bold "Installing scripts to ${BIN_DIR}"
mkdir -p "$BIN_DIR"
install -m 755 "${REPO_DIR}/bin/omambience-toggle"   "${BIN_DIR}/omambience-toggle"
install -m 755 "${REPO_DIR}/bin/omambience-volume"   "${BIN_DIR}/omambience-volume"
install -m 755 "${REPO_DIR}/bin/omambience-stop-all" "${BIN_DIR}/omambience-stop-all"
install -m 755 "${REPO_DIR}/bin/omambience-status"   "${BIN_DIR}/omambience-status"
ok "Scripts installed"
echo

bold "Installing audio files to ${DATA_DIR}/audio"
shopt -s nullglob
audio_files=("${REPO_DIR}"/audio/*.ogg)
shopt -u nullglob
if [ "${#audio_files[@]}" -eq 0 ]; then
  warn "No .ogg files found in ${REPO_DIR}/audio"
  info "Drop OGG loops named rain.ogg, fire.ogg, thunder.ogg, waves.ogg, cafe.ogg"
  info "into ${REPO_DIR}/audio/ and re-run this installer."
  info "See ${REPO_DIR}/audio/README.md for sourcing recommendations."
  exit 1
fi

if [ -d "${DATA_DIR}/audio" ] && [ -n "$(ls -A "${DATA_DIR}/audio" 2>/dev/null)" ]; then
  warn "${DATA_DIR}/audio is non-empty — leaving existing files in place"
  info "(Delete the directory and re-run if you want fresh files.)"
else
  mkdir -p "${DATA_DIR}/audio"
  install -m 644 "${audio_files[@]}" "${DATA_DIR}/audio/"
  ok "Installed ${#audio_files[@]} audio file(s)"
fi
echo

bold "Installing Hyprland keybindings"
mkdir -p "$HYPR_DIR"
HYPR_DEST="${HYPR_DIR}/omambience.conf"
if [ -f "$HYPR_DEST" ]; then
  warn "${HYPR_DEST} already exists — leaving it untouched"
else
  install -m 644 "${REPO_DIR}/snippets/hypr-omambience.conf" "$HYPR_DEST"
  ok "Wrote ${HYPR_DEST}"
fi
SOURCE_LINE="source = ~/.config/hypr/omambience.conf"
if grep -Fq "$SOURCE_LINE" "${HYPR_DIR}/hyprland.conf" 2>/dev/null; then
  ok "hyprland.conf already sources omambience.conf"
else
  warn "Add this line to ~/.config/hypr/hyprland.conf:"
  info "    ${SOURCE_LINE}"
  info "Then run:  hyprctl reload"
fi
echo

bold "Waybar — manual steps required"
info "Waybar uses JSONC and CSS, which can't be merged automatically without"
info "risking your existing config. Add the snippets below by hand."
echo
info "1. Paste the module block from:"
info "     ${REPO_DIR}/snippets/waybar-module.jsonc"
info "   into the top-level object of ~/.config/waybar/config.jsonc"
echo
info "2. Add \"custom/omambience\" to one of the modules arrays (modules-left/center/right)"
echo
info "3. Append the styles from:"
info "     ${REPO_DIR}/snippets/waybar-style.css"
info "   to ~/.config/waybar/style.css"
echo
info "4. Reload waybar:  pkill waybar && waybar &"
echo

bold "Done."
info "Press SUPER+ALT+1 to toggle rain. SUPER+ALT+0 stops everything."
