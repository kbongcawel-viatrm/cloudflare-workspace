---
name: bash-scripting
description: Create defensive shell scripts with strict error handling, safe path handling, and executable tests.
---

# Bash scripting

- Use `set -Eeuo pipefail`, quote expansions, and validate inputs.
- Avoid `eval` and unsafe indirect expansion.
- Never place secrets in command arguments or logs.
- Use traps only for safe, scoped cleanup.
- Test syntax with `bash -n` and exercise help/error cases without remote side effects.
- Destructive operations must be dry-run-first, narrowly scoped, and require explicit confirmation.
