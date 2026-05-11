# Reaction-diffusion

Gray-Scott reaction-diffusion simulated on a pixel grid. Produces
organic, biological-looking spots and stripes that evolve forever.

## What it shows

- Two-field diffusion + local nonlinear reaction.
- Laplacian via 5-point stencil (neighbors − 4×self).
- Running multiple sim steps per displayed frame for speed.

## Components

- **StarterGui.RDGui** — ScreenGui.
- **StarterGui.RDGui.Canvas** — ImageLabel.
- **StarterGui.RDGui.Canvas.Simulate** — LocalScript.

## Flow

1. ScreenGui + ImageLabel.
2. Add the Simulate LocalScript — seeds a B-square in the middle of an
   A-sea, steps Gray-Scott each frame.
3. Playtest: watch spots emerge, split, and spread.

## Assets

None.
