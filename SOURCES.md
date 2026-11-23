# Agent asset provenance

Selected agent rules, session templates, and skills are adapted from:

- Repository: https://github.com/kbongcawel-viatrm/ai-stack
- Branch inspected: `main`
- Snapshot date: 2026-11-23

The source repository contains personal and environment-specific operational memory and historical session records. This template intentionally does not copy those personal records. It carries forward reusable structure and seeds clean, project-specific memory instead.

Selected concepts/skills:
- `.agents/` canonical hierarchy, curated memory, rules, session templates, providers and skills.
- Agent guidance from `AGENTS.md` and `.agents/rules/working-agreement.md`.
- Wrangler, Dev Containers/Codespaces, Git operations, GitHub Actions, Bash scripting, session resume, and Vite app development.
- Bash profile adaptation from `projects/bash/bashrc_template`; only portable terminal helpers are enabled in `.bashrc`. The upstream full source is retained separately as reference and is not sourced.

Review upstream changes before syncing; never overwrite locally curated project memory automatically.

## MCP configuration source

The MCP server endpoint configuration and operational guidance are adapted from:
- https://github.com/kbongcawel-viatrm/ai-stack/blob/main/.cline/mcp.json
- https://github.com/kbongcawel-viatrm/ai-stack/blob/main/docs/mcp-setup.md

The project installer merges those Cline server definitions into local Cline settings. The GitHub token is prompted for at runtime and never copied from upstream or committed. OAuth/device authentication is performed independently by each provider.
