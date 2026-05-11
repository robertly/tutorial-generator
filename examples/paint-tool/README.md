# Paint tool

A one-color paintbrush. Click and drag to draw circles into an
`EditableImage`, building up strokes pixel by pixel.

## What it shows

- `EditableImage:DrawCircle` for brush stamps.
- Tracking drag state with `InputBegan` / `InputEnded` / `InputChanged`.
- Screen-to-pixel mapping via `AbsolutePosition`/`AbsoluteSize`.

## Components

- **StarterGui.PaintGui** — ScreenGui.
- **StarterGui.PaintGui.Canvas** — the ImageLabel canvas.
- **StarterGui.PaintGui.Canvas.Paint** — LocalScript that handles input
  and draws.

## Flow

1. ScreenGui + ImageLabel (white background).
2. Add the Paint LocalScript.
3. Playtest: drag the mouse across the canvas to paint.

## Assets

None.
