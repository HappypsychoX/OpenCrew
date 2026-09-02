# OpenCrew — v1 Project Plan

## Purpose

OpenCrew is a small, reusable multi-agent development workflow.

The key architectural idea is that **`crew-lead` is a role, not a specific model or runtime**.

The `crew-lead` role defines the behavior of the OpenCrew orchestrator:

- Understand the user's complete objective
- Decide whether delegation is useful
- Select the appropriate workers
- Give workers narrow assignments
- Evaluate worker results
- Resolve disagreements
- Approve implementation decisions
- Verify the finished work
- Report the final result

Version 1 is intentionally **OpenCode-native and self-contained**. In v1, the `crew-lead` role is implemented as an OpenCode primary agent, with DeepSeek V4 Pro as the suggested model.

Later versions may allow the exact same `crew-lead` role to be filled by Codex or Claude Code without changing the OpenCrew workers or the delegation philosophy.

OpenCrew therefore consists of:

1. **The `crew-lead` role specification** — the runtime-neutral orchestration behavior.
2. **A runtime implementation of `crew-lead`** — OpenCode in v1; potentially Codex or Claude Code later.
3. **Workers** — specialized OpenCode agents that perform narrow delegated tasks.

Conceptually:

```text
HOW TO LEAD
      +
HOW TO DELEGATE
      +
WHO TO DELEGATE TO
```
---

# 1. v1 Architecture

## `crew-lead` Is a Role

`crew-lead` should be treated as an OpenCrew job description rather than as an OpenCode-specific concept.

The role defines the stable behavior of the orchestrator. The runtime implementation defines how that behavior is executed.

For v1:

```text
crew-lead role
      ↓
OpenCode implementation
      ↓
DeepSeek V4 Pro
```

In a later version:

```text
crew-lead role
      ├─ OpenCode implementation
      ├─ Codex implementation
      └─ Claude Code implementation
```

The workers should not care which runtime is filling the `crew-lead` role.

## v1 Runtime

Version 1 uses OpenCode as the only supported `crew-lead` runtime:

```text
                    User
                     │
                     ▼
              ┌─────────────┐
              │  crew-lead  │
              │   role      │
              └──────┬──────┘
                     │
              OpenCode adapter
                     │
             DeepSeek V4 Pro
                     │
       ┌─────────────┼─────────────┐
       │             │             │
       ▼             ▼             ▼
  repo-scout     architect     implementer
       │             │             │
       └──────┐      │      ┌──────┘
              ▼      ▼      ▼
             reviewer
                │
              grunt
```

The diagram is conceptual rather than a mandatory execution pipeline.

`crew-lead` may use any subset of workers depending on the task.

Examples:

```text
Fix a typo
    ↓
crew-lead handles directly
```

```text
Rename a property everywhere
    ↓
crew-lead
    ↓
grunt
```

```text
Add a non-trivial feature
    ↓
crew-lead
    ├─ repo-scout
    ├─ architect
    ├─ implementer
    └─ reviewer
```

OpenCrew should optimize for **useful delegation**, not maximum agent activity.

## Portability Rule

Any future `crew-lead` implementation must preserve the same core responsibilities and decision rules.

Runtime-specific adapters may differ in:

- How worker agents are invoked
- How persistent instructions are loaded
- How context is passed
- How permissions are enforced
- How worker output is collected

They must not redefine the basic OpenCrew leadership model merely because the runtime changed.

---
# 2. Initial Agent Set

OpenCrew v1 will include:

- One runtime-neutral `crew-lead` role specification
- One OpenCode implementation of the `crew-lead` role
- Five OpenCode worker agents

## crew-lead Role

### Role

Primary OpenCrew orchestrator.

This is the **portable role definition** that later runtimes must implement.

### v1 Runtime

- OpenCode primary agent

### Suggested v1 Model

- DeepSeek V4 Pro

### Responsibilities

- Understand the user's complete objective
- Assess task complexity and uncertainty
- Decide whether delegation is useful
- Select appropriate workers
- Create narrow worker assignments
- Review worker findings
- Resolve conflicting recommendations
- Choose implementation approaches
- Approve work before write-enabled workers act
- Review resulting changes
- Decide when the task is complete
- Report the final result to the user

### v1 Permissions

