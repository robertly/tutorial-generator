# Dithering filter

Floyd-Steinberg 1-bit dither applied to a radial gradient. Produces the
classic "old Mac"/Macintosh dithered look — every pixel is pure black or
pure white, but the density approximates continuous gray.

## What it shows

- Building a procedural grayscale source.
- Error diffusion dithering: quantize each pixel, push the error to its
  unvisited neighbors.
- Rendering a single-channel value into RGBA.

## Components

- **StarterGui.DitherGui** — ScreenGui.
- **StarterGui.DitherGui.Canvas** — ImageLabel.
- **StarterGui.DitherGui.Canvas.Dither** — LocalScript.

## Flow

1. ScreenGui + ImageLabel.
2. Add the Dither LocalScript.
3. Playtest: a dithered radial gradient appears.

## Assets

None.
