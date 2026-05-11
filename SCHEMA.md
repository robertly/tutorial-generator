# Lesson Manifest Schema

The lesson manifest is the contract between the Claude Code skill (producer) and the Studio plugin (consumer). It is authored as YAML, validated against `schema.json` (JSON Schema draft-07 — which also validates YAML once parsed).

This document walks through every field. For the authoritative rules, see `schema.json`.

## Minimal lesson

```yaml
schemaVersion: 1
id: raycast-basics
title: Raycast basics

steps:
  - id: s1
    type: narrative
    body: |
      Raycasting lets you detect what a ray crosses.
```

Valid, boring, but legal. Anything beyond this is additive.

## Top-level fields

| Field | Required | Description |
|-------|----------|-------------|
| `schemaVersion` | yes | Always `1` in this version. Plugin refuses unknown versions. |
| `id` | yes | Lowercase hyphenated slug. Must be unique within a samples repo. |
| `title` | yes | Short display title. |
| `goal` | no | One-sentence summary of what the reader learns. |
| `prerequisites` | no | Other lesson IDs the reader should complete first. |
| `tags` | no | Free-form tags for filtering in the plugin Library. |
| `assets` | no | Inventory of assets this lesson depends on. See below. |
| `steps` | yes | Ordered playback steps. At least one. |

## Steps

Every step has four common fields: `id`, `type`, `body`, and optionally `explain` and `focus`. The `type` picks one of four step shapes. Every step except narrative also carries type-specific fields.

### Common fields