The OpenCode implementation of `crew-lead` should have the permissions necessary to inspect the repository and invoke subagents.

Preferred v1 behavior:

- `crew-lead` may handle tiny obvious edits itself
- Meaningful implementation work should normally be delegated to `implementer`
- Mechanical work should normally be delegated to `grunt`
- Git push should be denied
- Git commit should be denied by default

### Core Principle

`crew-lead` remains responsible for the final technical decision regardless of which runtime fills the role.

Workers provide evidence, implementation, and review. They are not authoritative.

Future Codex or Claude implementations must preserve this same responsibility model.

---

## repo-scout

### Purpose

- Search and understand repositories
- Trace code paths
- Locate relevant files and symbols
- Identify dependencies and existing patterns
- Investigate bugs
- Explain current behavior

### Permissions

- Read-only
- No file modifications
- No subagent delegation

### Suggested model

- DeepSeek V4 Flash

---

## architect

### Purpose

- Design implementation approaches
- Evaluate alternatives
- Identify risks and dependencies
- Produce implementation plans
- Consider maintainability and fit with the existing architecture

### Permissions

- Read-only
- No file modifications
- No subagent delegation

### Suggested model

- GLM-5.3-Flash

---

## implementer

### Purpose

- Execute an approved implementation plan
- Modify source files
- Add or update tests
- Run relevant builds and tests
- Review its own diff
- Report exactly what changed

### Permissions

- File editing allowed
- Relevant build/test commands allowed
- No subagent delegation
- Git commit denied
- Git push denied

### Suggested model

- Kimi K2.7 Code

---

## reviewer

### Purpose

- Independently inspect completed changes
- Review diffs
- Identify bugs and regressions
- Identify security concerns
- Identify missing or inadequate tests
- Verify implementation against the requested plan

### Permissions

- Read-only
- May run approved tests
- No source modification
- No subagent delegation

### Suggested model

- DeepSeek V4 Flash

---

## grunt

### Purpose

- Perform repetitive or mechanical development work
- Fix lint problems
- Rename symbols
- Update documentation
- Generate boilerplate
- Perform repetitive UI changes
- Handle straightforward mechanical refactors

### Permissions

- File editing allowed
- Limited build/test commands
- No subagent delegation
- Git commit denied
- Git push denied

### Suggested model

- MiMo-V2.5

---
# 3. Repository Structure

The repository should separate the portable `crew-lead` specification from the v1 OpenCode implementation.

```text
OpenCrew/
│
├── crew-lead/
│   ├── role.md
│   └── opencode.md
│
├── agents/
│   ├── repo-scout.md
│   ├── architect.md
│   ├── implementer.md
│   ├── reviewer.md
│   └── grunt.md
│
├── scripts/
│   ├── install.ps1
│   ├── install.sh
│   ├── uninstall.ps1
│   └── uninstall.sh
│
├── examples/
│   ├── basic-usage.md
│   └── delegation-examples.md
│
├── README.md
├── LICENSE
└── CHANGELOG.md
```

### `crew-lead/role.md`

The runtime-neutral source of truth for:

- Leadership responsibilities
- Delegation decision rules
- Over-orchestration avoidance
- Worker-selection guidance
- Escalation behavior
- Worker-result evaluation
- Final verification responsibilities

### `crew-lead/opencode.md`

The v1 OpenCode implementation of the `crew-lead` role.

During installation, this file is installed into OpenCode as:

```text
~/.config/opencode/agents/crew-lead.md
```

It should implement the behavior defined by `crew-lead/role.md` using OpenCode's native agent/subagent mechanisms.

Future versions may add:

```text
crew-lead/codex.md
crew-lead/claude.md
```

without changing the five worker definitions.

No model profiles or configuration-generation system will be included in v1.

Model assignments will be defined directly in the applicable OpenCode agent files.

---
# 4. How the Orchestrator Knows What to Do

The worker names alone do not teach `crew-lead` how to orchestrate them.

The portable behavior should be defined in:

```text
crew-lead/role.md
```

The v1 OpenCode implementation should translate that behavior into an executable OpenCode primary-agent definition:

```text
crew-lead/opencode.md
```

The role specification must describe:

- Which workers exist
- What each worker is responsible for
- When each worker should be used
- When delegation is unnecessary
- How worker results should be evaluated
- What decisions remain the orchestrator's responsibility
- How to handle disagreements
- When review is required
- When a task is considered complete

