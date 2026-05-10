# tutorial-plugin

Roblox Studio plugin that plays back `lesson.yaml` manifests step by step.

## Build

Uses Rojo. From this directory:

```
rojo build default.project.json -o TutorialPlugin.rbxmx
```

Drop `TutorialPlugin.rbxmx` into `%LOCALAPPDATA%/Roblox/Plugins` on Windows
or `~/Documents/Roblox/Plugins` on macOS, or serve it via `rojo serve` and
install the Rojo plugin.

## Architecture

Three layers, in order of dependency:

1. **Fetch** (`src/Fetch/`) — HTTP GET against configured repo indexes and
   lesson URLs. Parses YAML. Validates against the bundled schema. Caches
   results in `plugin:SetSetting`.
2. **Playback** (`src/Playback/`) — pure functions that take a parsed lesson
   + a step index and mutate the DataModel. One applier per step type /
   action op. All wrapped in `ChangeHistoryService` so Ctrl-Z undoes a step.
3. **UI** (`src/Components/`) — React dock widget. Three views: Library,
   Active lesson, Settings. The Active view renders the current step and
   drives playback forward/back.

See `PLAN.md` and `SCHEMA.md` in the parent directory for the full design.

## Module layout

```
src/
├── Main.server.lua            -- plugin entry point, creates DockWidget
├── Fetch/
│   ├── FetchIndex.lua         -- GET repoUrl/index.json
│   ├── FetchLesson.lua        -- GET lessonUrl → parsed table
│   ├── Yaml.lua               -- minimal YAML parser (or Packages/lua-yaml)
│   └── Validate.lua           -- JSON-Schema validation against schema.json
├── Playback/
│   ├── Apply.lua              -- dispatch by step.type → per-applier
│   ├── Actions/
│   │   ├── CreateInstance.lua
│   │   ├── SetProperty.lua
│   │   ├── DeleteInstance.lua
│   │   ├── ParentTo.lua
│   │   ├── CloneFromAssets.lua
│   │   └── InsertAsset.lua
│   ├── CodeEdit.lua           -- target.path + full source replacement
│   ├── Focus.lua              -- Selection:Set + ScriptEditorService
│   ├── ResolvePath.lua        -- "Workspace.Emitter" → Instance
│   └── Coerce.lua             -- YAML value → property-typed value
├── Components/
│   ├── App.lua
│   ├── LibraryView.lua
│   ├── LessonView.lua
│   ├── StepList.lua
│   ├── StepBody.lua           -- renders body/explain markdown
│   ├── DiffView.lua           -- computes visible diff for codeEdit
│   ├── PromptStepView.lua     -- body + copy button
│   └── SettingsView.lua       -- repo URLs, single lesson URL
└── Schema/
    └── schema.json            -- bundled copy of the lesson schema
```

## State

Persisted via `plugin:SetSetting`:

- `repos` — array of repo base URLs (each hosts `index.json`)
- `adhocLessons` — array of `{ id, url }` for one-off lesson URLs
- `lastLessonId` — for resume-on-reopen
- `autoplaySpeed` — reader preference

Transient (React state):

- `currentLessonId`, `currentStepIndex`
- `fetchStatus` per lesson/index

## Playback invariants

- Steps apply in order. Scrubbing backwards = replay from scratch up to the
  target index.
- Every applied step is a single `ChangeHistoryService:TryBeginRecording` /
  `:FinishRecording` transaction so Ctrl-Z undoes exactly one step.
- If a step fails to apply (e.g. `cloneFromAssets` when the
  `TutorialAssets` folder is absent), surface a clear error and stop; don't
  advance.

## Place file requirement

Lessons using `cloneFromAssets` must run inside `TutorialsPlace.rbxlx`
(or a fork of it) so `ReplicatedStorage.TutorialAssets.<sampleId>` exists.
Lessons using only `createInstance` / `setProperty` / `codeEdit` /
`insertAsset` work anywhere.
