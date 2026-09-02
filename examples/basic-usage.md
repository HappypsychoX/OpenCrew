# Basic Usage

This is a short walkthrough from installation to your first delegated task.

## 1. Install

Clone the repository and run the installer for your platform.

```
git clone https://github.com/<owner>/OpenCrew.git
cd OpenCrew
```

Windows:

```powershell
.\scripts\install.ps1
```

Linux/macOS:

```bash
./scripts/install.sh
```

Use `-Force` (Windows) or `--force` (Linux/macOS) to overwrite existing
OpenCrew files without being prompted.

The installer copies the `crew-lead` adapter and the five worker agents into
your global OpenCode agents directory.

## 2. Use crew-lead

Open any repository in OpenCode and ask:

```
@crew-lead <your task>
```

Examples:

```
@crew-lead Add automatic session expiration to this application.
```

```
@crew-lead Fix the typo "Serach" in this button.
```

```
@crew-lead Explain how authentication works in this repository.
```

You do not need to pick workers or coordinate the crew. `crew-lead` inspects
your request, decides whether delegation is useful, and routes work to the
appropriate workers. It reports the final result back to you.

## 3. Invoke workers directly

You can also call a worker directly for testing or specialized use.

Investigation:

```
@repo-scout Trace the authentication flow. Do not modify anything.
```

Design:

```
@architect Design a minimal approach for session expiration. Do not modify files.
```

Review:

```
@reviewer Review the current changes for regressions and missing tests.
```

Mechanical work:

```
@grunt Rename the `username` property to `handle` across the codebase.
```

Implementation (after an approved plan exists):

```
@implementer Apply the approved session-expiration plan and run the tests.
```

Direct invocation bypasses `crew-lead`, so the worker will only do what its
own role allows. Read-only workers will not modify files, and no worker can
push or commit.
