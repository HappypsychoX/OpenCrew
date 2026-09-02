# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Versioning semantics:

- PATCH: bug fixes or prompt improvements
- MINOR: new agents or backward-compatible capabilities
- MAJOR: breaking changes to agent behavior, orchestration, or installation

## [Unreleased]

## [1.0.1]

### Added

- Parts Bin test application (React/Vite)

### Changed

- `crew-lead` OpenCode agent mode changed from `all` to `primary`

## [1.0.0]

### Added

- `repo-scout` worker (DeepSeek V4 Flash): read-only repository search and investigation
- `architect` worker (GLM-5.3-Flash): read-only design and implementation planning
- `implementer` worker (Kimi K2.7 Code): write-enabled implementation of approved plans
- `reviewer` worker (DeepSeek V4 Flash): read-only independent review of completed changes
- `grunt` worker (MiMo-V2.5): write-enabled mechanical and repetitive development work
- `crew-lead` role specification with delegation decision rules
- OpenCode adapter implementing the `crew-lead` role (DeepSeek V4 Pro)
- Install scripts for Windows (`install.ps1`) and Linux/macOS (`install.sh`)
- Uninstall scripts for Windows (`uninstall.ps1`) and Linux/macOS (`uninstall.sh`)
- Documentation: README, basic-usage example, delegation examples, and this changelog
