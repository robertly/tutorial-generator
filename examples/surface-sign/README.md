# Surface sign

Put a readable sign on a Part using SurfaceGui + TextLabel. Five minutes;
shows how 3D-world UI works in Roblox without any scripts at all.

## What it shows

- `SurfaceGui` — a container that renders 2D UI on a chosen Face of a Part.
- `TextLabel` — standard GUI text element, same as in a ScreenGui.
- Nested instance creation: Part → SurfaceGui → TextLabel.
- `SurfaceGui.Face` and how it picks which side of the part to draw on.

## Components

- **Workspace.SignPost** — an anchored Part acting as the billboard body.
- **Workspace.SignPost.Display** — the `SurfaceGui` drawing on the front face.
- **Workspace.SignPost.Display.Headline** — the `TextLabel` with the sign text.

## Flow

1. Create the SignPost part in Workspace.
2. Add a SurfaceGui as a child, facing Front.
3. Add a TextLabel inside the SurfaceGui that fills it and shows the headline.
4. Suggest asking Assistant to make it pulse or scroll.

## Assets

None — this lesson uses only built-in instance types.
