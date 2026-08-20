# Omambience contributor notes

Omambience is an Omarchy Quattro shell plugin. The root `manifest.json`
registers `BarWidget.qml` as `nwarwick.omambience`; Waybar and legacy Hyprland
configuration are out of scope.

The Bash commands in `bin/` share path, validation, process-ownership, and
audio-discovery helpers from `lib/omambience.sh`. User audio under
`$XDG_DATA_HOME/omambience/audio` overrides bundled audio. Runtime state lives
under `$XDG_STATE_HOME/omambience`.

Run `./tests/test` after changes. On Quattro, also run
`omarchy plugin validate .`. Keep the Lua snippet aligned with the IPC methods
in `BarWidget.qml`.
