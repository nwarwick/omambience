# omambience

A simple ambient noise mixer for [Omarchy](https://omarchy.org) / Hyprland
setups. Toggle rain, fire, thunder, waves, and cafe loops with a keybind, mix
them however you like, see what's playing in Waybar.

- One key per sound — toggle on/off (`SUPER+ALT+1` through `SUPER+ALT+5`)
- One key to stop everything (`SUPER+ALT+0`)
- Mix freely — multiple sounds play at once, each with its own volume
- Per-sound volumes persist between toggles
- Waybar module that hides itself when nothing is playing

Built on `mpv` — one detached instance per sound, mixed by PipeWire.

## Requirements

- `mpv` (audio engine; one instance per active sound)
- `socat` (talks to mpv's IPC socket for live volume changes)
- `waybar`
- Hyprland

On Arch:

```sh
pacman -S mpv socat waybar
```

## Install

```sh
git clone https://github.com/nwarwick/omambience.git
cd omambience
./install.sh
```

The installer will:

- Drop `omambience-toggle`, `omambience-volume`, `omambience-stop-all`, and
  `omambience-status` into `~/.local/bin/`
- Copy audio files to `~/.local/share/omambience/audio/` (only if that dir is
  empty — won't clobber your customizations)
- Write `~/.config/hypr/omambience.conf` with default keybindings (only if you
  don't already have one) and tell you the `source = ...` line to add to
  `hyprland.conf`
- Print the Waybar JSONC + CSS snippets you need to paste by hand

## Audio files

The repository ships with two seamless OGG loops in `audio/` (`rain.ogg` and
`fire.ogg`). These are **licensed separately from the code** — see
[`CREDITS.md`](CREDITS.md) for sources and terms. Notably, `fire.ogg` is
CC BY-NC 3.0, so commercial use of the bundled fire loop is not permitted;
swap it for a CC0 alternative if you need commercial-friendly audio.

To swap in your own files (or add `thunder.ogg`, `waves.ogg`, `cafe.ogg`),
drop OGG loops named after the sound into `~/.local/share/omambience/audio/`.
See `audio/README.md` for sourcing recommendations.

## Keybindings

| Keys                    | Action                              |
|-------------------------|-------------------------------------|
| `SUPER+ALT+1..5`        | Toggle rain/fire/thunder/waves/cafe |
| `SUPER+ALT+0`           | Stop all sounds                     |
| `SUPER+CTRL+1..5`       | Raise that sound's volume by 5      |
| `SUPER+CTRL+SHIFT+1..5` | Lower that sound's volume by 5      |

Volume binds use `binde` so they auto-repeat while held — hold to ramp.
The `SUPER+CTRL` combos are deliberately chosen to dodge Omarchy's default
`SUPER+SHIFT+N` and `SUPER+SHIFT+ALT+N` binds, which move windows to
workspace N.

The Waybar module is always visible (a single `♫` icon, dimmed when nothing
is playing). When two or more sounds are active, the count is appended
(e.g. `♫ 3`). Hover for the full readout — every available sound, its
on/off state (`●` / `○`), a 10-cell volume bar, and the percent.

| Mouse      | Action          |
|------------|-----------------|
| Left click | Stop all sounds |

## Adjusting volume

Per-sound volume is controlled from the CLI:

```sh
omambience-volume rain 60      # set rain to 60
omambience-volume fire +10     # raise fire by 10
omambience-volume cafe -5      # lower cafe by 5
```

Volume is clamped to `[0, 130]`. Values above 100 use mpv's soft amplification;
go easy. The new value is applied live to the running sound (if any) and
persisted, so the next time you toggle the sound on it starts at this level.
The current per-sound levels are visible at a glance in the Waybar tooltip.

## Adding or renaming sounds

The five default sound names are wired into the Hyprland snippet and the
audio filenames the installer copies, but the scripts themselves are
sound-agnostic — they operate on whatever name you pass. To add a sixth sound:

1. Drop `<name>.ogg` into `~/.local/share/omambience/audio/`
2. Add a keybinding to `~/.config/hypr/omambience.conf`:
   `bindd = SUPER ALT, 6, Toggle <name>, exec, $HOME/.local/bin/omambience-toggle <name>`
3. Reload Hyprland: `hyprctl reload`

The Waybar module enumerates all currently-playing sounds automatically, so it
picks up new sounds the moment you first toggle them.

## How it works

Each sound runs as a detached `mpv` instance with `--loop --no-config
--input-ipc-server=$XDG_STATE_HOME/omambience/<sound>.sock`. The socket is the
source of truth for "is this sound playing?" — `omambience-toggle` checks for
a running mpv bound to that socket. PipeWire combines the streams; that's the
mixing.

Volume changes are written to mpv via the IPC socket using `socat`, so they
take effect live without restarting the sound. Per-sound volumes are persisted
to `~/.local/state/omambience/<sound>.volume` and re-applied on the next toggle.

## Uninstall

```sh
./uninstall.sh
```

Stops any running sounds, removes the scripts, removes the Hyprland snippet.
Leaves audio files in `~/.local/share/omambience/`, persisted volumes in
`~/.local/state/omambience/`, and Waybar edits in place — those may have been
customized.

## License

Code: MIT (see [`LICENSE`](LICENSE)).

Bundled audio files: separately licensed, see [`CREDITS.md`](CREDITS.md).
