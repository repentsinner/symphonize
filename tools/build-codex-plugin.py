#!/usr/bin/env python3
"""Build small Codex skill adapters for the canonical plugin skills."""

from pathlib import Path
import json
import re
import shutil

ROOT = Path(__file__).resolve().parent.parent
SKILLS = ROOT / "skills"
SOURCES = {
    "notation": ("init", "lint"),
    "compose": ("discover", "plan", "roadmap", "triage", "review"),
    "conduct": ("next", "review", "clean"),
    "symphonize": ("feedback",),
}

version = json.loads((ROOT / "plugins/symphonize/.claude-plugin/plugin.json").read_text())["version"]
manifest = {
    "name": "symphonize",
    "version": version,
    "description": "Governance planning and delivery workflows for Codex",
    "skills": "./skills/",
}
(ROOT / ".codex-plugin/plugin.json").write_text(json.dumps(manifest, indent=2) + "\n")

if SKILLS.exists():
    shutil.rmtree(SKILLS)
SKILLS.mkdir()
for group, names in SOURCES.items():
    for name in names:
        source = ROOT / f"plugins/{group}/skills/{name}/SKILL.md"
        raw = source.read_text()
        match = re.match(r"\A---\n(.*?)\n---\n", raw, re.S)
        if not match:
            raise ValueError(f"missing frontmatter: {source}")
        description = next(
            (line.removeprefix("description: ") for line in match.group(1).splitlines() if line.startswith("description: ")),
            None,
        )
        if not description:
            raise ValueError(f"missing description: {source}")
        skill = SKILLS / f"{group}-{name}"
        skill.mkdir()
        if group == "conduct" and name == "next":
            source_path = "codex-src/next.md"
        else:
            source_path = f"plugins/{group}/skills/{name}/SKILL.md"
        body = f"""---
name: {group}-{name}
description: {description}
---

# {group}:{name}

Find the installed plugin root by walking up from this SKILL.md to the
nearest directory containing `.codex-plugin/plugin.json`. Read
`{source_path}` there in full and follow its workflow. Treat the user's text
after this skill's name as the command arguments.

For an existing git project, inspect its branch, working tree, remote state,
and open PRs before changing files. If the remote is unavailable, report that
limit before a change that depends on it. Follow the project's AGENTS.md.

Apply these Codex adaptations to the source instructions:

- A reference to `/${group}:{name}` means this skill. Other
  `/<group>:<command>` references mean `$symphonize:<group>-<command>`.
- `$1` means the user's arguments. Resolve `${{CLAUDE_PLUGIN_ROOT}}` to the
  installed plugin root's `plugins/{group}` directory. Resolve bundled
  scripts, templates, and protocols from that directory.
- Use Codex worktrees and subagents where available. Do not assume a
  `.claude/worktrees/` directory or a Claude-assigned branch name. Use
  `git worktree list` for discovery.
- The package has no automatic hook. Check repo state explicitly before
  changing an existing project. No `/goal` turn loop runs in Codex.
"""
        if group == "notation" and name == "init":
            body += """
When the source creates `.githooks/pre-commit`, replace its Claude cache
search with `$HOME/.codex/plugins/cache/*/*/*/plugins/notation/scripts/governance-lint.sh`.
The `GOVERNANCE_LINT` override remains valid.
"""
        (skill / "SKILL.md").write_text(body)

print(f"built {len(list(SKILLS.iterdir()))} Codex skill adapters")
