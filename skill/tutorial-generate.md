---
description: Read a sample's README.md and source code, produce lesson.yaml conforming to schema.json. Stateless — never reads its own previous output.
---

# /tutorial-generate

Reads a tutorial sample's `README.md` + source code, writes `lesson.yaml`
conforming to `schema.json`. Stateless: **never read the previous
`lesson.yaml`** — regenerate from README + source every time. This
prevents AI drift from re-ingesting our own output.

## Inputs

- `<sample>/README.md` — the outline (required; fail cleanly if missing)
- `<sample>/src/` (or whatever the Rojo project points at) — the actual code
- `<sample>/default.project.json` — tells us the path mapping
- `../../SCHEMA.md` + `../../schema.json` — the output contract

## Output

- `<sample>/lesson.yaml` — overwrite existing. The schema is version 1.

## Authoring rules

### Slugs

- `id` is derived from the folder name (`raycast-basics` → `raycast-basics`).
  Lowercase, hyphen-separated, `^[a-z0-9][a-z0-9-]*$`.
- Step `id`s are short slugs, prefixed with their order: `s1-intro`,
  `s2-create-emitter`, …

### Steps

Pick types from the closed vocabulary: `narrative`, `scripted`, `codeEdit`,
`prompt`. Prefer **fewer, weightier** steps over many tiny ones. Good default
cadence:

- First step: `narrative` — set up what the reader is about to see.
- Each "thing gets created/edited" becomes one step of type `scripted` or
  `codeEdit`. **One conceptual change per step.** Don't create a Part and
  also set a dozen properties in the same step — create it with the props
  inline (`createInstance` takes a `props` map), then use follow-up
  `setProperty` steps only for changes that deserve their own narrative
  beat.
- `prompt` steps — use sparingly, for "the best way to extend this is to ask
  Assistant." One per lesson, usually near the end.
- **Last step: always a `narrative` "finish and playtest" step.** Conventionally
  id `sN-playtest` (or `s-playtest`). Its body tells the reader to press
  Play and describes what they should see, hear, or do to verify the build
  works. Even if an earlier `prompt` step handed extension work to Assistant,
  the lesson still ends with this playtest narrative — do not merge the two.
  Example body: "Press ▶ Play. Walk onto the emitter — you should see 'Ray
  hit: ...' in the Output window each time you step on it."

### `body` content

- Markdown allowed. Keep it to 1–3 short paragraphs.
- Start the body with the **what**, not the **how** — the reader sees the
  mutation happen; don't narrate the mutation verbatim.
- Put deeper explanation in `explain`, not `body`.

### `focus`

After every `scripted` / `codeEdit` step, set `focus`:

- After `createInstance` / `parentTo` / `cloneFromAssets` / `insertAsset` /
  `setProperty`: `focus.selection` with the affected path.
- After `codeEdit`: `focus.script.path` at minimum. Add `startLine`/`endLine`
  if a specific section of the script is what changed.

### `codeEdit` — full source replacement

The `source` field is the **entire script body** after this step. Never a
diff or patch. If the previous step's script was 20 lines and this step adds
3, emit all 23. The plugin computes the visible diff by comparing adjacent
steps' sources.

When creating a script for the first time, include `target.create: true` and
`target.class`.

### `scripted` — closed action vocabulary

Use only these six ops:

- `createInstance` — for every new DataModel instance.
- `setProperty` — single property change post-create.
- `deleteInstance`, `parentTo` — rare but allowed.
- `cloneFromAssets` — for anything under `ReplicatedStorage.TutorialAssets.<id>.*`
  bundled in the shared place.
- `insertAsset` — fallback for `rbxassetid://...` marketplace references.

Don't invent new ops. If an author asks for something outside this set,
model it as a `prompt` step instead.

### Property values

Let YAML be YAML. Follow the conventions in SCHEMA.md:

- Vector3 / Size / Position / UDim2 / Color3: arrays of numbers.
- `CFrame`: 12-number array.
- Enums: `"Enum.Material.Metal"`.
- Instance references: dot-path strings.

Don't annotate types — the plugin infers them from property reflection.

### Assets block

Whenever the lesson references `ReplicatedStorage.TutorialAssets.<id>.<name>`
via `cloneFromAssets`, or `rbxassetid://...` via `insertAsset` or as a
property value, add an entry to the top-level `assets` array. Include a
short `description` of what it is.

### Instance paths

- Start at the service (`Workspace`, `ReplicatedStorage`, etc.). **No leading
  `game.`**
- Case-sensitive.
- Avoid spaces in names you create (readability).

### Ids and ordering

- Step order in `steps:` is the playback order.
- IDs must be unique within the lesson.

## Procedure

1. Locate the sample folder (argument, or cwd).
2. Read `README.md`. If missing, error out telling the user to run
   `/tutorial-bootstrap` first or write a README by hand.
3. Read every source file under the Rojo project's mapped path(s).
4. Extract from the README: title, goal, component list, flow.
5. For each component: decide whether it's a create step (+ property step if
   needed) or a code edit step.
6. For each flow item in the README: map it to a step.
7. Draft the YAML. Validate against `schema.json` mentally (every
   `scripted.action` picks one of the six ops; every `codeEdit.target.path`
   is a valid instance path; every `focus.selection` references a real
   instance).
8. Write `<sample>/lesson.yaml`.
9. Print a short summary: step count by type, assets referenced.

## Non-goals

- Do **not** read any existing `lesson.yaml`.
- Do not fetch anything over the network.
- Do not add "Try it yourself" / exercise / quiz steps — pure playback.
- Do not invent assets that aren't in the README or source.
