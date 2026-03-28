# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `/symphonize:lint` command — runs markdownlint on governance files locally
- `/symphonize:init` command — scaffolds governance files, CI workflows, and pre-commit hooks
- Reusable `governance-lint.yml` workflow (markdownlint, SPEC.md status lines, README headings)
- Template workflows: release-please, auto-merge-release, update-major-tag
- Pre-commit hook scaffolding via `.githooks/` and `core.hooksPath`
- Governance files (SPEC.md, ROADMAP.md, CHANGELOG.md)
- CI dogfooding own governance-lint workflow

### Changed

- README restructured: motivation before mechanics, added Opinions and Governance files sections
- `/symphonize:clean --full` delegates to `/symphonize:lint` instead of inline markdownlint
