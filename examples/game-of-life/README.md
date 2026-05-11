# Game of Life

Conway's Game of Life running on an `EditableImage`. Each cell is one
pixel; alive = white, dead = black. Demonstrates the read/simulate/write
loop with `WritePixelsBuffer`.

## What it shows

- A cellular automaton driven by `RunService.Heartbeat`.
- Double-buffering simulation state in two Lua tables.
- Writing a monochrome image by packing bytes into an RGBA buffer.

## Components

- **StarterGui.LifeGui** — `ScreenGui` host.
- **StarterGui.LifeGui.Canvas** — the `ImageLabel`.
- **StarterGui.LifeGui.Canvas.Simulate** — `LocalScript` that runs the
  simulation.

## Flow

1. Create the ScreenGui and ImageLabel.
2. Add the Simulate LocalScript with a 128×128 grid, random initial state.
3. Heartbeat steps the sim ~15 times/sec.
4. Playtest: watch gliders, oscillators, and still lifes emerge from noise.

## Assets

None.
