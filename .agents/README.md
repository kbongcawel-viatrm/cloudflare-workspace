# Agent workspace

Portable agent context adapted from [kbongcawel-viatrm/ai-stack](https://github.com/kbongcawel-viatrm/ai-stack).

- `rules/`: working agreements and safety controls.
- `memory/`: curated project decisions and architecture. Do not store credentials, raw chat logs, personal information, or sensitive production payloads.
- `skills/`: reusable task playbooks in `SKILL.md` format.
- `sessions/templates/`: portable plans and handoffs.
- `providers/`: agent provider and MCP setup notes.

`AGENTS.md` is the primary entry point. Client-specific pointers live in `.clinerules/`, `.cline/`, `.claude/`, and `.github/copilot-instructions.md`. Credentials and local runtime state remain outside Git.
