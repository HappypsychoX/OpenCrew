# OpenCrew

A small, reusable multi-agent development workflow for OpenCode.

## What is OpenCrew?

OpenCrew is a set of specialized development agents coordinated by a single
lead agent called `crew-lead`. You talk to `crew-lead`; it decides which of
the other workers (if any) your task actually needs, and reports the result
back to you.

The key idea is that `crew-lead` is a **role**, not a specific model or
runtime. In v1 that role is filled by an OpenCode primary agent running
DeepSeek V4 Pro.

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

## Installation

Requirements: OpenCode must be installed.

1. Clone the repository:

   ```
   git clone https://github.com/<owner>/OpenCrew.git
   cd OpenCrew
   ```

2. Run the installer for your platform.

   Windows:

   ```powershell
   .\scripts\install.ps1
   ```

   Linux/macOS:

   ```bash
   ./scripts/install.sh
   ```

The installer copies the `crew-lead` adapter and the five worker agents into
your global OpenCode agents directory (`~/.config/opencode/agents/`).

It asks before replacing existing OpenCrew files. Use force mode to skip the
prompt:

```powershell
.\scripts\install.ps1 -Force
```

```bash
./scripts/install.sh --force
```

## Meet the crew

| Agent | Model | Access | Role |
|---|---|---|---|
| crew-lead | DeepSeek V4 Pro | orchestration | Primary orchestrator; decides delegation and approves decisions |
| repo-scout | DeepSeek V4 Flash | read-only | Searches and understands repositories; traces code paths; investigates bugs |
| architect | GLM-5.3-Flash | read-only | Designs implementation approaches; evaluates alternatives and risks |
| implementer | Kimi K2.7 Code | write-enabled | Executes an approved plan; edits files and runs builds and tests |
| reviewer | DeepSeek V4 Flash | read-only | Independently inspects completed changes for bugs and regressions |
| grunt | MiMo-V2.5 | write-enabled | Handles repetitive or mechanical work: lint fixes, renames, boilerplate |

## Using crew-lead

The normal experience is a single command:

```
@crew-lead <your task>
```

First-use example:

```
@crew-lead Explain how authentication works in this repository.
```

You do not need to manually coordinate the crew. `crew-lead` chooses a
delegation plan based on the task. Trivial edits are handled directly;
mechanical work goes to `grunt`; more involved tasks may fan out to several
workers.

## Direct worker usage

You can also invoke workers directly for testing or specialized use:

```
@repo-scout Trace the authentication flow. Do not modify anything.
```

```
@architect Design a minimal approach for session expiration. Do not modify files.
```

```
@reviewer Review the current changes for regressions and missing tests.
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

To update to a newer release, pull the latest changes and re-run the
installer. Use force mode to overwrite the existing OpenCrew files:

```powershell
.\scripts\install.ps1 -Force
```

```bash
./scripts/install.sh --force
```

## Uninstalling

Run the uninstaller for your platform:

```powershell
.\scripts\uninstall.ps1
```

```bash
./scripts/uninstall.sh
```

The uninstaller removes only the OpenCrew-managed agent files
(`crew-lead`, `repo-scout`, `architect`, `implementer`, `reviewer`, `grunt`).
It does not delete the agents directory or any of your own agents.

## Security considerations

- No OpenCrew agent can run `git push`.
- `git commit` is denied by default for all agents.
- You decide when work should be committed or published.
- Read-only workers (`repo-scout`, `architect`, `reviewer`) cannot modify files.
- Workers cannot invoke other workers; all delegation flows through `crew-lead`.
- Workers escalate back to `crew-lead` when a task exceeds their role.
