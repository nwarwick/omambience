#!/bin/bash
# Uninstaller for omambience.
# Stops any running sounds, removes the scripts, removes the Hyprland snippet.
# Leaves audio files and persisted volumes alone — those may have been
# customized — and leaves Waybar edits to the user.

set -euo pipefail

bold()  { printf '\033[1m%s\033[0m\n' "$*"; }
info()  { printf '  %s\n' "$*"; }
ok()    { printf '\033[32m✓ %s\033[0m\n' "$*"; }

bold "Stopping any running sounds"
if [ -x "${HOME}/.local/bin/omambience-stop-all" ]; then
  "${HOME}/.local/bin/omambience-stop-all" || true
fi
ok "Done"
echo

bold "Removing scripts"
rm -f "${HOME}/.local/bin/omambience-toggle"
rm -f "${HOME}/.local/bin/omambience-volume"
rm -f "${HOME}/.local/bin/omambience-stop-all"
rm -f "${HOME}/.local/bin/omambience-status"
ok "Scripts removed"
echo

bold "Removing Hyprland snippet"
rm -f "${HOME}/.config/hypr/omambience.conf"
ok "omambience.conf removed"
info "Remember to delete the matching 'source = ...' line from hyprland.conf"
echo

bold "Manual cleanup still required"
info "  • ~/.local/share/omambience/ (audio files, kept in case customized)"
info "  • ~/.local/state/omambience/ (saved per-sound volumes)"
info "  • Waybar module + CSS in ~/.config/waybar/{config.jsonc,style.css}"
