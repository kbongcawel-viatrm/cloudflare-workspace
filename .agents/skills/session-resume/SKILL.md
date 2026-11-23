---
name: session-resume
description: Resume an interrupted engineering session from curated session handoffs and Git state without changing the worktree.
---

# Resume a session safely

1. Review `git status --short --branch`.
2. Read the latest real handoff under `.agents/sessions/`; do not treat templates as history.
3. Identify completed tasks, unresolved questions, risks, and next safe actions.
4. Verify time-sensitive facts with current sources before acting.
5. Never reset, clean, checkout, stage, pull, or modify files during session discovery.
6. Do not copy secrets, raw transcripts, or sensitive output into handoffs.
