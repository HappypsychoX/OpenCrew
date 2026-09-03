# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Versioning semantics:

- PATCH: bug fixes or prompt improvements
- MINOR: new agents or backward-compatible capabilities
- MAJOR: breaking changes to agent behavior, orchestration, or installation

## [Unreleased]

### Added

- Claude Code runtime: `crew-lead` and all five workers can now be installed
  into `~/.claude/agents/`, with Opus leading and Sonnet/Haiku backing the
  workers
- Runtime selection at install time (`-Runtime` / `--runtime`, prompted when
  omitted) for both the installers and the uninstallers
- `runtimes/<runtime>/` manifests holding everything runtime-specific:
  install target, per-agent model and temperature, frontmatter templates,
  delegation wording, and optional runtime-level permission rules
- Capability classes (`lead`, `investigate`, `review`, `write`) as the default
  source of agent frontmatter, with per-agent overrides
  (`frontmatter/<agent>.yml`) when a class is not precise enough
- Claude Code installs write `git push` / `git commit` deny rules, preserving
  existing rules. Scope is selectable with `-PermissionScope` /
  `--permission-scope` (`project` default, `user`, `none`); project scope
  targets the current repository's `.claude/settings.json` so the rules do not
  apply to every Claude Code session on the machine
- Installers fail with a clear error if a template leaves an unsubstituted
  `{{TOKEN}}`, instead of shipping it verbatim into an agent file

### Changed

- Agent prompts are now runtime-neutral: `agents/*.md` declare only
  `description` and `capability`, and the installer renders the runtime
  frontmatter around them
- `crew-lead/opencode.md` replaced by `crew-lead/body.md` plus
  `runtimes/opencode/`; the OpenCode adapter is now generated rather than
  stored, removing the second source of truth for the lead prompt
- `install.sh` and `install.ps1` produce byte-identical output, and the
  rendered OpenCode agents are byte-identical to the 1.0.1 files

### Notes

- On Claude Code, `grunt` and `implementer` share the `write` class; the
  narrower `grunt` command allowlist exists only on OpenCode. Verified as a
  platform limit: tool-level grants are enforced (an agent without `Bash`
  cannot run commands), but the command specifier in a `Bash(...)` grant is
  ignored and grants `Bash` wholesale.
- `install.sh` uses `jq` to merge Claude Code permission rules. Without `jq`
  the install still succeeds and prints the rules to add by hand.

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