A simplified runtime-neutral `crew-lead` instruction should resemble:

```text
You are the OpenCrew lead.

Available workers:

repo-scout
- Repository investigation
- Read-only

architect
- Architecture and implementation planning
- Read-only

implementer
- Executes approved implementation plans
- May modify files

reviewer
- Independently reviews completed changes
- Read-only

grunt
- Mechanical and repetitive development work
- May modify files

Use workers when delegation improves accuracy, efficiency, independence,
or context management.

Do not delegate merely because workers exist.

You remain responsible for:
- interpreting the user's request
- deciding whether delegation is necessary
- choosing workers
- giving workers narrow assignments
- evaluating worker output
- resolving disagreements
- approving implementation plans
- final verification
```

The OpenCode, Codex, and Claude implementations may eventually express these instructions differently, but the underlying behavior should remain the same.

---
# 5. Orchestrator Decision Rules

OpenCrew should use decision rules rather than a fixed mandatory workflow.

| Situation | Recommended action |
|---|---|
| Need to understand unfamiliar code | Use `repo-scout` |
| Need to trace behavior or locate a bug | Use `repo-scout` |
| Multiple reasonable implementation approaches exist | Use `architect` |
| Architecture or design decisions are required | Use `architect` |
| A clear implementation plan is ready | Use `implementer` |
| Significant code was changed | Use `reviewer` |
| Work is repetitive or mechanical | Use `grunt` |
| Change is tiny and obvious | `crew-lead` handles it directly |
| Worker outputs disagree | `crew-lead` resolves the disagreement |
| Worker exceeds its assigned role | Stop or redirect the worker |
| Task is ambiguous but repository inspection can resolve it | Delegate inspection before asking the user |
| Task requires a user-only decision | Ask the user only when genuinely necessary |

The orchestrator should make the smallest reasonable delegation plan.

---

# 6. Avoiding Over-Orchestration

OpenCrew must explicitly discourage unnecessary multi-agent workflows.

Example:

```text
User:
Fix the typo "Serach" in this button.
```

Bad:

```text
repo-scout
    ↓
architect
    ↓
implementer
    ↓
reviewer
```

Preferred:

```text
crew-lead
    ↓
fixes typo
```

Another example:

```text
User:
Rename this variable in these three files.
```

Preferred:

```text
crew-lead
    ↓
grunt
```

Another example:

```text
User:
Explain how authentication works.
```

Preferred:

```text
crew-lead
    ↓
repo-scout
    ↓
crew-lead summarizes findings
```

No architect, implementer, or reviewer is needed.

---

# 7. Example: Non-Trivial Feature

Example request:

```text
Add automatic session expiration to this application.
```

Possible workflow:

```text
Existing session handling must be understood.
        ↓
repo-scout

The feature requires a design decision.
        ↓
architect

Worker findings are reviewed.
        ↓
crew-lead chooses the implementation approach

Code must change.
        ↓
implementer

Meaningful code changed.
        ↓
reviewer

Review findings are evaluated.
        ↓
crew-lead

Legitimate findings fixed if needed.
        ↓
crew-lead final verification

Done
```

This is not hard-coded as a required sequence. It is chosen because the task warrants those steps.

---

# 8. Example: Bug Investigation

Request:

```text
Users are occasionally being logged out immediately after signing in.
Find and fix the problem.
```

Possible workflow:

```text
crew-lead
    ↓
repo-scout
    ↓
crew-lead evaluates likely cause

If implementation is obvious:
    ↓
implementer

If multiple fixes are plausible:
    ↓
architect
    ↓
crew-lead chooses
    ↓
implementer

After meaningful changes:
    ↓
reviewer
    ↓
crew-lead final verification
```

The worker sequence adapts to what is discovered.

---

# 9. Example: Multiple Approaches

Request:

```text
Find the best way to add offline caching.
Do not change anything yet.
```

Possible workflow:

```text
crew-lead
    ↓
repo-scout
    ↓
architect
    ↓
crew-lead evaluates the proposal
    ↓
final recommendation
```

Because the user explicitly prohibited changes:

- `implementer` is not used
- `grunt` is not used
- `reviewer` is generally unnecessary unless an independent critique is useful

---

# 10. Agent Design Rules

