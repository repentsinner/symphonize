#!/usr/bin/env python3
"""Build the Codex skill package from the Claude command sources."""

from pathlib import Path
import json
import re
import shutil

ROOT = Path(__file__).resolve().parent.parent
OUTPUT = ROOT / "plugins/codex"
SOURCES = {
    "notation": ("init", "lint"),
    "compose": ("discover", "plan", "roadmap", "triage", "review"),
    "conduct": ("next", "review", "clean"),
    "symphonize": ("feedback",),
}


def adapt(body: str) -> str:
    for group, names in SOURCES.items():
        for name in names:
            body = body.replace(f"/{group}:{name}", f"$symphonize:{group}-{name}")
    body = body.replace("${CLAUDE_PLUGIN_ROOT}/templates/", "resources/notation/templates/")
    body = body.replace("${CLAUDE_PLUGIN_ROOT}/protocols/batch-agent.md", "the installed plugin's resources/conduct/batch-agent.md")
    body = body.replace("$1", "the user's arguments after the skill invocation")
    body = body.replace("`.claude/worktrees/`", "linked worktrees shown by `git worktree list`")
    body = body.replace(".claude/worktrees/", "linked worktrees shown by `git worktree list`")
    body = body.replace("$HOME\"/.claude/plugins/cache/*/notation/scripts/governance-lint.sh", "$HOME\"/.codex/plugins/cache/*/*/*/resources/notation/scripts/governance-lint.sh")
    body = body.replace("outside Claude Code", "outside the agent session")
    body = body.replace("${CLAUDE_PLUGIN_ROOT} is unset", "the plugin root is not set")
    body = body.replace("`/conduct:orchestrate` does so before starting its loop.", "Run lite mode before repeated manual batch execution.")
    body = body.replace("or `/conduct:orchestrate`", "or repeated manual batches")
    body = body.replace("`/symphonize:<command>`", "the applicable `$symphonize:<skill>`")
    body = body.replace("from linked worktrees shown by `git worktree list` and their\n   backing git worktrees", "shown by `git worktree list`")
    body = body.replace("linked worktrees shown by `git worktree list` worktree directories", "linked worktrees shown by `git worktree list`")
    return body


if OUTPUT.exists():
    shutil.rmtree(OUTPUT)
(OUTPUT / ".codex-plugin").mkdir(parents=True)
(OUTPUT / "skills").mkdir()
(OUTPUT / "resources/notation").mkdir(parents=True)
(OUTPUT / "resources/conduct").mkdir(parents=True)

version = json.loads((ROOT / "plugins/symphonize/.claude-plugin/plugin.json").read_text())["version"]
manifest = {
    "name": "symphonize",
    "version": version,
    "description": "Governance planning and delivery workflows for Codex",
    "skills": "./skills/",
}
(OUTPUT / ".codex-plugin/plugin.json").write_text(json.dumps(manifest, indent=2) + "\n")

for group, names in SOURCES.items():
    for name in names:
        source = ROOT / f"plugins/{group}/commands/{name}.md"
        raw = source.read_text()
        match = re.match(r"\A---\n(.*?)\n---\n", raw, re.S)
        if not match:
            raise ValueError(f"missing frontmatter: {source}")
        description = next((line.removeprefix("description: ") for line in match.group(1).splitlines() if line.startswith("description: ")), None)
        if not description:
            raise ValueError(f"missing description: {source}")
        skill = OUTPUT / "skills" / f"{group}-{name}"
        skill.mkdir()
        if group == "conduct" and name == "next":
            body = (ROOT / "codex-src/next.md").read_text()
        else:
            body = adapt(raw[match.end():])
        if group == "notation" and name == "lint":
            body = body.replace("`scripts/governance-lint.sh", "`resources/notation/scripts/governance-lint.sh")
            body = body.replace("It lives beside this command in the notation plugin.", "Resolve the path from the installed plugin root.")
        preface = (
            f"---\nname: {group}-{name}\ndescription: {description}\n---\n\n"
            f"# {group}:{name}\n\n"
            "Use this workflow for the named Symphonize task. Resolve paths under this installed plugin from this SKILL.md file. "
            "Treat the user's text after the skill name as its arguments. Follow the project AGENTS.md instructions. "
            "Before changing an existing git project, inspect its branch, working tree, remote state, and open PRs. "
            "If the remote is unavailable, report that limit before making a change that depends on it.\n\n"
        )
        (skill / "SKILL.md").write_text(preface + body)

(OUTPUT / "resources/notation/scripts").mkdir()
shutil.copy2(ROOT / "plugins/notation/scripts/governance-lint.sh", OUTPUT / "resources/notation/scripts/governance-lint.sh")
shutil.copytree(ROOT / "plugins/notation/templates", OUTPUT / "resources/notation/templates")
shutil.copy2(ROOT / "codex-src/batch-agent.md", OUTPUT / "resources/conduct/batch-agent.md")
print(f"built {len(list((OUTPUT / 'skills').iterdir()))} Codex skills")
