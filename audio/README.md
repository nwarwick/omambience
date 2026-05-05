# Audio files

omambience expects five OGG loops in this directory:

| Filename       | Notes                                                       |
|----------------|-------------------------------------------------------------|
| `rain.ogg`     | Light to medium rain. Avoid distinct thunder claps.         |
| `fire.ogg`     | Crackling fireplace or campfire.                            |
| `thunder.ogg`  | Distant rolling thunder. Avoid sharp peaks at the loop end. |
| `waves.ogg`    | Beach or ocean waves.                                       |
| `cafe.ogg`     | Coffee-shop ambience (chatter, clatter).                    |

The files **must be valid OGG Vorbis** and seamlessly loopable — mpv loops by
restarting from the top, so any audible discontinuity at the boundary will be
heard every cycle. 60–120 seconds is a comfortable length: short enough to
keep the file small, long enough that the seam isn't obvious.

## Where to find loops

These are good starting points for CC0 or permissively-licensed audio:

- [freesound.org](https://freesound.org) — filter to license CC0 1.0
- [pixabay.com/sound-effects](https://pixabay.com/sound-effects/) — Pixabay
  Content License (free for commercial and personal use)
- [SoundBible](https://soundbible.com) — many CC-Sampling+ and PD samples

Search terms that work well: `rain loop`, `fireplace ambience`,
`distant thunder`, `beach waves loop`, `coffee shop ambience`.

## Encoding to OGG

If your source is WAV or MP3, convert and trim to a clean loop with ffmpeg:

```sh
# 60 seconds, fade-in/out for a roughly seamless loop
ffmpeg -i source.wav -t 60 \
  -af "afade=t=in:st=0:d=2,afade=t=out:st=58:d=2" \
  -c:a libvorbis -q:a 5 \
  rain.ogg
```

For truly seamless loops, edit in Audacity (or similar) and crossfade the
start and end manually before exporting.

## Licenses

Whatever you commit here will inherit the repository's MIT license unless you
note otherwise. If you ship CC-BY tracks, add a `CREDITS.md` listing the
authors and source URLs.
