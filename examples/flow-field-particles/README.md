# Flow field particles

500 particles drift through a time-varying procedural vector field,
leaving fading trails. Pure painterly motion.

## What it shows

- Computing a vector field from simple trig.
- Accumulating trails by fading the canvas instead of clearing it.
- `ReadPixelsBuffer` + `WritePixelsBuffer` round-trip for per-pixel
  effects.

## Components

- **StarterGui.FlowGui** — ScreenGui.
- **StarterGui.FlowGui.Canvas** — ImageLabel.
- **StarterGui.FlowGui.Canvas.Flow** — LocalScript.

## Flow

1. ScreenGui + ImageLabel.
2. Add the Flow LocalScript.
3. Playtest: trails swirl across the canvas.

## Assets

None.
