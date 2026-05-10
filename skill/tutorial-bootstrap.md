---
description: Scaffold a new tutorial sample — create the folder layout, draft README.md from the source code if present. Does NOT generate lesson.yaml.
---

# /tutorial-bootstrap

Scaffolds a new tutorial sample. Run this **once** when starting a new sample.
Use `/tutorial-generate` afterwards (and on every README change) to produce
`lesson.yaml`.

## What this skill does

1. Figure out the sample folder (argument, or current directory).
2. Ensure the layout exists:
   ```
   <sample>/
   ├── default.project.json     # Rojo — created if missing
   ├── src/                     # authored code — left alone if present
   ├── README.md                # drafted if missing; left alone if present
   └── (lesson.yaml comes later, from /tutorial-generate)
   ```
3. If `src/` has code, read it and draft a `README.md` that describes what the
   sample is, what it shows, the named components (Parts, Scripts, Models),
   and the rough flow.
4. If `src/` is empty, write a short placeholder README prompting the author
   to fill it in.
5. **Never** overwrite an existing `README.md`. If one exists, say so and
   stop — the engineer should edit it themselves and rerun
   `/tutorial-generate` when ready.
6. **Never** create `lesson.yaml`. That's `/tutorial-generate`'s job.

## Arguments

- Optional: a path to the sample folder. If omitted, use the current working
  directory.

## README shape

The README is the contract for `/tutorial-generate`. Draft it with these
sections:

```markdown
# <Sample title>

<One paragraph: what this sample is and the one idea it teaches.>

## What it shows

- <bullet per API or concept demonstrated>

## Components

- **<InstancePath>** — <what it is, why it's there>

## Flow

1. <step the playback should take, in order>
2. ...

## Assets

- `<ReplicatedStorage.TutorialAssets.<sampleId>.<name>>` — <what it is>
  (or `rbxassetid://...` — <what it is>)
```

Keep it tight. Authors will edit it; that edited version is the source of
truth for `/tutorial-generate`.

## Rojo project

If `default.project.json` is missing, write a minimal one pointing at `src/`:

```json
{
  "name": "<sample-id>",
  "tree": {
    "$className": "DataModel",
    "Workspace": {
      "$path": "src"
    }
  }
}
```

Leave as-is if the author already has one.

## Non-goals

- Do not read or reference any existing `lesson.yaml` — it may be stale.
- Do not call out to any external services.
- Do not invent components that aren't in `src/`.
