# Starfield

Classic screensaver: 200 stars rushing toward the camera with perspective
projection. Each star gets brighter and bigger as it approaches.

## What it shows

- Simple 3D→2D perspective projection (`screen = world / z`).
- Recycling particles when they pass the camera.
- Using `DrawRectangle` as a full-canvas clear each frame.

## Components

- **StarterGui.StarfieldGui** — ScreenGui.
- **StarterGui.StarfieldGui.Canvas** — ImageLabel.
- **StarterGui.StarfieldGui.Canvas.Starfield** — LocalScript.

## Flow

1. ScreenGui + ImageLabel.
2. Add the Starfield LocalScript.
3. Playtest: stars fly past forever.

## Assets

None.
