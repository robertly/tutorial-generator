# Tutorial Generator — Plan

A system for producing narrated playback tutorials of working Roblox projects, from a sample + a README, via a Claude Code skill. The generated tutorials play back inside a Studio plugin.

## Product vision

Engineers deliver working Roblox sample projects. A Claude Code skill turns each sample into a lesson manifest. A Studio plugin plays the manifest back step-by-step, auto-applying each change to the DataModel while the user watches and reads narration. Learning comes from seeing a real project get built with context, not from being quizzed.

The entire authoring surface is two files per sample: the Rojo project source and a `README.md`. Everything else is generated.

## High-level architecture

```
┌──────────────────────────┐     ┌──────────────────────────┐     ┌──────────────────────────┐
│ tutorial-samples (repo)  │     │ tutorial-skill (repo)    │     │ tutorial-plugin (repo)   │
│                          │     │                          │     │                          │
│  samples/*/              │◄────│  /tutorial-bootstrap     │     │  Studio plugin (Rojo)    │
│    default.project.json  │     │  /tutorial-generate      │     │  Fetches lesson.yaml     │
│    src/                  │     │  schema.json             │     │  over HTTP               │
│    README.md   ◄─────────┼─────┤  (author edits this)     │     │                          │
│    lesson.yaml ◄─────────┼─────┤  (skill writes this)     │     │                          │
│  TutorialsPlace.rbxlx    │     │                          │     │                          │
│  index.json              │     │                          │     │                          │
└──────────────────────────┘     └──────────────────────────┘     └──────────────────────────┘
          ▲                                                                   │
          └───────────────────── HTTP GET (raw github URLs) ──────────────────┘

           (User opens TutorialsPlace.rbxlx in Studio; plugin loads lessons into it)
```

Three repos, all open source:

1. **tutorial-skill** — the Claude Code skill (markdown) + the JSON Schema + authoring docs.
2. **tutorial-plugin** — the Studio plugin (Rojo project) that plays back lesson manifests.
3. **tutorial-samples** — seed collection of real samples + the shared `TutorialsPlace.rbxlx` that bundles their assets. Anyone can fork and point the plugin at their own repo.

No backend services. No CLIs to distribute. No review UIs. Git hosts everything; the plugin fetches via HTTP.

## Shared tutorials place

All tutorials run inside a single shared place file (`TutorialsPlace.rbxlx`) that ships alongside the samples repo. This is the sandbox environment lessons play back into.

Its `ReplicatedStorage` contains a `TutorialAssets` folder, namespaced per sample:

```
ReplicatedStorage/
  TutorialAssets/
    raycast-basics/
      Emitter            -- MeshPart, pre-imported
      Barrel             -- Model
    camera-shake/
      CameraRig
```

Engineers contributing a sample that needs assets drop them into the appropriate subfolder, commit the updated `.rbxlx` alongside their `lesson.yaml`, push. No Roblox marketplace upload required; no asset ownership issues; no CDN dependency.

Why force a shared place:
- Tutorials mutate the DataModel heavily — running them in a user's real project would be chaotic.
- Bundling assets with the place eliminates the "engineer's personal asset ID disappears when they leave" failure mode.
- Users open one file; the plugin just works.

Plugin behavior: at load time, the plugin checks for `ReplicatedStorage.TutorialAssets`. If missing, it shows a "please open TutorialsPlace.rbxlx" error and refuses to run lessons that need bundled assets. Lessons with no bundled assets still work in any place.

## Authoring flow

```
1. Engineer writes a Rojo sample project.
2. Runs /tutorial-bootstrap in the sample folder.
   → drafts README.md from the source code.
3. Engineer edits README.md to emphasize what matters.
4. Runs /tutorial-generate.
   → writes lesson.yaml from README + source.
5. Commits. Pushes to a public repo.
6. Users add the repo URL to their plugin; lesson appears in the library.
```

Engineer touches: the Rojo project + `README.md`. Skill produces: `README.md` (first draft only) + `lesson.yaml` (regenerated as README evolves).

### The two commands

- **`/tutorial-bootstrap`** — scaffolds a new sample. Creates folder layout if missing, reads whatever source code the engineer has written, drafts a `README.md`. Does not generate `lesson.yaml`. Run once per new sample.
- **`/tutorial-generate`** — reads current `README.md` + source, writes `lesson.yaml`. Stateless. Run whenever README changes or the schema/skill improves.

## Sample folder layout

```
samples/raycast-basics/
├── default.project.json       # Rojo
├── src/                       # authored code
│   └── …
├── README.md                  # drafted by bootstrap, edited by engineer
└── lesson.yaml                # generated by generate (never edited by hand)
```

