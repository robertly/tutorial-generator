# Procedural brick texture

Generate a brick pattern in an `EditableImage` at runtime and apply it to
a Part via `SurfaceAppearance.ColorMap`. No asset uploads — the texture
is built in-game.

## What it shows

- Drawing patterns with `DrawRectangle` to build a tileable texture.
- Running-bond layout via per-row offset.
- Applying an EditableImage as a `SurfaceAppearance` color map.

## Components

- **Workspace.BrickWall** — the anchored Part we're texturing.
- **Workspace.BrickWall.Texture** — server Script that draws the texture
  and creates a SurfaceAppearance under the Part.

## Flow

1. Create a wall-shaped anchored Part.
2. Add the Texture server Script.
3. Playtest: the wall gets a randomized brick texture.

## Assets

None.
