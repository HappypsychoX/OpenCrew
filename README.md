# OpenCrew

A small, reusable multi-agent development workflow.

## What is OpenCrew?

OpenCrew is a set of specialized development agents coordinated by a single
lead agent called `crew-lead`. You talk to `crew-lead`; it decides which of
the other workers (if any) your task actually needs, and reports the result
back to you.

The key idea is that `crew-lead` is a **role**, not a specific model or
runtime. The role is defined once in `crew-lead/role.md`, and each supported
runtime provides an adapter that implements it. Choosing a runtime at install
time does not change the crew, the delegation rules, or the worker names.

Supported runtimes:

| Runtime | Lead model | Agents installed to |
|---|---|---|
| Claude Code | Opus | `~/.claude/agents/` |
| OpenCode | DeepSeek V4 Pro | `~/.config/opencode/agents/` |

OpenCrew optimizes for useful delegation, not maximum agent activity.

## How it works

When you ask `crew-lead` for something, it:

1. Understands your complete objective
2. Decides whether delegation is useful
3. Selects the appropriate workers
4. Gives each worker a narrow assignment
5. Evaluates their results
6. Resolves disagreements and approves implementation decisions
7. Verifies the finished work and reports back

`crew-lead` remains responsible for the final technical decision. Workers
provide evidence, implementation, and review; they are not authoritative.

## Repository layout

Agent prompts are runtime-neutral. Everything runtime-specific lives under
`runtimes/`, and the installer renders the two together.

```text
crew-lead/role.md         Runtime-neutral specification of the lead role
crew-lead/body.md         Shared lead prompt (contains substitution tokens)
agents/*.md               Five worker prompts: description + capability + prose
runtimes/<runtime>/
    runtime.conf          Install target, model per agent, temperature overrides
    frontmatter/*.yml     Frontmatter templates, per capability class or per agent
    delegation.md         How this runtime delegates
    settings-permissions.json   Optional runtime-level permission rules
```

Each agent declares a **capability class** rather than concrete permissions:

| Class | Agents | Meaning |
|---|---|---|
| `lead` | crew-lead | Delegates; may make trivial direct edits |
| `investigate` | repo-scout, architect | Read-only, no test execution |
| `review` | reviewer | Read-only, may run approved tests |
| `write` | implementer, grunt | May edit files and run builds/tests |

A runtime can override any single agent by adding `frontmatter/<agent>.yml`;
the per-agent file wins over the class default. OpenCode uses this to keep
`grunt` narrower than `implementer` and to keep `architect` narrower than
`repo-scout`.

Adding a new runtime (Codex, for example) means adding one `runtimes/codex/`
directory. It requires no changes to the six agent prompts.

## Installation

Requirements: the runtime you are installing for must be installed.

1. Clone the repository:

   ```
   git clone https://github.com/<owner>/OpenCrew.git
   cd OpenCrew
   ```

2. Run the installer for your platform. It prompts for a runtime if you do
   not name one.

   Windows:

   ```powershell
   .\scripts\install.ps1
   .\scripts\install.ps1 -Runtime claude
   .\scripts\install.ps1 -Runtime opencode -Force
   ```

   Linux/macOS:

   ```bash
   ./scripts/install.sh
   ./scripts/install.sh --runtime claude
   ./scripts/install.sh --runtime opencode --force
   ```

The installer renders `crew-lead` and the five workers for the chosen runtime
and writes them to that runtime's agents directory. It asks before replacing
existing OpenCrew files unless force mode is used.

For Claude Code it also writes `git push` / `git commit` deny rules, preserving
any rules already present. By default these go to the **current repository's**
`.claude/settings.json`, so they apply where you run OpenCrew rather than to
every Claude Code session on the machine. Re-run the installer in each
repository where you want the guard.

```powershell
.\scripts\install.ps1 -Runtime claude -PermissionScope project   # default
.\scripts\install.ps1 -Runtime claude -PermissionScope user      # machine-wide
.\scripts\install.ps1 -Runtime claude -PermissionScope none      # skip
```

```bash
./scripts/install.sh --runtime claude --permission-scope project  # default
./scripts/install.sh --runtime claude --permission-scope user     # machine-wide
./scripts/install.sh --runtime claude --permission-scope none     # skip
```

Agents always install to the user-global agents directory; only the permission
rules are scoped.