## Repo-level layout (tutorial-samples)

```
tutorial-samples/
├── index.json                 # { "samples": [{ id, title, path, tags }, ...] }
└── samples/
    ├── raycast-basics/
    ├── camera-shake/
    └── …
```

The plugin fetches `index.json` to populate its Library view, then individual `lesson.yaml` files on demand.

## Lesson schema (summary)

Format: **YAML.** Chosen over JSON for multi-line narrative strings. Validated against a JSON Schema (works on YAML too).

Closed vocabulary of step types so AI output is reliable:

- **`narrative`** — prose only, no action. Body + optional `explain`.
- **`scripted`** — DataModel mutation (create/set-property/delete/reparent). Auto-applies.
- **`codeEdit`** — create or edit a script's `Source`. Auto-applies; UI shows a diff.
- **`prompt`** — narrative with a copyable suggested prompt. For "here's how I'd ask Assistant to do this" moments.

Closed vocabulary of action ops for `scripted`: `createInstance`, `setProperty`, `deleteInstance`, `parentTo`, `cloneFromAssets`, `insertAsset`.

- `cloneFromAssets` — primary asset path. Clones an instance from `ReplicatedStorage.TutorialAssets.<sampleId>.<name>` into a target parent. Used for bundled meshes, models, rigs, etc.
- `insertAsset` — fallback for Roblox marketplace references (`rbxassetid://...`). Uses `game:GetObjects`. Used when bundling would bloat the place file or when showcasing a community asset.

Property values of type `rbxassetid://...` remain valid as regular string properties (e.g., `Sound.SoundId`, `Decal.Texture`) — useful for small asset references that don't need full instance cloning.

Common step fields: `id`, `type`, `body` (markdown), `explain` (markdown, optional), `focus` (highlight instance / script lines, optional).

`focus` sub-fields: `selection` (path or list), `script` (path + startLine + endLine). Viewport framing deferred post-v1 — explorer selection + script editor focus are enough.

Lesson-level fields: `schemaVersion` (always `1` for v1), `id`, `title`, `goal`, `prerequisites`, `tags`, `assets` (optional — inventory of `cloneFromAssets` paths and `rbxassetid://` references the lesson uses), `steps`.

Property value encoding (serializable types): primitives (`number`, `string`, `bool`), `Vector3` as `[x,y,z]`, `CFrame` as 12-number array, `Color3` as `[r,g,b]`, `UDim2`, `EnumItem` as `"Enum.Material.Plastic"`, `Instance` references as dot-paths. No functions, no deeply-nested tables for v1.

`codeEdit` uses full-source replacement — never patches. The `source` field contains the entire script body at that step. Plugin computes visible diffs by comparing adjacent steps' sources. This is always correct, scrubs trivially, and is what the AI naturally produces.

Full schema drafted separately in `SCHEMA.md` / `schema.json`.

## Plugin design

Single dock widget, three views:

- **Library** — list of lessons pulled from configured repo indexes. Search, filter by tag.
- **Active lesson** — step list on the left, current step on the right. Narrative, diff panel, next/back/autoplay, focus highlights.
- **Settings** — add/remove repo URLs, paste a single lesson URL, clear state.

### Playback behavior

- **Auto-apply on Next.** All scripted/codeEdit steps apply immediately. No "wait for user" states.
- **Autoplay** with pacing control.
- **Scrubbing.** Click any step in the timeline; plugin replays from scratch up to that point. (Start with replay-from-scratch; materialized snapshots as a later optimization.)
- **Diff view.** After each step, show what changed (new instances in green, deleted in red, script line additions).
- **Focus.** After each step, highlight the referenced instance in the Explorer (`Selection:Set`) and/or scroll to the referenced script lines (`ScriptEditorService:OpenScriptDocumentAsync` + selection APIs). Viewport framing deferred — explorer + script focus is enough for v1.
- **Copy button** on prompt steps.
- **ChangeHistoryService** wraps every action so standard Ctrl-Z undoes a step.

### Fetch model

- On Library load: fetch each configured `index.json` over HTTP.
- On lesson selection: fetch the corresponding `lesson.yaml`.
- Cache locally per `plugin:SetSetting`.

## Docs site rendering (optional but free)

The same `lesson.yaml` can render as a static article: steps → headings, `body` → prose, scripted/codeEdit steps → code blocks + "what changes" callouts. No interactivity needed — just a second surface for the same content. Users who prefer reading get a good experience without Studio.

