#!/usr/bin/env python3
"""Validate the Codex plugin entry points and shared source paths."""

from pathlib import Path
import json
import re

root = Path(__file__).resolve().parent.parent
marketplace = json.loads((root / ".agents/plugins/marketplace.json").read_text())
entry = marketplace["plugins"][0]
assert marketplace["name"] == "symphonize"
assert entry["source"] == {"source": "local", "path": "./"}
manifest = json.loads((root / ".codex-plugin/plugin.json").read_text())
assert manifest["name"] == "symphonize"
assert manifest["skills"] == "./skills/"
assert manifest["version"] == json.loads((root / "plugins/symphonize/.claude-plugin/plugin.json").read_text())["version"]
release_config = json.loads((root / "release-please-config.json").read_text())
assert {"type": "json", "path": "/.codex-plugin/plugin.json", "jsonpath": "$.version"} in release_config["packages"]["plugins/symphonize"]["extra-files"]
skills = sorted((root / "skills").glob("*/SKILL.md"))
assert len(skills) == 11, len(skills)
claude_skills = sorted((root / "plugins").glob("*/skills/*/SKILL.md"))
assert len(claude_skills) == 12, len(claude_skills)
assert not list((root / "plugins").glob("*/commands/*.md"))
for skill in claude_skills:
    assert re.match(rf"---\nname: {skill.parent.name}\n(?:argument-hint: .+\n)?description: .+\n---\n", skill.read_text()), skill
for skill in skills:
    text = skill.read_text()
    assert re.match(r"---\nname: [a-z]+-[a-z]+\ndescription: .+\n---\n", text), skill
    source = re.search(r"Read\n`([^`]+)` there in full", text)
    assert source, skill
    assert (root / source.group(1)).is_file(), skill
    assert len(text.splitlines()) < 55, skill
for path in (
    "plugins/notation/scripts/governance-lint.sh",
    "plugins/notation/templates/release-please/release-please.yml",
    "codex-src/batch-agent.md",
):
    assert (root / path).is_file(), path
print("Plugin package: 12 Claude skills, 11 Codex adapters, and shared files valid")
