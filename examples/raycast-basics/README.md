# Raycast basics

A small tutorial-sample. We build an "emitter" part in Workspace that fires a
downward raycast whenever something touches it, then drop in a target rig for
the ray to hit.

## What it shows

- `workspace:Raycast(origin, direction)` — the modern raycast API.
- `Vector3.yAxis` as a readable way to write a unit vector.
- Responding to a `.Touched` event by running code against world state.
- Reading the hit result: `result.Instance`, `result.Position`.

## Components

- **Workspace.Emitter** — an anchored Part that acts as the ray origin. Sized
  flat so it's obvious where it is. Anchored so physics don't move it.
- **Workspace.Emitter.Handler** — a server `Script` under the Emitter. Connects
  to `Emitter.Touched`, casts a ray 50 studs straight down, prints what it hit.
- **Workspace.Target** — a cloned rig from the bundled `TutorialAssets` folder,
  placed below the emitter so the ray has something interesting to hit.

## Flow

1. Create the emitter part in Workspace.
2. Add the handler script with the Touched + Raycast logic.
3. Clone the bundled target rig into Workspace below the emitter.
4. Suggest an Assistant prompt to upgrade the handler into a timed loop.

## Assets

- `ReplicatedStorage.TutorialAssets.raycast-basics.EmitterRig` — a pre-built
  mesh/model used as the Target. Bundled in `TutorialsPlace.rbxlx`.
