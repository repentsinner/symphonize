#!/usr/bin/env python3
"""Validate the generated Codex plugin's installable files."""

from pathlib import Path
import json
import re

root = Path(__file__).resolve().parent.parent
plugin = root / "plugins/codex"
marketplace = json.loads((root / ".agents/plugins/marketplace.json").read_text())
entry = marketplace["plugins"][0]
assert marketplace["name"] == "symphonize"
assert entry["source"]["path"] == "./plugins/codex"
assert entry["source"]["source"] == "local"
manifest = json.loads((plugin / ".codex-plugin/plugin.json").read_text())
assert manifest["name"] == "symphonize"
assert manifest["skills"] == "./skills/"
assert manifest["version"] == json.loads((root / "plugins/symphonize/.claude-plugin/plugin.json").read_text())["version"]
skills = sorted((plugin / "skills").glob("*/SKILL.md"))
assert len(skills) == 11, len(skills)
for skill in skills:
    text = skill.read_text()
    assert re.match(r"---\nname: [a-z]+-[a-z]+\ndescription: .+\n---\n", text), skill
    assert "${CLAUDE_PLUGIN_ROOT}" not in text, skill
    assert "`.claude/worktrees/`" not in text, skill
for path in (
    "resources/notation/scripts/governance-lint.sh",
    "resources/notation/templates/release-please/release-please.yml",
    "resources/conduct/batch-agent.md",
):
    assert (plugin / path).is_file(), path
assert "PR URL" in (plugin / "skills/conduct-next/SKILL.md").read_text()
print("Codex package: 11 skills, manifest, marketplace, and resources valid")