| Field | Required | Description |
|-------|----------|-------------|
| `id` | yes | Lowercase hyphenated slug, unique within the lesson. |
| `type` | yes | One of `narrative`, `scripted`, `codeEdit`. |
| `body` | yes | Main narrative. Markdown allowed. Shown in the main content area. |
| `explain` | no | Deeper explanation. Expandable "learn more" panel in the UI. |
| `focus` | no | UI highlight applied after the step runs. See [Focus](#focus). |

### `narrative` step

Prose only. No action. Use for transitions, setup, context between mechanical steps.

```yaml
- id: s1
  type: narrative
  body: |
    Raycasting lets you detect what a ray crosses. We'll build an
    emitter part that casts rays downward and reports what it hits.
  explain: |
    Under the hood, Ray.new takes an origin and a direction vector...
```

### `scripted` step

Performs a DataModel mutation. Auto-applies when the reader clicks Next. The `action` field picks the operation.

```yaml
- id: s2
  type: scripted
  body: "We start with a Part in Workspace to act as the emitter."
  action:
    op: createInstance
    class: Part
    parent: Workspace
    props:
      Name: Emitter
      Anchored: true
      Size: [4, 1, 4]
      Position: [0, 5, 0]
      Material: Enum.Material.Metal
  focus:
    selection: "Workspace.Emitter"
```

### `codeEdit` step

Creates or edits a script. The `source` field holds the **entire script body** after the step — never a diff or patch. The plugin computes the visible diff by comparing adjacent steps.

```yaml
- id: s3
  type: codeEdit
  body: "Add a handler that fires a ray when the emitter is touched."
  target:
    path: "Workspace.Emitter.Handler"
    create: true
    class: Script
  source: |
    local function onTouch(hit)
      local origin = script.Parent.Position
      local dir = Vector3.yAxis * -50
      local result = workspace:Raycast(origin, dir)
      if result then
        print("hit:", result.Instance:GetFullName())
      end
    end

    script.Parent.Touched:Connect(onTouch)
  focus:
    script:
      path: "Workspace.Emitter.Handler"
      startLine: 1
      endLine: 10
```

`target.create` and `target.class` are only needed when creating a new script. For edits to an existing script, just provide `target.path` and the new full `source`.

## Focus

Optional per-step UI hint applied after the action runs. Any subset of the sub-fields can be provided.

```yaml
focus:
  selection: "Workspace.Emitter"
  # or list:
  # selection: ["Workspace.Emitter", "Workspace.Target"]
  script:
    path: "Workspace.Emitter.Handler"
    startLine: 3
    endLine: 7
```

| Field | Description |
|-------|-------------|
| `selection` | Instance path (string) or list of instance paths to select in the Explorer. |
| `script.path` | Script instance path to open in the script editor. |
| `script.startLine`, `script.endLine` | 1-indexed line range to highlight. Both optional; omit for "just open the script." |

Viewport framing (camera movement) is intentionally **not** supported in v1.

## Actions

Closed vocabulary of six operations for `scripted` steps.

### `createInstance`

```yaml
action:
  op: createInstance
  class: Part                   # Roblox ClassName
  parent: Workspace             # instance path
  props:                        # optional property map
    Name: Emitter
    Size: [4, 1, 4]
```

The instance's `Name` is whatever `props.Name` sets (or the default ClassName if omitted).

### `setProperty`

```yaml
action:
  op: setProperty
  target: "Workspace.Emitter"
  property: Anchored
  value: true
```

### `deleteInstance`

```yaml
action:
  op: deleteInstance
  target: "Workspace.TempFolder"
```

### `parentTo`

```yaml
action:
  op: parentTo
  target: "Workspace.Emitter"
  parent: "Workspace.Emitters"
```

### `cloneFromAssets` — primary asset path

Clones an instance from the shared place's `ReplicatedStorage.TutorialAssets.<sampleId>.*` folder. Use for meshes, pre-built models, rigs, etc. bundled with the tutorials place file.

```yaml
action:
  op: cloneFromAssets
  source: "ReplicatedStorage.TutorialAssets.raycast-basics.EmitterRig"
  parent: "Workspace"
  name: "Emitter"               # optional rename after clone
```

### `insertAsset` — fallback for marketplace references

Fetches an asset by ID via `game:GetObjects`. Use when an asset lives on the Roblox marketplace rather than bundled in the place file.

```yaml
action:
  op: insertAsset
  assetId: "rbxassetid://12345678"
  parent: "Workspace"
  name: "CommunityBarrel"
```

## Property values

Property values are polymorphic. The plugin reads the target property's declared type and coerces the YAML value appropriately. Conventions:

| Roblox type | YAML encoding | Example |
|-------------|---------------|---------|
| number / string / bool | native | `Anchored: true`, `Name: Emitter` |
| Vector3 / Vector2 / Size | array of numbers | `Position: [0, 5, 0]` |
| CFrame | 12-number array `[px,py,pz, r00..r22]` | `CFrame: [0,0,0, 1,0,0, 0,1,0, 0,0,1]` |
| Color3 | `[r, g, b]` in 0..1 | `Color: [1, 0.5, 0.2]` |
| UDim2 | `[scaleX, offsetX, scaleY, offsetY]` | `Size: [0, 100, 0, 50]` |
| EnumItem | dotted string | `Material: Enum.Material.Metal` |
| Instance reference | instance path string | `PrimaryPart: "Workspace.Emitter.Base"` |
| null / Instance nil | `null` | `Parent: null` |

Authors don't annotate types; the plugin figures it out from the class's property reflection. The AI generator just writes the natural-looking YAML.

## Instance paths

Dot-separated paths rooted at a DataModel service (`Workspace`, `ReplicatedStorage`, `ServerStorage`, `StarterPlayer`, etc.) or a descendant thereof.

Examples:
- `Workspace.Emitter`
- `Workspace.Emitter.Handler`
- `ReplicatedStorage.TutorialAssets.raycast-basics.EmitterRig`
- `StarterPlayer.StarterCharacterScripts.Movement`

Names with spaces and hyphens are permitted in non-leading segments (Studio allows them, and lesson IDs under `TutorialAssets.<sample-id>` commonly contain hyphens). The **first** segment must be a valid service name — letters/underscore start, no spaces or hyphens — so paths like `Workspace.My-Thing` are fine but `My-Service.Foo` is not.

## Assets block

Optional top-level inventory. Documents what the lesson depends on. Each entry declares `kind` and either `source` (bundled in the shared place) or `assetId` (marketplace reference), but not both.

```yaml
assets:
  - kind: model
    source: "ReplicatedStorage.TutorialAssets.raycast-basics.EmitterRig"
    name: "Emitter rig"
    description: "Pre-built emitter mesh with particle attachment points."
  - kind: mesh
    assetId: "rbxassetid://12345678"
    name: "Community barrel"
    description: "Used to test raycast against arbitrary geometry."
```

`kind` enum: `model | mesh | image | sound | animation | audio | video | other`.

The plugin doesn't enforce or pre-fetch assets from this block in v1; it's for documentation and future use. The `/tutorial-generate` skill populates it automatically from references it finds in the lesson.

## Full example

```yaml
schemaVersion: 1
id: raycast-basics
title: Raycast basics
goal: Cast a ray from a Part and react to what it hits.
tags: [raycasting, beginner]

assets:
  - kind: model
    source: "ReplicatedStorage.TutorialAssets.raycast-basics.EmitterRig"

steps:
  - id: s1
    type: narrative
    body: |
      Raycasting lets you detect what a ray crosses in the world. We'll
      build a small emitter that casts rays downward and reports hits.

  - id: s2
    type: scripted
    body: "Create the emitter part in Workspace."
    action:
      op: createInstance
      class: Part
      parent: Workspace
      props:
        Name: Emitter
        Anchored: true
        Size: [4, 1, 4]
        Position: [0, 10, 0]
        Material: Enum.Material.Metal
    focus:
      selection: "Workspace.Emitter"

  - id: s3
    type: codeEdit
    body: "Add a handler script that casts a ray when something touches the emitter."
    target:
      path: "Workspace.Emitter.Handler"
      create: true
      class: Script
    source: |
      local function onTouch(hit)
        local origin = script.Parent.Position
        local dir = Vector3.yAxis * -50
        local result = workspace:Raycast(origin, dir)
        if result then
          print("hit:", result.Instance:GetFullName())
        end
      end

      script.Parent.Touched:Connect(onTouch)
    focus:
      script:
        path: "Workspace.Emitter.Handler"

  - id: s4
    type: scripted
    body: "Drop in a pre-built target rig to give the ray something to hit."
    action:
      op: cloneFromAssets
      source: "ReplicatedStorage.TutorialAssets.raycast-basics.EmitterRig"
      parent: "Workspace"
      name: "Target"
    focus:
      selection: "Workspace.Target"

  - id: s5-playtest
    type: narrative
    body: |
      Press ▶ Play (F5). Touch the emitter — each contact triggers a
      downward raycast and prints the hit in the Output window.
```

## Gotchas

- **Instance paths are case-sensitive.** `Workspace.emitter` ≠ `Workspace.Emitter`.
- **Do not include leading `game.`** Paths start at the service (`Workspace`, `ReplicatedStorage`, etc.).
- **Full-source replacement for `codeEdit`.** If a script exists and you provide `source`, the entire body is replaced. There is no append or patch mode.
- **`cloneFromAssets` requires the shared tutorials place.** If run outside of it, the plugin surfaces a clear error. `rbxassetid://` via `insertAsset` works anywhere.
- **`setProperty` uses the property's declared type** for coercion; a property that wants a Vector3 must be given `[x,y,z]`, not a nested object.
- **Step `id` uniqueness is within a lesson, not globally.** Lesson `id` uniqueness is within a samples repo.

## Versioning

This document describes `schemaVersion: 1`. Future versions will:
- Keep `schemaVersion` as the top-level discriminator.
- Add new step types, action ops, or fields — never repurpose existing ones.
- Be explicit about breaking changes; plugins refuse versions they don't know.
