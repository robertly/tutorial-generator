# Posterize filter

Animated radial ripple, then posterize each channel to 4 levels. Produces
chunky flat-color bands instead of smooth gradients — the classic print /
silk-screen look.

## What it shows

- Per-channel quantization to N levels (snap to nearest step).
- Running a filter each frame so it still animates under the effect.

## Components

- **StarterGui.PosterizeGui** — ScreenGui.
- **StarterGui.PosterizeGui.Canvas** — ImageLabel.
- **StarterGui.PosterizeGui.Canvas.Posterize** — LocalScript.

## Flow

1. ScreenGui + ImageLabel.
2. Add the Posterize LocalScript.
3. Playtest: watch animated concentric bands with only 4 shades per
   channel.

## Assets

None.
