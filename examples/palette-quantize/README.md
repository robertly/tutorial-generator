# Palette quantize

Reduce a colorful procedural gradient to a fixed 16-color palette
(DawnBringer 16, a popular pixel-art palette). Each pixel snaps to the
nearest palette entry by Euclidean distance in RGB.

## What it shows

- Defining a fixed palette as a table of `{r, g, b}` entries.
- Nearest-color lookup per pixel.
- The "retro game" look: smooth gradients become posterized color bands.

## Components

- **StarterGui.QuantizeGui** — ScreenGui.
- **StarterGui.QuantizeGui.Canvas** — ImageLabel.
- **StarterGui.QuantizeGui.Canvas.Quantize** — LocalScript.

## Flow

1. ScreenGui + ImageLabel.
2. Add the Quantize LocalScript with the DawnBringer 16 palette.
3. Playtest: gradient painted in 16 colors.

## Assets

None.
