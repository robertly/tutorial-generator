# Heightmap viewer

Generate a fractional Brownian motion (fBM) heightmap and render it as a
colored top-down map: water, shore, sand, grass, forest, rock, snow.
Looks like a procedural world map.

## What it shows

- `math.noise` summed across 5 octaves (classic fBM).
- Height-to-color lookup by banded thresholds.
- Cheap diagonal-slope shading.

## Components

- **StarterGui.HeightGui** — ScreenGui.
- **StarterGui.HeightGui.Canvas** — ImageLabel.
- **StarterGui.HeightGui.Canvas.Height** — LocalScript.

## Flow

1. ScreenGui + ImageLabel.
2. Add the Height LocalScript.
3. Playtest: a biome-colored map appears.

## Assets

None.
