# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

An ambient-noise mixer for Hyprland/Omarchy. Pure bash + config snippets —
no build, no test suite, no linter. Intentionally modeled on the sister
project [`omadoro`](../omadoro): four tiny scripts in `bin/`, an `install.sh`
that drops them into `~/.local/bin`, plus Hyprland and Waybar snippets.

## Commands

- `./install.sh` — copies `bin/*` to `~/.local/bin/`, copies `audio/*.ogg` to
  `~/.local/share/omambience/audio/` (only if that dir is empty), drops
  `snippets/hypr-omambience.conf` into `~/.config/hypr/`, and prints the
  Waybar snippets to paste manually. Checks for `mpv`, `socat`, `waybar` and
  exits if any are missing.
- `./uninstall.sh` — stops any running sounds, removes the installed scripts
  and Hyprland snippet. Deliberately leaves audio files, persisted volumes,
  and Waybar edits in place because they may have been customized.
- `shellcheck bin/* install.sh uninstall.sh` — run before changes if available;
  no CI but scripts use `set -euo pipefail` and should stay shellcheck-clean.
- After editing scripts, re-run `./install.sh` to pick up changes (it
  overwrites `bin/*` unconditionally, but never the audio files).

## Architecture

Four small bash scripts in `bin/` orchestrate detached `mpv` instances — one
per active sound. Mixing happens for free at the PipeWire layer.

- **`omambience-toggle <sound>`** — start/stop one sound. Detection: `pgrep
  -f "--input-ipc-server=$SOCK"` (the leading `--` is intentional — it keeps
  the matcher from picking up unrelated processes that mention the socket
  path, like a shell that just `cat`-ed it). Start: `setsid -f mpv
  --no-config --no-video --no-terminal --loop --volume=$VOL
  --input-ipc-server=$SOCK $FILE`. Stop: `pkill` against the same pattern,
  then `rm -f $SOCK` to clean up the leftover socket node.
- **`omambience-volume <sound> <value|+N|-N>`** — clamp to `[0, 130]`, persist
  the new value to `$STATE_DIR/<sound>.volume`, and (if the sound is currently
  playing) push it live to mpv via `socat - UNIX-CONNECT:$SOCK` with a JSON
  IPC command (`{"command":["set_property","volume",N]}`).
- **`omambience-stop-all`** — iterates `*.sock` in the state dir, `pkill`s
  each running mpv, removes the sockets. Volumes are preserved.
- **`omambience-status`** — long-running Waybar producer. Loops every 1s
  emitting JSON. Empty `{"text":""}` when nothing is playing so Waybar hides
  the module.

### Path conventions

- Audio files: `${XDG_DATA_HOME:-$HOME/.local/share}/omambience/audio/<sound>.ogg`
- IPC sockets: `${XDG_STATE_HOME:-$HOME/.local/state}/omambience/<sound>.sock`
- Persisted volumes: `${XDG_STATE_HOME:-$HOME/.local/state}/omambience/<sound>.volume`

The state dir doubles as a registry of "known sounds" — anything with a
`.sock` (live or stale) has been toggled at least once. `omambience-status`
enumerates `*.sock` and filters to those with a live mpv.

### Why mpv (and not paplay/mpg123/etc.)

mpv is the only common player that gives us a per-instance JSON IPC socket
for live property changes. That's how `omambience-volume` adjusts a running
sound without restarting it. Other engines either lack live volume control or
require shimming through PipeWire's `pw-cli`, which is per-stream and brittle.

### Why one mpv per sound

Mixing inside a single mpv is awkward (multiple loaded files + per-track
volume via lavfi — fragile). One process per sound is dead simple, lets each
sound have its own IPC socket and volume, and PipeWire handles the actual
mixing transparently.

### Why socat (not nc)

`socat` is the portable way to talk to a Unix socket from bash. `nc -U` works
on netcat-openbsd but not netcat-traditional, and Unix-socket support has
historically been flaky. socat is widely available on Arch and a hard
dependency.

## Install surfaces (and why they differ)

- `~/.local/bin/omambience-*` — overwritten on every `install.sh` run.
- `~/.local/share/omambience/audio/` — preserved if non-empty. Wipe the
  directory to force a refresh.
- `~/.config/hypr/omambience.conf` — preserved if present. The user must add
  `source = ~/.config/hypr/omambience.conf` to `hyprland.conf` themselves;
  `install.sh` only checks for it and prints the line.
- Waybar (`config.jsonc` + `style.css`) — never auto-edited. The installer
  prints the snippets for manual paste because merging JSONC/CSS without
  breaking the user's existing config isn't safe.

## Conventions

- All scripts use `#!/bin/bash` and (where practical) `set -euo pipefail`. The
  long-running `omambience-status` deliberately omits `set -e` so a transient
  glob/read error doesn't kill the Waybar producer.
- Scripts must be idempotent and safe to run when no mpv is running. Most
  cleanup paths swallow errors with `2>/dev/null` and `|| true`.
- Keep the Waybar JSON output single-line per tick; Waybar parses
  line-by-line.
- The default sound names — `rain`, `fire`, `thunder`, `waves`, `cafe` — are
  hardcoded in `snippets/hypr-omambience.conf` and matched by the audio
  filenames the installer copies. The scripts themselves are sound-agnostic;
  any user can rename or extend the set by editing the snippet and dropping
  matching `.ogg` files into the data dir.
