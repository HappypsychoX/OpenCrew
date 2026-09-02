# Delegation Examples

These examples show how `crew-lead` picks a delegation plan for different
kinds of requests. They are driven by decision rules, not by a fixed
mandatory pipeline.

The guiding principle is the **smallest reasonable delegation plan**:
delegate because it improves accuracy, efficiency, independence, or context
management - never merely because the workers exist.

## 1. Trivial edit (typo)

Request:

```
Fix the typo "Serach" in this button.
```

Recommended path:

```
crew-lead
    ↓
fixes typo
```

Why: the change is tiny and obvious. There is nothing to investigate, no
design decision to make, and no meaningful review burden. Spinning up
`repo-scout`, `architect`, `implementer`, and `reviewer` for a single-word
fix would be over-orchestration. `crew-lead` handles it directly.

## 2. Mechanical work (rename)

Request:

```
Rename this variable in these three files.
```

Recommended path:

```
crew-lead
    ↓
grunt
```

Why: the work is repetitive and mechanical, and the scope is already known.
`grunt` is the write-enabled worker for exactly this kind of task. No
investigation or design is required, so `repo-scout` and `architect` are not
used.

## 3. Investigation (explain authentication)

Request:

```
Explain how authentication works.
```

Recommended path:

```
crew-lead
    ↓
repo-scout
    ↓
crew-lead summarizes findings
```

Why: the user wants understanding, not changes. `repo-scout` is the
read-only worker for searching and tracing code paths. No `architect`,
`implementer`, or `reviewer` is needed because nothing is being designed,
changed, or reviewed.

## 4. Non-trivial feature (session expiration)

Request:

```
Add automatic session expiration to this application.
```

Recommended path:

```
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

Why each worker is used:

- `repo-scout`: the existing session handling must be understood first.
- `architect`: the feature involves a genuine design decision with multiple
  reasonable approaches.
- `implementer`: code must change, and `crew-lead` has approved a plan.
- `reviewer`: meaningful code changed, so it receives independent review.

This is chosen because the task warrants those steps, not because it is a
mandatory sequence.

## 5. Bug investigation

Request:

```
Users are occasionally being logged out immediately after signing in.
Find and fix the problem.
```

Recommended path:

```
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

Why: the worker sequence adapts to what is discovered. `repo-scout` first
locates and explains the likely cause. If the fix is obvious, `crew-lead`
goes straight to `implementer`. If several fixes are plausible, `architect`
evaluates the options before `crew-lead` chooses one. After meaningful
changes, `reviewer` inspects the result.

## 6. Multiple approaches (no changes allowed)

Request:

```
Find the best way to add offline caching.
Do not change anything yet.
```

Recommended path:

```
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

Why: the user explicitly prohibited changes, so the write-enabled workers are
not used. `repo-scout` gathers the current state of the code, `architect`
produces and compares approaches, and `crew-lead` evaluates the proposal and
returns a recommendation. `implementer` and `grunt` are not used, and
`reviewer` is generally unnecessary unless an independent critique is useful.

## Summary

| Request type | Delegation path |
|---|---|
| Trivial edit | `crew-lead` handles directly |
| Mechanical work | `crew-lead` -> `grunt` |
| Investigation | `crew-lead` -> `repo-scout` -> `crew-lead` |
| Non-trivial feature | `crew-lead` -> `repo-scout` -> `architect` -> `implementer` -> `reviewer` |
| Bug investigation | adapts: `repo-scout`, then `implementer` or `architect`, then `reviewer` |
| Multiple approaches (read-only) | `crew-lead` -> `repo-scout` -> `architect` -> recommendation |
