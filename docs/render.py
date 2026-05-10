#!/usr/bin/env python3
"""Render lesson.json files as static HTML articles.

Usage:
    python3 docs/render.py                 # render every examples/* into docs/html/
    python3 docs/render.py examples/foo    # render a single sample folder

Output lands in docs/html/<sample-id>/index.html plus an index page at
docs/html/index.html. Pure stdlib — no build step, no dependencies.
"""

from __future__ import annotations

import html
import json
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
EXAMPLES = REPO / "examples"
OUT = REPO / "docs" / "html"

CSS = """
:root { color-scheme: dark; }
* { box-sizing: border-box; }
body {
  margin: 0;
  padding: 0;
  font-family: ui-sans-serif, system-ui, -apple-system, "Segoe UI", Roboto, sans-serif;
  background: #1a1a1a;
  color: #e0e0e0;
  line-height: 1.55;
}
main { max-width: 780px; margin: 0 auto; padding: 40px 24px 80px; }
header.page { margin-bottom: 32px; }
header.page h1 { font-size: 32px; margin: 0 0 6px; }
header.page p.goal { color: #9a9a9a; margin: 0; font-size: 16px; }
header.page p.meta { color: #6a6a6a; margin: 6px 0 0; font-size: 13px; }
nav a { color: #9ac3ff; text-decoration: none; }
nav a:hover { text-decoration: underline; }

section.step {
  margin: 32px 0;
  padding: 20px 22px;
  background: #232323;
  border-radius: 8px;
  border-left: 4px solid var(--accent, #555);
}
section.step.narrative { --accent: #888; }
section.step.scripted  { --accent: #6a9ed0; }
section.step.codeEdit  { --accent: #b07fd0; }
section.step.prompt    { --accent: #d1a060; }
section.step h2 {
  font-size: 16px;
  margin: 0 0 4px;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: #a8a8a8;
}
section.step h2 .id { color: #666; font-weight: 400; margin-left: 6px; }
section.step .body { font-size: 15px; margin: 8px 0 0; white-space: pre-wrap; }
section.step .explain {
  font-size: 13px;
  color: #bdbdbd;
  background: #1c1c1c;
  padding: 10px 14px;
  border-radius: 4px;
  margin-top: 12px;
}

pre, code { font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace; }
pre {
  background: #141414;
  padding: 14px 16px;
  border-radius: 4px;
  overflow-x: auto;
  font-size: 13px;
  line-height: 1.4;
  margin: 12px 0 0;
}
pre.prompt { border-left: 3px solid #d1a060; color: #cfe3ff; }

.action-head {
  font-size: 12px;
  text-transform: uppercase;
  letter-spacing: 0.06em;
  color: #8aa;
  margin: 12px 0 4px;
}
.focus {
  font-size: 12px;
  color: #888;
  margin-top: 10px;
}
.focus strong { color: #aaa; }

.tags { margin-top: 6px; }
.tag {
  display: inline-block;
  background: #2d2d2d;
  color: #c0c0c0;
  font-size: 11px;
  padding: 2px 8px;
  border-radius: 10px;
  margin-right: 4px;
}

ul.lesson-index { list-style: none; padding: 0; }
ul.lesson-index li {
  padding: 14px 16px;
  background: #232323;
  border-radius: 6px;
  margin-bottom: 8px;
}
ul.lesson-index li a { color: #e0e0e0; text-decoration: none; font-weight: 600; }
ul.lesson-index li p { margin: 4px 0 0; color: #9a9a9a; font-size: 14px; }
""".strip()


def load_lesson(path: Path) -> dict | None:
    """Prefer lesson.json; fall back to yaml only if we can import it."""
    json_path = path / "lesson.json"
    if json_path.exists():
        return json.loads(json_path.read_text())
    yaml_path = path / "lesson.yaml"
    if yaml_path.exists():
        try:
            import yaml  # type: ignore
        except ImportError:
            print(f"  skip {path.name}: lesson.json missing and PyYAML not installed")
            return None
        return yaml.safe_load(yaml_path.read_text())
    return None


def escape(s: str) -> str:
    return html.escape(s, quote=True)


def render_value(value) -> str:
    if isinstance(value, str):
        return escape(value)
    return escape(json.dumps(value))


def render_action(action: dict) -> str:
    op = action.get("op", "?")
    rows = [f'<div class="action-head">action: {escape(op)}</div>']
    pretty = json.dumps(action, indent=2)
    rows.append(f"<pre>{escape(pretty)}</pre>")
    return "\n".join(rows)