> **Note:** `install.sh` needs [`jq`](https://jqlang.github.io/jq/) to merge
> those rules. Without it the install still succeeds, and the rules are
> printed for you to add by hand. `install.ps1` needs no extra tools.

## Meet the crew

The names and responsibilities are identical on every runtime. Only the
backing model changes.

| Agent | Access | Claude Code | OpenCode | Role |
|---|---|---|---|---|
| crew-lead | orchestration | Opus | DeepSeek V4 Pro | Primary orchestrator; decides delegation and approves decisions |
| repo-scout | read-only | Haiku | DeepSeek V4 Flash | Searches and understands repositories; traces code paths; investigates bugs |
| architect | read-only | Opus | GLM-5.3-Flash | Designs implementation approaches; evaluates alternatives and risks |
| implementer | write-enabled | Sonnet | Kimi K2.7 Code | Executes an approved plan; edits files and runs builds and tests |
| reviewer | read-only | Sonnet | DeepSeek V4 Flash | Independently inspects completed changes for bugs and regressions |
| grunt | write-enabled | Haiku | MiMo-V2.5 | Handles repetitive or mechanical work: lint fixes, renames, boilerplate |

Model assignments live in `runtimes/<runtime>/runtime.conf`. The Claude Code
manifest uses generation aliases (`opus`, `sonnet`, `haiku`) so OpenCrew keeps
working when a new generation ships; replace them with pinned IDs
(`claude-opus-5`, `claude-sonnet-5`, `claude-haiku-4-5`) if you want
reproducible installs.

## Using crew-lead

The normal experience is a single request to the lead.

OpenCode:

```
@crew-lead Explain how authentication works in this repository.
```

Claude Code — run the session *as* `crew-lead` rather than delegating to it,
so it owns the conversation the way a primary agent does:

```bash
claude --agent crew-lead
```

```bash
claude -p --agent crew-lead "Explain how authentication works in this repository."
```

To make it the default for every session, set `"agent": "crew-lead"` in
`~/.claude/settings.json`; `--agent` overrides it per run.

You do not need to manually coordinate the crew. `crew-lead` chooses a
delegation plan based on the task. Trivial edits are handled directly;
mechanical work goes to `grunt`; more involved tasks may fan out to several
workers.

## Direct worker usage

You can also invoke workers directly for testing or specialized use.

OpenCode:

```
@repo-scout Trace the authentication flow. Do not modify anything.
@architect Design a minimal approach for session expiration. Do not modify files.
@reviewer Review the current changes for regressions and missing tests.
```

Claude Code:

```
Use the repo-scout subagent to trace the authentication flow. Do not modify anything.
```

## Example workflows

A trivial edit:

```
Fix the typo "Serach" in this button.

crew-lead
    ↓
fixes typo
```

A non-trivial feature:

```
Add automatic session expiration.

crew-lead
    ├─ repo-scout
    ├─ architect
    ├─ implementer
    └─ reviewer
```

See `examples/basic-usage.md` and `examples/delegation-examples.md` for the
full walkthroughs and the decision rules behind each path.

## Updating

Pull the latest changes and re-run the installer for your runtime. Use force
mode to overwrite existing OpenCrew files:

```powershell
.\scripts\install.ps1 -Runtime claude -Force
```

```bash
./scripts/install.sh --runtime claude --force
```

## Uninstalling

Run the uninstaller for your platform. It prompts for a runtime if you do not
name one:

```powershell
.\scripts\uninstall.ps1 -Runtime claude
```

```bash
./scripts/uninstall.sh --runtime claude
```

The uninstaller removes only the six OpenCrew-managed agent files. It does not
delete the agents directory or any of your own agents, and it leaves
`settings.json` untouched — remove the git deny rules by hand if you no longer
want them.

## Security considerations

- No OpenCrew agent can run `git push`.
- `git commit` is denied by default for all agents.
- You decide when work should be committed or published.
- Read-only workers (`repo-scout`, `architect`, `reviewer`) cannot modify files.
- Workers cannot invoke other workers; all delegation flows through `crew-lead`.
- Workers escalate back to `crew-lead` when a task exceeds their role.

How those last two are enforced differs by runtime:

| Guarantee | Claude Code | OpenCode |
|---|---|---|
| No worker-to-worker delegation | Workers are not granted the `Task` tool | `task: deny` in agent frontmatter |
| Read-only workers cannot edit | No `Edit`/`Write` in the tool grant | `edit: deny` in agent frontmatter |
| No `git push` / `git commit` | `permissions.deny` in `settings.json` | Per-agent `bash` deny rules |

One Claude Code caveat worth knowing:

**`grunt` is not narrower than `implementer` here.** On OpenCode, `grunt` gets
a deliberately smaller command allowlist. On Claude Code both resolve to the
same `write` class, and the distinction rests on the prompt body alone.

This is a platform limit, not an oversight. Tested directly: an agent granted
`tools: ["Read"]` correctly cannot run shell commands, so tool-level grants
*are* enforced — but an agent granted `tools: ["Bash(echo:*)"]` ran `ls -la`
successfully. The command specifier inside a `Bash(...)` grant is ignored; it
grants `Bash` wholesale. Command-level restriction is only expressible through
`permissions.deny` / `permissions.allow` in a settings file, which applies to
the whole session rather than to one agent.
