# tutorial-generator

Playback-style tutorials for Roblox. Engineers deliver a working Rojo sample
plus a README; a Claude Code skill turns it into a `lesson.yaml` manifest;
a Studio plugin plays the manifest back step by step inside a shared
`TutorialsPlace.rbxlx` file.

This repo is a staging ground for all three pieces before they get split into
their own open-source repos.

## Layout

```
tutorial-generator/
├── PLAN.md                     design doc — start here
├── SCHEMA.md                   human-readable schema reference
├── schema.json                 JSON Schema draft-07, canonical contract
│
├── examples/
│   └── raycast-basics/         hand-authored sample + lesson.yaml
│       ├── README.md
│       └── lesson.yaml
│
├── skill/                      Claude Code skill (eventually: tutorial-skill repo)
│   ├── tutorial-bootstrap.md   /tutorial-bootstrap — scaffold a new sample
│   └── tutorial-generate.md    /tutorial-generate — README → lesson.yaml
│
└── plugin/                     Studio plugin (eventually: tutorial-plugin repo)
    ├── README.md
    ├── default.project.json
    └── src/
        ├── Main.server.lua
        ├── Fetch/              HTTP + YAML + schema validation
        ├── Playback/           apply steps to DataModel
        │   ├── Apply.lua
        │   ├── CodeEdit.lua
        │   ├── Focus.lua
        │   ├── ResolvePath.lua
        │   ├── Coerce.lua
        │   └── Actions/…
        ├── Components/         React UI (Library / Lesson / Settings)
        └── Schema/schema.json  bundled copy for client-side validation
```

## Build order

1. ✅ `schema.json` + `SCHEMA.md` — the contract.
2. ✅ Hand-authored `examples/raycast-basics/lesson.yaml` — stress-tests the schema.
3. 🟡 Plugin scaffold drafted:
    - ✅ `Playback/` — ResolvePath, Coerce, Focus, CodeEdit, Apply + all six Action
      appliers.
    - ✅ `Fetch/` — FetchIndex, FetchLesson, Validate (lightweight shape check).
    - ⏳ `Fetch/Yaml.lua` — **placeholder**; needs a real Luau YAML parser
      package wired in.
    - ⏳ `Components/` — React UI (Library / Lesson / Settings) not yet drafted.
      Needs a decision on Roact vs react-lua packaging first.
    - ✅ `Main.server.lua` — creates toolbar button + DockWidget; mount point ready.
4. ⏳ Docs site rendering (optional; static renderer of the same manifest).
5. ✅ Skill — `tutorial-bootstrap.md` + `tutorial-generate.md` drafted.
6. ⏳ Samples repo — 3–5 good samples, `index.json`, bundled `TutorialsPlace.rbxlx`.

## Open items before the plugin is runnable

- Pick a YAML parser and bundle it (`lua-yaml` port or equivalent) in
  `plugin/src/Packages/Yaml.lua`; replace `Fetch/Yaml.lua` stub with a
  thin re-export.
- Pick a React packaging (Roact vs `react-lua` + `react-roblox`) and add it
  to `plugin/src/Packages/`.
- Draft the three views: Library, LessonView (with StepList + DiffView +
  PromptStepView), Settings.
- Fill in `plugin/src/Main.server.lua` with the React mount call.
- Produce `TutorialsPlace.rbxlx` with the bundled asset folders
  (`ReplicatedStorage.TutorialAssets.raycast-basics.EmitterRig` etc.).