## Handoff: docs → Studio

Deliberately simple: the docs page shows the lesson's URL (or ID). User pastes it into the plugin's Settings view. One copy, one paste. Consistent with the "copy prompts into Assistant" pattern.

Fancier options (deeplinks, browser extensions, TLS loopback) are explicitly out of scope for v1. They can be layered on later without changing the core.

## What we deliberately dropped

Worth naming explicitly so the scope stays honest:

- ❌ **MCP server additions.** Originally considered extending Studio's MCP proxy/plugin to accept browser calls. Unnecessary given the playback model.
- ❌ **Browser extension / deeplink / loopback TLS.** All solve "browser pokes Studio" — replaced by "plugin fetches from GitHub."
- ❌ **Cross-plugin bridge into Assistant's `ExternalHooks`.** Replaced by `prompt` steps with a Copy button.
- ❌ **User exercises / validation / "did they do it right" checks.** Pure playback means no need.
- ❌ **Review UI for generated lessons.** Claude Code is the review surface — engineer iterates via conversation and git.
- ❌ **Backend service for pairing, relay, or coordination.** None needed.
- ❌ **AI generator CLI / binary.** Replaced by a Claude Code skill (markdown file).
- ❌ **`outline.md` as a separate file.** README plays the role of outline AND human-facing doc.

## Build order

1. **JSON Schema** (`schema.json` + `SCHEMA.md`). The contract everything else depends on.
2. **One hand-authored `lesson.yaml`** for a real sample. Stress-tests the schema and serves as the target for the skill.
3. **The plugin (`tutorial-plugin`)** — plays the hand-authored manifest end-to-end. Library, playback, diff, focus, autoplay.
4. **Docs site rendering** — static render of the same manifest. Optional; can come last.
5. **The skill (`tutorial-skill`)** — `/tutorial-bootstrap` + `/tutorial-generate`. Engineered against the hand-authored lesson as the target output.
6. **Example samples (`tutorial-samples`)** — 3–5 good samples. Doubles as a test corpus for the skill.

Deliberate order: schema first (contract), then plugin (consumer), then skill (producer). Building the skill against a known-good manifest shape is easier than building the skill blind and then discovering the schema is wrong.

## Resolved design decisions

- **`focus` fields**: `selection` (Explorer), `script` (path + line range in the script editor). Viewport framing deferred post-v1.
- **`codeEdit` diffs**: full-source replacement always. Plugin computes visible diffs from adjacent steps.
- **Snapshotting**: replay-from-scratch for scrubbing. Materialized snapshots post-v1 if performance demands.
- **Schema versioning**: `schemaVersion: 1` at the top of every manifest. Plugin refuses unknown versions.
- **Assets**: bundled in the shared `TutorialsPlace.rbxlx` under `ReplicatedStorage.TutorialAssets.<sampleId>/`, referenced via the new `cloneFromAssets` action op. `rbxassetid://` references retained as a fallback via `insertAsset` and as property values.
- **Action vocabulary (final for v1)**: `createInstance`, `setProperty`, `deleteInstance`, `parentTo`, `cloneFromAssets`, `insertAsset`.
- **Step type vocabulary (final for v1)**: `narrative`, `scripted`, `codeEdit`, `prompt`.

## Still open (non-blocking for schema)

- **Where does the plugin discover repos by default?** Zero-config (user adds URLs) vs. a built-in default registry. UX decision, doesn't affect schema.
- **Place file distribution.** Direct `.rbxlx` download from the repo vs. a published place on Roblox that users open by ID. Probably ship both: raw file in git for forking, published place ID for easy user onboarding.

## Non-goals for v1

- Rich validation / "did the user do this correctly" grading.
- Multi-DataModel tutorials (edit mode + play mode switching).
- Real-time collaboration on a lesson.
- Authoring tools beyond "write code + README."
- Any LLM integration beyond the Claude Code skill (no in-plugin LLM calls).
- Viewport framing as a focus target.

## Success criteria for v1

- An engineer can take a working Rojo sample, run two commands, and commit a lesson that plays back correctly in Studio.
- A user can add a repo URL to the plugin, pick a lesson, and learn from it without reading any extra docs about the plugin.
- The JSON Schema reliably constrains AI output to valid manifests (measured by % of first-run outputs that pass validation on the sample corpus).
- Regenerating a lesson from an edited README reflects the author's changes faithfully (no AI drift from re-ingesting its own output, because the skill only reads the README, never its own previous `lesson.yaml`).

## Next step

Draft `schema.json` and its human-readable counterpart `SCHEMA.md` in this directory.
