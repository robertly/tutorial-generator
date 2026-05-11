# Minimap fog of war

A corner minimap whose fog layer starts fully black and is "erased" with
a transparent circle everywhere the player has been.

## What it shows

- Using `EditableImage` as an alpha mask (fog layer).
- `DrawCircle` with `transparency = 1` + `ImageCombineType.Overwrite` to
  punch holes in a mask.
- Mapping world position to pixel coordinates.

## Components

- **StarterGui.MinimapGui** — ScreenGui.
- **StarterGui.MinimapGui.Frame** — map background (placeholder Frame).
- **StarterGui.MinimapGui.Frame.Fog** — the fog overlay ImageLabel.
- **StarterGui.MinimapGui.Frame.Fog.Reveal** — LocalScript that erases fog.

## Flow

1. ScreenGui + Frame background + Fog ImageLabel.
2. Reveal script tracks the player's position and erases a circle.
3. Playtest: walk around, fog clears where you've been.

## Assets

None.
