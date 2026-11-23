---
name: git-operations
description: Safely inspect repositories, stage intentional changes, commit, push, and coordinate GitHub workflows.
---

# Git operations

- Inspect branch, status, remotes, and diffs before changing Git state.
- Preserve unrelated work and stage explicit paths where practical.
- Run `git diff --cached --check` and inspect staged changes before committing.
- Never force-push, rewrite shared history, or delete remote branches without explicit authorization.
- Push only after explicit operator approval; workspace-push adds interactive confirmation.
- Report branch, commit SHA, changed files, and validation results.

References:
- https://git-scm.com/docs
- https://docs.github.com/en/repositories
