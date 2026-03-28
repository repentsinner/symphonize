# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.13](https://github.com/repentsinner/symphonize/compare/v0.1.12...v0.1.13) (2026-03-28)


### Bug Fixes

* **ci:** replace Vale wget with vale-cli/vale-action ([#40](https://github.com/repentsinner/symphonize/issues/40)) ([6e86340](https://github.com/repentsinner/symphonize/commit/6e86340dae41d354a6490363da6b8a34eab8471e))

## [0.1.12](https://github.com/repentsinner/symphonize/compare/v0.1.11...v0.1.12) (2026-03-28)


### Features

* add Vale prose linter with IEEE modal verb rules ([#37](https://github.com/repentsinner/symphonize/issues/37)) ([825e06f](https://github.com/repentsinner/symphonize/commit/825e06f96b8ec259aafcf4ea18ab2378807b885e))

## [0.1.11](https://github.com/repentsinner/symphonize/compare/v0.1.10...v0.1.11) (2026-03-28)


### Features

* governance consistency (init, conventions, lint, markdownlint) ([#32](https://github.com/repentsinner/symphonize/issues/32)) ([9ff1145](https://github.com/repentsinner/symphonize/commit/9ff1145a665f0a307a531eaf9c60160fd36321cd))

## [0.1.10](https://github.com/repentsinner/symphonize/compare/v0.1.9...v0.1.10) (2026-03-28)


### Features

* integrate REQUIREMENTS.md into governance loop ([#28](https://github.com/repentsinner/symphonize/issues/28)) ([8560d72](https://github.com/repentsinner/symphonize/commit/8560d72bdbc7e347a422483a650d910203fd9550))


### Bug Fixes

* **discover:** support updating existing REQUIREMENTS.md ([#29](https://github.com/repentsinner/symphonize/issues/29)) ([472a97a](https://github.com/repentsinner/symphonize/commit/472a97a2b3353b7029f24366b4040d53bcee4cc9))

## [0.1.9](https://github.com/repentsinner/symphonize/compare/v0.1.8...v0.1.9) (2026-03-28)


### Features

* **commands:** add discover command ([#26](https://github.com/repentsinner/symphonize/issues/26)) ([e5d2655](https://github.com/repentsinner/symphonize/commit/e5d265575180cec40f7cec8e8f098fc67adf7bbe))

## [0.1.8](https://github.com/repentsinner/symphonize/compare/v0.1.7...v0.1.8) (2026-03-28)


### Features

* cross-document reference validation and traceability convention ([#23](https://github.com/repentsinner/symphonize/issues/23)) ([8b347d3](https://github.com/repentsinner/symphonize/commit/8b347d35d6772eb041293f20502a860c2311b2b0))

## [0.1.7](https://github.com/repentsinner/symphonize/compare/v0.1.6...v0.1.7) (2026-03-28)


### Features

* add /symphonize:init command ([9710df8](https://github.com/repentsinner/symphonize/commit/9710df872bd62a5e96d065312d4789fc853d5b66))
* add /symphonize:lint command ([4734fed](https://github.com/repentsinner/symphonize/commit/4734fed4928213053cb5d8aa887e441ab2541eee))
* add CONVENTIONS.md with self-contained governance rules ([#16](https://github.com/repentsinner/symphonize/issues/16)) ([a7f51bc](https://github.com/repentsinner/symphonize/commit/a7f51bcf65ab79179a8c69b291af92563fa72752))
* add pre-commit hook scaffolding to /symphonize:init ([6fec7c2](https://github.com/repentsinner/symphonize/commit/6fec7c2c4d347f5d5f50c89fa3fb6acba53702b5))
* add reusable CI workflows and release-please config ([a0a769f](https://github.com/repentsinner/symphonize/commit/a0a769fc20464b67e293f1e0666b01f52ce29481))
* add self-hosted marketplace manifest ([fdbf249](https://github.com/repentsinner/symphonize/commit/fdbf24981c3e7c31d6b36f425d38d8ed8d8c13d7))
* batch — self-contained conventions (batch-agent, commands, slug-sections) ([#18](https://github.com/repentsinner/symphonize/issues/18)) ([5eeed2c](https://github.com/repentsinner/symphonize/commit/5eeed2c50e9c3a6f2133528dc592086b909525a1))
* dogfood governance-lint CI and update README ([e075723](https://github.com/repentsinner/symphonize/commit/e0757239c8335ebc795dfbc7125eb7db50ecb252))
* initial plugin scaffold ([90fd6fd](https://github.com/repentsinner/symphonize/commit/90fd6fd1b6d37e5acedc009883f0a026b9b426f2))
* integrate governance lint into symphonize ([20842ec](https://github.com/repentsinner/symphonize/commit/20842ec821e01423c009e5ab133fb0d9a9096748))
* simplify lint, add pre-commit hook scaffolding ([0ef43da](https://github.com/repentsinner/symphonize/commit/0ef43daa619c52bd2c7218684e3a20c45599898c))


### Bug Fixes

* configure release-please to update plugin.json version ([914aeec](https://github.com/repentsinner/symphonize/commit/914aeec09949e4daa27631bb69ab7e0b960efbd0))
* release-please updates plugin.json version ([411e1e9](https://github.com/repentsinner/symphonize/commit/411e1e95138d6c63293b9b1f317749921f27f0bf))
* resolve markdownlint violations in governance files ([6a49443](https://github.com/repentsinner/symphonize/commit/6a49443666ba989ad11d8d0374e61193857e4104))
* restore RELEASE_PLEASE_PAT token ([ab44a61](https://github.com/repentsinner/symphonize/commit/ab44a61daeabed576922aab2bdc4396a803b229f))
* run clean --lite before starting orchestrate loop ([#14](https://github.com/repentsinner/symphonize/issues/14)) ([0cabd3b](https://github.com/repentsinner/symphonize/commit/0cabd3bc04b3f1f8ba38f9ef90e06392aa98f5a3))
* simplify /lint to just run markdownlint ([6780522](https://github.com/repentsinner/symphonize/commit/6780522f71c299c98f9d77a10e211ad9c814c790))
* switch release workflows to GitHub App token ([0200935](https://github.com/repentsinner/symphonize/commit/020093529b9c6fcfbcb32c30e6fc029f5f34a80e))
* switch release workflows to GitHub App token ([fab227e](https://github.com/repentsinner/symphonize/commit/fab227edb9f003ac6a695e191d58f2fd374c406a))
* use './' for self-referencing plugin source ([be55681](https://github.com/repentsinner/symphonize/commit/be55681a955b3635ec19860e739e2af3a0642fe4))
* use pull_request_target for auto-merge trigger ([43eda2f](https://github.com/repentsinner/symphonize/commit/43eda2f3646a510cdfbce3a55f730baa79241908))
* use pull_request_target for auto-merge trigger ([d80df10](https://github.com/repentsinner/symphonize/commit/d80df10821195f4f0af5962551a983d04f36d90f))

## [0.1.6](https://github.com/repentsinner/symphonize/compare/v0.1.5...v0.1.6) (2026-03-28)


### Features

* batch — self-contained conventions (batch-agent, commands, slug-sections) ([#18](https://github.com/repentsinner/symphonize/issues/18)) ([5eeed2c](https://github.com/repentsinner/symphonize/commit/5eeed2c50e9c3a6f2133528dc592086b909525a1))

## [0.1.5](https://github.com/repentsinner/symphonize/compare/v0.1.4...v0.1.5) (2026-03-28)


### Features

* add CONVENTIONS.md with self-contained governance rules ([#16](https://github.com/repentsinner/symphonize/issues/16)) ([a7f51bc](https://github.com/repentsinner/symphonize/commit/a7f51bcf65ab79179a8c69b291af92563fa72752))

## [0.1.4](https://github.com/repentsinner/symphonize/compare/v0.1.3...v0.1.4) (2026-03-28)


### Bug Fixes

* run clean --lite before starting orchestrate loop ([#14](https://github.com/repentsinner/symphonize/issues/14)) ([0cabd3b](https://github.com/repentsinner/symphonize/commit/0cabd3bc04b3f1f8ba38f9ef90e06392aa98f5a3))

## [0.1.3](https://github.com/repentsinner/symphonize/compare/v0.1.2...v0.1.3) (2026-03-28)


### Bug Fixes

* switch release workflows to GitHub App token ([0200935](https://github.com/repentsinner/symphonize/commit/020093529b9c6fcfbcb32c30e6fc029f5f34a80e))
* switch release workflows to GitHub App token ([fab227e](https://github.com/repentsinner/symphonize/commit/fab227edb9f003ac6a695e191d58f2fd374c406a))
* use pull_request_target for auto-merge trigger ([43eda2f](https://github.com/repentsinner/symphonize/commit/43eda2f3646a510cdfbce3a55f730baa79241908))
* use pull_request_target for auto-merge trigger ([d80df10](https://github.com/repentsinner/symphonize/commit/d80df10821195f4f0af5962551a983d04f36d90f))

## [0.1.2](https://github.com/repentsinner/symphonize/compare/v0.1.1...v0.1.2) (2026-03-28)


### Bug Fixes

* configure release-please to update plugin.json version ([914aeec](https://github.com/repentsinner/symphonize/commit/914aeec09949e4daa27631bb69ab7e0b960efbd0))
* release-please updates plugin.json version ([411e1e9](https://github.com/repentsinner/symphonize/commit/411e1e95138d6c63293b9b1f317749921f27f0bf))
* restore RELEASE_PLEASE_PAT token ([ab44a61](https://github.com/repentsinner/symphonize/commit/ab44a61daeabed576922aab2bdc4396a803b229f))

## [0.1.1](https://github.com/repentsinner/symphonize/compare/v0.1.0...v0.1.1) (2026-03-28)


### Features

* add /symphonize:init command ([9710df8](https://github.com/repentsinner/symphonize/commit/9710df872bd62a5e96d065312d4789fc853d5b66))
* add /symphonize:lint command ([4734fed](https://github.com/repentsinner/symphonize/commit/4734fed4928213053cb5d8aa887e441ab2541eee))
* add pre-commit hook scaffolding to /symphonize:init ([6fec7c2](https://github.com/repentsinner/symphonize/commit/6fec7c2c4d347f5d5f50c89fa3fb6acba53702b5))
* add reusable CI workflows and release-please config ([a0a769f](https://github.com/repentsinner/symphonize/commit/a0a769fc20464b67e293f1e0666b01f52ce29481))
* add self-hosted marketplace manifest ([fdbf249](https://github.com/repentsinner/symphonize/commit/fdbf24981c3e7c31d6b36f425d38d8ed8d8c13d7))
* dogfood governance-lint CI and update README ([e075723](https://github.com/repentsinner/symphonize/commit/e0757239c8335ebc795dfbc7125eb7db50ecb252))
* initial plugin scaffold ([90fd6fd](https://github.com/repentsinner/symphonize/commit/90fd6fd1b6d37e5acedc009883f0a026b9b426f2))
* integrate governance lint into symphonize ([20842ec](https://github.com/repentsinner/symphonize/commit/20842ec821e01423c009e5ab133fb0d9a9096748))
* simplify lint, add pre-commit hook scaffolding ([0ef43da](https://github.com/repentsinner/symphonize/commit/0ef43daa619c52bd2c7218684e3a20c45599898c))


### Bug Fixes

* resolve markdownlint violations in governance files ([6a49443](https://github.com/repentsinner/symphonize/commit/6a49443666ba989ad11d8d0374e61193857e4104))
* simplify /lint to just run markdownlint ([6780522](https://github.com/repentsinner/symphonize/commit/6780522f71c299c98f9d77a10e211ad9c814c790))
* use './' for self-referencing plugin source ([be55681](https://github.com/repentsinner/symphonize/commit/be55681a955b3635ec19860e739e2af3a0642fe4))

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
