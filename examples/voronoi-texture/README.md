# Voronoi texture

Generate a stained-glass / cell-pattern texture: each pixel takes the
color of its nearest seed point, with a shaded falloff near cell centers.

## What it shows

- Classic Voronoi diagram implementation.
- Per-pixel nearest-neighbor search with early-exit not needed at this size.
- A cheap center-shade trick to visualize the underlying distance field.

## Components

- **StarterGui.VoronoiGui** — ScreenGui.
- **StarterGui.VoronoiGui.Canvas** — ImageLabel.
- **StarterGui.VoronoiGui.Canvas.Voronoi** — LocalScript.

## Flow

1. ScreenGui + ImageLabel.
2. Add the Voronoi LocalScript — pick random seeds, render nearest-color.
3. Playtest: new random pattern each run.

## Assets

None.
