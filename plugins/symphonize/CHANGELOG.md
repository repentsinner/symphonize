# Changelog

## [0.2.1](https://github.com/repentsinner/symphonize/compare/symphonize--v0.2.0...symphonize--v0.2.1) (2026-06-07)


### Miscellaneous Chores

* **symphonize:** Synchronize symphonize-plugins versions

## [0.2.0](https://github.com/repentsinner/symphonize/compare/symphonize--v0.1.39...symphonize--v0.2.0) (2026-06-05)


### ⚠ BREAKING CHANGES

* the monolithic /symphonize:* command namespace is retired. Commands now resolve under their plugin — /notation:init|lint, /compose:discover|plan|roadmap|triage|review, /conduct:next|orchestrate|clean|review, and /symphonize:feedback. Installing the symphonize plugin pulls all four layers; install notation, compose, or conduct individually for a subset.

### Features

* batch — extract the compose plugin ([#147](https://github.com/repentsinner/symphonize/issues/147)) ([c5c5fec](https://github.com/repentsinner/symphonize/commit/c5c5fec1b2cc0c8d2882ab0ec661ee18e083fedc))
* **conduct:** extract conduct plugin with execution commands, protocol, and hook ([#148](https://github.com/repentsinner/symphonize/issues/148)) ([547f31b](https://github.com/repentsinner/symphonize/commit/547f31b06565a0e22add858c1a480da9a2e3c25c))
* **symphonize:** wire the umbrella plugin's dependencies on compose and conduct ([#149](https://github.com/repentsinner/symphonize/issues/149)) ([ed0d8a5](https://github.com/repentsinner/symphonize/commit/ed0d8a5757cfd03a814c48b48c4f037aef5d6f55))


### Documentation

* document the four-plugin namespaces and add the umbrella plugin readme ([#157](https://github.com/repentsinner/symphonize/issues/157)) ([bc017a6](https://github.com/repentsinner/symphonize/commit/bc017a6760b43a1a64f6799304f04b4827685cdf))
