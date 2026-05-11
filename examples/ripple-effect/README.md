# Ripple effect

Click anywhere in the image to send concentric ripples across the
surface. A 2D wave equation simulated on a pixel grid.

## What it shows

- A simple finite-difference wave simulation.
- Converting simulation values to RGBA color for display.
- Mouse-pixel coordinate conversion via `AbsolutePosition`/`AbsoluteSize`.

## Components

- **StarterGui.RippleGui** — ScreenGui host.
- **StarterGui.RippleGui.Canvas** — ImageLabel.
- **StarterGui.RippleGui.Canvas.Ripple** — LocalScript running the sim.

## Flow

1. ScreenGui + ImageLabel.
2. Add the Ripple LocalScript. Two height tables; each frame updates
   current from neighbors + previous, damped.
3. Clicks poke an impulse into the height field.
4. Playtest: click anywhere to send ripples.

## Assets

None.
