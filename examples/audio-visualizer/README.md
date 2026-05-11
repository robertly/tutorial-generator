# Audio visualizer

Scroll a loudness-history array leftward each frame and draw it as
rainbow bars on an `EditableImage`. Uses `SoundService:GetOutputLoudness`
for the signal.

## What it shows

- `SoundService:GetOutputLoudness` — overall output RMS.
- `EditableImage:DrawRectangle` for simple primitive drawing.
- A scrolling history buffer without any pixel buffer — just sampled
  primitives.

## Components

- **StarterGui.VisualizerGui** — ScreenGui.
- **StarterGui.VisualizerGui.Canvas** — ImageLabel.
- **StarterGui.VisualizerGui.Canvas.Visualize** — LocalScript.

## Flow

1. ScreenGui + ImageLabel.
2. Add the Visualize LocalScript.
3. Playtest: walk around, trigger sounds, watch bars react.

## Assets

None required. Try adding any `Sound` under `SoundService` and `:Play()`
it from the command bar for more visible bars.
