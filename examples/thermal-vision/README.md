# Thermal vision

Render a procedural heat field with moving "heat sources" and map intensity
through a jet-like palette (blue → green → yellow → red). Looks like a
thermal camera.

## What it shows

- A scalar field computed per pixel (inverse distance to two moving
  sources).
- Mapping intensity through a palette function to get the thermal look.
- Animating everything via `RunService.Heartbeat`.

## Components

- **StarterGui.ThermalGui** — ScreenGui.
- **StarterGui.ThermalGui.Canvas** — ImageLabel.
- **StarterGui.ThermalGui.Canvas.Thermal** — LocalScript.

## Flow

1. ScreenGui + ImageLabel.
2. Add the Thermal LocalScript.
3. Playtest: watch two heat sources orbit.

## Assets

None.