def render_focus(focus: dict | None) -> str:
    if not focus:
        return ""
    parts = []
    sel = focus.get("selection")
    if sel:
        if isinstance(sel, list):
            parts.append("Select: " + ", ".join(f"<code>{escape(s)}</code>" for s in sel))
        else:
            parts.append(f"Select: <code>{escape(sel)}</code>")
    script = focus.get("script")
    if script:
        line_range = ""
        if "startLine" in script:
            end = script.get("endLine", script["startLine"])
            line_range = f" (lines {script['startLine']}–{end})"
        parts.append(f"Open script: <code>{escape(script['path'])}</code>{line_range}")
    if not parts:
        return ""
    return f'<div class="focus"><strong>Focus:</strong> ' + " · ".join(parts) + "</div>"


def render_step(step: dict) -> str:
    t = step.get("type", "?")
    step_id = step.get("id", "?")
    body = step.get("body", "")
    explain = step.get("explain")

    pieces = [
        f'<section class="step {escape(t)}">',
        f'<h2>{escape(t)}<span class="id">#{escape(step_id)}</span></h2>',
        f'<div class="body">{escape(body)}</div>',
    ]

    if t == "scripted":
        action = step.get("action", {})
        pieces.append(render_action(action))
    elif t == "codeEdit":
        target = step.get("target", {})
        path = target.get("path", "?")
        pieces.append(f'<div class="action-head">edit: <code>{escape(path)}</code></div>')
        src = step.get("source", "")
        pieces.append(f"<pre><code>{escape(src)}</code></pre>")
    elif t == "prompt":
        p = step.get("suggestedPrompt", "")
        pieces.append('<div class="action-head">copy to assistant:</div>')
        pieces.append(f'<pre class="prompt">{escape(p)}</pre>')

    if explain:
        pieces.append(f'<div class="explain">{escape(explain)}</div>')
    pieces.append(render_focus(step.get("focus")))
    pieces.append("</section>")
    return "\n".join(p for p in pieces if p)


def render_lesson_page(lesson: dict) -> str:
    tags = lesson.get("tags") or []
    tag_html = (
        '<div class="tags">'
        + "".join(f'<span class="tag">{escape(t)}</span>' for t in tags)
        + "</div>"
        if tags
        else ""
    )
    steps_html = "\n".join(render_step(s) for s in lesson.get("steps", []))
    title = escape(lesson.get("title", ""))
    goal = lesson.get("goal") or ""
    goal_html = f'<p class="goal">{escape(goal)}</p>' if goal else ""
    return f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>{title}</title>
<style>{CSS}</style>
</head>
<body>
<main>
<nav><a href="../index.html">← All lessons</a></nav>
<header class="page">
<h1>{title}</h1>
{goal_html}
<p class="meta">id: <code>{escape(lesson.get("id", ""))}</code> · {len(lesson.get("steps", []))} steps</p>
{tag_html}
</header>
{steps_html}
</main>
</body>
</html>
"""


def render_index(lessons: list[tuple[str, dict]]) -> str:
    items = []
    for slug, lesson in lessons:
        title = escape(lesson.get("title", slug))
        goal = escape(lesson.get("goal") or "")
        items.append(
            f'<li><a href="{escape(slug)}/index.html">{title}</a>'
            f'<p>{goal}</p></li>'
        )
    body = "\n".join(items)
    return f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Tutorials</title>
<style>{CSS}</style>
</head>
<body>
<main>
<header class="page">
<h1>Tutorials</h1>
<p class="goal">{len(lessons)} lessons available.</p>
</header>
<ul class="lesson-index">
{body}
</ul>
</main>
</body>
</html>
"""


def render_all(targets: list[Path]) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    rendered: list[tuple[str, dict]] = []
    for folder in targets:
        lesson = load_lesson(folder)
        if lesson is None:
            continue
        slug = folder.name
        dest = OUT / slug
        dest.mkdir(parents=True, exist_ok=True)
        (dest / "index.html").write_text(render_lesson_page(lesson))
        rendered.append((slug, lesson))
        print(f"  rendered {slug} ({len(lesson.get('steps', []))} steps)")
    (OUT / "index.html").write_text(render_index(rendered))
    print(f"→ wrote {len(rendered)} lesson(s) + index to {OUT.relative_to(REPO)}")


def main() -> None:
    if len(sys.argv) > 1:
        targets = [Path(arg) for arg in sys.argv[1:]]
    else:
        targets = [p for p in sorted(EXAMPLES.iterdir()) if p.is_dir()]
    render_all(targets)


if __name__ == "__main__":
    main()