## Narrow Responsibility

Each worker has one clearly defined role.

Avoid workers that try to investigate, design, implement, and review all at once.

The broad responsibility belongs to `crew-lead`.

## Least Privilege

Read-only workers:

```text
repo-scout
architect
reviewer
```

Write-enabled workers:

```text
implementer
grunt
```

`crew-lead` permissions should be kept as limited as practical while still allowing orchestration and trivial direct fixes.

## No Git Publishing

No OpenCrew agent should be able to run:

```text
git push
```

by default.

Prefer denying:

```text
git commit
```

as well.

The user remains responsible for deciding when work should be committed or published.

## No Worker-to-Worker Orchestration

For v1, workers should not invoke other workers.

All delegation flows through:

```text
crew-lead
```

Preferred:

```text
crew-lead
    ├─ repo-scout
    ├─ architect
    └─ implementer
```

Not:

```text
crew-lead
    ↓
architect
    ↓
repo-scout
    ↓
grunt
    ↓
reviewer
    ↓
who the hell is in charge anymore
```

## Escalation

Workers should stop and report when a task exceeds their role.

Examples:

- `grunt` should not redesign architecture
- `repo-scout` should not modify files
- `architect` should not silently implement its own proposal
- `implementer` should not invent a major redesign when the approved plan becomes difficult
- `reviewer` should not manufacture problems merely to produce findings

Workers escalate back to `crew-lead`.

---

# 11. Worker Invocation

OpenCrew should primarily use OpenCode's native subagent/task mechanism.

Users may also directly invoke workers for testing or specialized use.

Examples:

```text
@repo-scout Trace the authentication flow. Do not modify anything.
```

```text
@architect Design a minimal approach for session expiration. Do not modify files.
```

```text
@reviewer Review the current changes for regressions and missing tests.
```

The normal end-user experience should be:

```text
@crew-lead Add automatic session expiration.
```

The user should not need to manually coordinate the crew.

---

# 12. Installation Behavior

The v1 installer should install the OpenCode implementation of `crew-lead` plus the five worker agents into the user's global OpenCode agent directory.

Target:

```text
~/.config/opencode/agents/
```

Source mapping:

```text
crew-lead/opencode.md
    → ~/.config/opencode/agents/crew-lead.md

agents/repo-scout.md
    → ~/.config/opencode/agents/repo-scout.md

agents/architect.md
    → ~/.config/opencode/agents/architect.md

agents/implementer.md
    → ~/.config/opencode/agents/implementer.md

agents/reviewer.md
    → ~/.config/opencode/agents/reviewer.md

agents/grunt.md
    → ~/.config/opencode/agents/grunt.md
```

The installer should:

1. Verify that OpenCode appears to be installed.
2. Create the agents directory if necessary.
3. Install the OpenCode `crew-lead` adapter as `crew-lead.md`.
4. Copy the five worker agent files.
5. Detect existing OpenCrew files.
6. Ask before replacing existing files unless force mode is explicitly used.
7. Report which agents were installed.
8. Display a simple first-use example.

Example output:

```text
OpenCrew installed successfully.

Agents:

crew-lead
repo-scout
architect
implementer
reviewer
grunt

Try:

@crew-lead Explain how authentication works in this repository.
```

---

# 13. Installer Options

Keep v1 options minimal.

Windows:

```powershell
.\scripts\install.ps1
```

Optional:

```powershell
.\scripts\install.ps1 -Force
```

Linux/macOS:

```bash
./scripts/install.sh
```

Optional:

```bash
./scripts/install.sh --force
```

No configuration wizard is required for v1.

---

# 14. Uninstall Behavior

The uninstaller should remove only OpenCrew-managed files.

It must not delete:

```text
~/.config/opencode/agents/
```

or unrelated user-created agents.

It should remove only:

```text
crew-lead.md
repo-scout.md
architect.md
implementer.md
reviewer.md
grunt.md
```

The uninstaller should report each removed file.

---

# 15. Documentation

The README should explain OpenCrew in a few minutes.

Recommended sections:

```text
What is OpenCrew?
How it works
Installation
Meet the crew
Using crew-lead
Direct worker usage
Example workflows
Updating
Uninstalling
Security considerations
```

Detailed examples should live under:

```text
examples/
```

The README should not become a giant manifesto.

