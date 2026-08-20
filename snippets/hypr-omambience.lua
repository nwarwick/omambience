-- Omambience controls for Omarchy Quattro.
-- Paste this into ~/.config/hypr/bindings.lua, which Omarchy loads after its
-- defaults. The number-key codes keep the bindings keyboard-layout independent.

local ambience = { "rain", "fire", "thunder", "waves", "cafe" }

for index, sound in ipairs(ambience) do
  local key = "code:" .. tostring(index + 9)

  -- Omarchy uses SUPER+ALT+1..5 for group-window selection by default.
  hl.unbind("SUPER + ALT + " .. key)
  hl.unbind("SUPER + CTRL + " .. key)
  hl.unbind("SUPER + CTRL + SHIFT + " .. key)

  o.bind(
    "SUPER + ALT + " .. key,
    "Toggle " .. sound,
    "omarchy-shell nwarwick.omambience toggle " .. sound
  )
  o.bind(
    "SUPER + CTRL + " .. key,
    "Raise " .. sound .. " volume",
    "omarchy-shell nwarwick.omambience volume " .. sound .. " +5",
    { repeating = true }
  )
  o.bind(
    "SUPER + CTRL + SHIFT + " .. key,
    "Lower " .. sound .. " volume",
    "omarchy-shell nwarwick.omambience volume " .. sound .. " -5",
    { repeating = true }
  )
end

hl.unbind("SUPER + ALT + code:19")
o.bind(
  "SUPER + ALT + code:19",
  "Stop all ambient sounds",
  "omarchy-shell nwarwick.omambience stopAll"
)
