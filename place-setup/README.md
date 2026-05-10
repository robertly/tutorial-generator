# Shared TutorialsPlace setup

The plan's "shared `TutorialsPlace.rbxlx`" is the place file that lessons
using `cloneFromAssets` resolve against. None of the **current** samples
actually use bundled assets — they all build from primitives — so this
folder is scaffolding for future samples.

## Producing `TutorialsPlace.rbxlx`

1. In Studio, create a new Baseplate place (any template with an empty
   Workspace is fine).
2. Open the command bar: **View → Command Bar**.
3. Paste the contents of `setup_tutorials_place.lua` and hit Enter.
4. `File → Save As... → TutorialsPlace.rbxlx` (save into this repo's
   root, alongside `Showcase.rbxlx`).

The script creates `ReplicatedStorage.TutorialAssets` and per-sample
sub-folders for anything declared in its own `SAMPLES` table. Right now
that table is empty with a commented-out example — rerun the script
(idempotent) whenever you add entries.

## Adding an asset

1. Open `TutorialsPlace.rbxlx` in Studio.
2. Add the Model / MeshPart / etc. you need under
   `ReplicatedStorage.TutorialAssets.<sampleId>/`.
3. Save the place.
4. In the sample's `lesson.yaml`, reference the asset via
   `cloneFromAssets`:
   ```yaml
   action:
     op: cloneFromAssets
     source: "ReplicatedStorage.TutorialAssets.<sampleId>.<assetName>"
     parent: "Workspace"
     name: "MyRuntimeName"
   ```
5. Optionally append the builder to `SAMPLES` in the setup script so the
   place file can be reproduced from scratch.

## Why not just commit the `.rbxlx`?

Binary-ish XML that Studio mutates on every save is miserable to diff.
Checking in the reproduction script keeps review manageable; the actual
place file is a build artifact anyone can regenerate.
