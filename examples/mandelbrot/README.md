# Mandelbrot viewer

Render the Mandelbrot set to an `EditableImage` pixel-by-pixel, then let the
user click to zoom into the point they clicked. Shows raw pixel throughput
via `WritePixelsBuffer` and the click-to-zoom interaction pattern.

## What it shows

- `AssetService:CreateEditableImage` with a fixed `Size`.
- `EditableImage:WritePixelsBuffer` from a `buffer` of RGBA bytes.
- Binding an `EditableImage` to `ImageLabel.ImageContent` via `Content.fromObject`.
- `ImageLabel.InputBegan` for click-to-zoom input.

## Components

- **StarterGui.MandelbrotGui** — `ScreenGui` host, `ResetOnSpawn` off.
- **StarterGui.MandelbrotGui.Canvas** — the `ImageLabel` we render into.
- **StarterGui.MandelbrotGui.Canvas.Render** — `LocalScript` that builds
  the `EditableImage`, renders the fractal, and handles clicks.

## Flow

1. Create a `ScreenGui` in `StarterGui`.
2. Add a centered square `ImageLabel` as the canvas.
3. Add a `LocalScript` that renders the fractal and zooms on click.
4. Playtest: click anywhere in the image to zoom by 2× at that point.

## Assets

None.
