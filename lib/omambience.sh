#!/usr/bin/env bash

# Shared helpers for the Omambience command-line tools.

omambience_root="${OMAMBIENCE_ROOT:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"
omambience_data_dir="${XDG_DATA_HOME:-$HOME/.local/share}/omambience"
omambience_state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/omambience"
omambience_user_audio_dir="$omambience_data_dir/audio"
omambience_bundled_audio_dir="$omambience_root/audio"
readonly omambience_max_volume=100

omambience_validate_sound() {
  local sound="${1:-}"
  [[ $sound =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ && $sound != *..* ]]
}

omambience_require_sound() {
  local sound="${1:-}"
  if ! omambience_validate_sound "$sound"; then
    printf 'Invalid sound name: %s\n' "${sound:-<empty>}" >&2
    return 1
  fi
}

omambience_prepare_state() {
  umask 077
  mkdir -p -- "$omambience_state_dir"
}

omambience_audio_file() {
  local sound="$1"
  local candidate

  for candidate in \
    "$omambience_user_audio_dir/$sound.ogg" \
    "$omambience_bundled_audio_dir/$sound.ogg"; do
    if [[ -f $candidate ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  return 1
}

omambience_playback_gain() {
  local sound="$1"
  local audio_file="$2"

  # These gains bring the bundled loops to approximately -30 LUFS without
  # re-encoding them. User overrides retain their source level because their
  # loudness is unknown.
  if [[ $audio_file != "$omambience_bundled_audio_dir/$sound.ogg" ]]; then
    printf '0\n'
    return 0
  fi

  case "$sound" in
    cafe) printf '19.3\n' ;;
    fire) printf '3.6\n' ;;
    rain) printf '%s\n' '-9.1' ;;
    stream) printf '9.5\n' ;;
    thunder) printf '%s\n' '-3.1' ;;
    waves) printf '6.4\n' ;;
    *) printf '0\n' ;;
  esac
}

omambience_sound_names() {
  local directory file sound
  local -A seen=()
  local -a keyed_sounds=(rain fire thunder waves cafe)

  for directory in "$omambience_user_audio_dir" "$omambience_bundled_audio_dir"; do
    [[ -d $directory ]] || continue
    shopt -s nullglob
    for file in "$directory"/*.ogg; do
      sound="${file##*/}"
      sound="${sound%.ogg}"
      if omambience_validate_sound "$sound"; then
        seen["$sound"]=1
      fi
    done
    shopt -u nullglob
  done

  ((${#seen[@]} > 0)) || return 0
  for sound in "${keyed_sounds[@]}"; do
    if [[ -n ${seen[$sound]+present} ]]; then
      printf '%s\n' "$sound"
      unset 'seen[$sound]'
    fi
  done

  ((${#seen[@]} > 0)) || return 0
  printf '%s\n' "${!seen[@]}" | LC_ALL=C sort
}

omambience_pid_file() {
  printf '%s/%s.pid\n' "$omambience_state_dir" "$1"
}

omambience_socket_file() {
  printf '%s/%s.sock\n' "$omambience_state_dir" "$1"
}

omambience_volume_file() {
  printf '%s/%s.volume\n' "$omambience_state_dir" "$1"
}

omambience_lock_file() {
  printf '%s/%s.lock\n' "$omambience_state_dir" "$1"
}

omambience_read_volume() {
  local sound="$1"
  local volume_file value

  volume_file="$(omambience_volume_file "$sound")"
  value=100
  if [[ -f $volume_file ]]; then
    read -r value <"$volume_file" || value=100
    [[ $value =~ ^[0-9]{1,3}$ ]] || value=100
  fi

  value=$((10#$value))
  ((value < 0)) && value=0
  ((value > omambience_max_volume)) && value=$omambience_max_volume
  printf '%s\n' "$value"
}

omambience_pid_owns_socket() {
  local pid="$1"
  local socket="$2"
  local argument

  [[ $pid =~ ^[0-9]+$ && -r /proc/$pid/cmdline ]] || return 1
  while IFS= read -r -d '' argument; do
    [[ $argument == "--input-ipc-server=$socket" ]] && return 0
  done <"/proc/$pid/cmdline"

  return 1
}

omambience_running_pid() {
  local sound="$1"
  local pid_file socket pid

  pid_file="$(omambience_pid_file "$sound")"
  socket="$(omambience_socket_file "$sound")"
  [[ -f $pid_file ]] || return 1
  read -r pid <"$pid_file" || return 1

  if omambience_pid_owns_socket "$pid" "$socket"; then
    printf '%s\n' "$pid"
    return 0
  fi

  rm -f -- "$pid_file" "$socket"
  return 1
}

omambience_stop_sound() {
  local sound="$1"
  local pid_file socket pid attempt

  pid_file="$(omambience_pid_file "$sound")"
  socket="$(omambience_socket_file "$sound")"
  if pid="$(omambience_running_pid "$sound")"; then
    kill "$pid" 2>/dev/null || true
    for ((attempt = 0; attempt < 20; attempt++)); do
      omambience_pid_owns_socket "$pid" "$socket" || break
      sleep 0.025
    done
    if omambience_pid_owns_socket "$pid" "$socket"; then
      kill -KILL "$pid" 2>/dev/null || true
    fi
  fi
  rm -f -- "$pid_file" "$socket"
}
