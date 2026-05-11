# Plasma effect

Classic demoscene plasma: overlapping sine waves modulated by time, mapped
to an HSV-ish RGB palette. Animates forever.

## What it shows

- Writing animated pixel data each frame via `WritePixelsBuffer`.
- Combining sines of `x`, `y`, `x+y`, and radial distance to produce the
  plasma field.
- Converting a scalar field to color via offset sines per channel.

## Components

- **StarterGui.PlasmaGui** — ScreenGui.
- **StarterGui.PlasmaGui.Canvas** — ImageLabel.
- **StarterGui.PlasmaGui.Canvas.Plasma** — LocalScript.

## Flow

1. ScreenGui + ImageLabel.
2. Add the Plasma LocalScript — sine fields summed, channel-offset palette.
3. Playtest: watch the colors swirl.

## Assets

None.
