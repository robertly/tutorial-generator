# SDF shapes

Three animated 2D signed-distance-field shapes (two circles, one box)
smoothly blended into a single blob with metaball-like fusion. Edges are
highlighted with a thin ring.

## What it shows

- SDF primitives: circle and box.
- `smin` — a C∞ smooth-minimum that fuses two SDFs rather than clipping
  them together.
- Using the SDF value (`d`) for both fill and edge detection.

## Components

- **StarterGui.SDFGui** — ScreenGui.
- **StarterGui.SDFGui.Canvas** — ImageLabel.
- **StarterGui.SDFGui.Canvas.SDF** — LocalScript.

## Flow

1. ScreenGui + ImageLabel.
2. Add the SDF LocalScript.
3. Playtest: watch three shapes orbit and merge.

## Assets

None.
