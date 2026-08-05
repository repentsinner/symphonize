# Manual release template

Empty by design. The `manual` option scaffolds no release-automation
files — no workflow, no config, no manifest. `/notation:init` still
creates CHANGELOG.md with its `[Unreleased]` section; the adopter
edits it and tags releases by hand.

This directory exists so the three release-automation options share one
`templates/<tool>/` shape. See SPEC.md §spec:release-automation-options.
