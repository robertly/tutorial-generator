# Surface canvas

A Part you can paint on in 3D space. Mouse-over the part to draw colored
strokes onto its front face. Uses a `SurfaceGui` with an `ImageLabel`
backed by an `EditableImage`.

## What it shows

- Binding an `EditableImage` to a `SurfaceGui.ImageLabel`.
- Mapping the player's mouse position (via `Mouse.Target`) to pixel
  coords on the surface.
- Cycling colors with `Color3.fromHSV(tick() % 1, …)`.

## Components

- **Workspace.Canvas** — anchored Part, flat and wall-shaped.
- **Workspace.Canvas.SurfaceGui** — `SurfaceGui` facing front.
- **Workspace.Canvas.SurfaceGui.Image** — ImageLabel, full size.
- **Workspace.Canvas.SurfaceGui.Image.Paint** — LocalScript handling input.

## Flow

1. Create the Canvas Part.
2. Add a SurfaceGui on its front face.
3. Add the ImageLabel that fills the SurfaceGui.
4. Add the Paint LocalScript.
5. Playtest: walk up to the Part and click/drag to paint.

## Assets

None.