---

# 16. Distribution

OpenCrew v1 should initially be distributed through GitHub.

Users can clone the repository:

```bash
git clone https://github.com/<owner>/OpenCrew.git
cd OpenCrew
```

Then run the appropriate installer.

GitHub Releases should also provide:

```text
OpenCrew-v1.0.0.zip
```

No npm package, marketplace listing, package manager, plugin system, or standalone executable is necessary for v1.

---

# 17. Versioning

Use semantic versioning.

```text
1.0.0
1.0.1
1.1.0
2.0.0
```

Meaning:

```text
PATCH
Bug fixes or prompt improvements

MINOR
New agents or backward-compatible capabilities

MAJOR
Breaking changes to agent behavior, orchestration, or installation
```

---

# 18. Initial Release Criteria

OpenCrew v1.0.0 is complete when:

- `crew-lead/role.md` defines the runtime-neutral lead behavior.
- `crew-lead/opencode.md` implements that role for OpenCode.
- The installed OpenCode `crew-lead` can orchestrate workers.
- All five worker definitions exist.
- Each worker has appropriate permissions.
- Workers cannot invoke other workers.
- Git push is denied for all agents.
- Git commit is denied by default.
- Models are assigned directly in the agent files.
- The portable `crew-lead` role contains clear delegation decision rules.
- The OpenCode adapter preserves those rules without redefining the role.
- `crew-lead` does not blindly use every worker for every task.
- Trivial tasks can be handled directly.
- Mechanical tasks can be routed directly to `grunt`.
- Investigation-only requests can use `repo-scout` without triggering implementation.
- Non-trivial feature workflows can successfully use multiple workers.
- Significant implementation changes can receive independent review.
- Worker disagreements are resolved by `crew-lead`.
- Windows installer works.
- Linux/macOS installer works.
- Windows uninstaller works.
- Linux/macOS uninstaller works.
- Existing unrelated OpenCode agents are preserved.
- Existing OpenCrew files are not silently overwritten.
- Basic workflows are documented and tested.
- README installation instructions are tested.
- GitHub repository is ready for distribution.
- A v1.0.0 ZIP release can be generated.

---

# 19. Explicitly Out of Scope for v1

Do not implement these in v1:

- Codex implementation of `crew-lead`
- Claude Code implementation of `crew-lead`
- Cross-provider orchestration
- Runtime selection during installation
- Model profiles
- Interactive model selection
- Dynamic model routing
- GUI installer
- OpenCode plugin
- npm package
- Automatic updates
- Agent marketplace
- Telemetry
- Cloud service
- Central configuration server
- Complex worker dependency system
- Worker-to-worker delegation
- Mandatory fixed worker pipelines

The v1 architecture should **allow** future Codex and Claude `crew-lead` adapters, but it should not implement them yet.

Add additional runtimes only after the OpenCode-native workflow proves reliable.

---
# 20. Future Versions

## Design Principle

Future versions should not create separate OpenCrew systems for OpenCode, Codex, and Claude.

Instead, they should provide multiple implementations of the same `crew-lead` role.

Conceptually:

```text
                 crew-lead role
                       │
          ┌────────────┼────────────┐
          │            │            │
          ▼            ▼            ▼
      OpenCode       Codex       Claude Code
       adapter       adapter        adapter
          │            │            │
          └────────────┼────────────┘
                       │
                OpenCrew workers
```

The workers remain:

```text
repo-scout
architect
implementer
reviewer
grunt
```

The selected lead runtime changes. The OpenCrew crew does not.

## Possible v1.x Improvements

Backward-compatible improvements may include:

- Better `crew-lead` routing instructions
- Additional delegation examples
- Improved permission defaults
- Additional worker safety checks
- Optional new worker roles
- Installer improvements
- Better diagnostics
- Refinements to `crew-lead/role.md` that remain runtime-neutral

## Possible v2 — Multiple crew-lead Runtimes

A later release may add alternate adapters:

```text
crew-lead/
├── role.md
├── opencode.md
├── codex.md
└── claude.md
```

### OpenCode

```text
crew-lead role
    ↓
OpenCode adapter
    ↓
OpenCode workers
```

### Codex

```text
crew-lead role
    ↓
Codex adapter
    ↓
OpenCode workers
```

### Claude Code

