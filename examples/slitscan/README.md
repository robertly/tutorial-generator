# Slit-scan

Each row of the image samples a slightly different moment in time.
Produces the "time smeared along an axis" effect you see in slit-scan
photography.

## What it shows

- Per-row time offset — vertical position encodes elapsed time.
- A simple procedural scene (sine-wave colors) as the signal being
  smeared.
- `WritePixelsBuffer` once per frame.

## Components

- **StarterGui.SlitGui** — ScreenGui.
- **StarterGui.SlitGui.Canvas** — ImageLabel.
- **StarterGui.SlitGui.Canvas.Slitscan** — LocalScript.

## Flow

1. ScreenGui + ImageLabel.
2. Add the Slitscan LocalScript.
3. Playtest: watch bands flow across the image diagonally.

## Assets

None.