```text
crew-lead role
    ↓
Claude adapter
    ↓
OpenCode workers
```

Possible implementation areas:

- Codex `AGENTS.md` integration
- Claude Code `CLAUDE.md` integration
- Runtime-specific worker invocation
- Cross-provider output capture
- Shared `crew-lead` behavior sourced from `role.md`
- Installer support for selecting or enabling a lead runtime
- Documentation for personal/work split workflows

## Compatibility Requirement

Adding a new `crew-lead` runtime should not require rewriting worker definitions.

A task such as:

```text
Add automatic session expiration.
```

should follow the same OpenCrew decision philosophy regardless of whether the lead is:

```text
OpenCode
Codex
Claude Code
```

The mechanics may differ. The leadership behavior should not.

---
# 21. Recommended Build Order

## Phase 1 — Worker Definitions

Create and test:

```text
repo-scout
architect
implementer
reviewer
grunt
```

Verify each role works correctly on its own.

## Phase 2 — crew-lead Role and OpenCode Adapter

Create:

```text
crew-lead/role.md
crew-lead/opencode.md
```

Define the runtime-neutral role first, then implement it for OpenCode.

Define:

- Available workers
- Worker responsibilities
- Delegation decision rules
- Over-orchestration avoidance
- Escalation behavior
- Worker-result evaluation
- Final-review responsibility
- Runtime-neutral behavior that does not depend on OpenCode-specific terminology unless required by the adapter

Verify that `crew-lead/opencode.md` implements the behavior in `crew-lead/role.md`.

Test simple and complex requests.

### Test: trivial edit

```text
Fix this typo.
```

Expected:

```text
crew-lead handles directly
```

### Test: mechanical work

```text
Rename this property throughout these files.
```

Expected:

```text
crew-lead
    ↓
grunt
```

### Test: investigation

```text
Explain how authentication works.
```

Expected:

```text
crew-lead
    ↓
repo-scout
    ↓
crew-lead response
```

### Test: non-trivial feature

```text
Add automatic session expiration.
```

Expected possible workflow:

```text
crew-lead
    ↓
repo-scout
    ↓
architect
    ↓
crew-lead decision
    ↓
implementer
    ↓
reviewer
    ↓
crew-lead final verification
```

## Phase 3 — Permission and Safety Testing

Verify:

- Read-only workers cannot edit files.
- `implementer` and `grunt` can make intended changes.
- Workers cannot invoke other workers.
- No agent can push.
- Commit behavior matches the chosen v1 policy.
- `crew-lead` does not exceed its intended permissions.
- Agents escalate when work exceeds their role.

## Phase 4 — Installation

Build:

```text
install.ps1
uninstall.ps1
install.sh
uninstall.sh
```

Test on:

- Clean OpenCode configuration
- Existing OpenCode configuration
- Existing custom agents
- Reinstallation
- Forced update
- Uninstall

## Phase 5 — Documentation

Create:

```text
README.md
examples/basic-usage.md
examples/delegation-examples.md
CHANGELOG.md
LICENSE
```

## Phase 6 — Release

Create the GitHub repository.

Tag:

```text
v1.0.0
```

Generate:

```text
OpenCrew-v1.0.0.zip
```

Publish the initial release.

---

# End Goal

OpenCrew v1 should make this possible:

```text
Install OpenCrew once.

Open any repository in OpenCode.

Ask:

@crew-lead <your task>

The OpenCode implementation of crew-lead applies the shared OpenCrew role:

- decide whether delegation is needed
- choose the appropriate worker
- define what each worker should do
- evaluate worker output
- decide whether implementation needs review
- perform final verification

The user interacts primarily with crew-lead.
```

The v1 hierarchy is:

```text
You
 ↓
crew-lead role
 ↓
OpenCode implementation
 ↓
OpenCrew decision rules
 ↓
Appropriate worker(s)
 ↓
crew-lead final decision
```

The long-term architecture is:

```text
You
 ↓
crew-lead role
 ↓
Selected runtime
 ├─ OpenCode
 ├─ Codex
 └─ Claude Code
 ↓
Same OpenCrew workers
```

The first release should prioritize reliability, transparency, and simplicity over configurability.

OpenCode gets the `crew-lead` badge in v1.

Later, Codex or Claude can wear the same badge without replacing the crew.

---
