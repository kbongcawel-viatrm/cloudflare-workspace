# Architecture decisions

- Updated: 2026-11-23
- Status: confirmed baseline

## Purpose
Provide a repeatable project workspace for building applications and deploying them to Cloudflare Workers using GitHub Actions.

## Delivery model
- Each application lives in its own GitHub repository created from this template.
- GitHub Actions runs tests/build checks and deploys the Worker on pushes to `main`.
- Wrangler configuration is the source of truth for Worker name, entrypoint, compatibility date, bindings, and optional routes.
- Codespaces and local development use the same Dev Container configuration.

## Agent context
- `.agents/` is the canonical, tool-neutral source for rules, memory, sessions, providers, and skills.
- `AGENTS.md` is the primary agent entry point. Tool-specific files point back to it.
- Git stores curated, non-secret technical knowledge, not credentials, workstation state, raw chat transcripts, or personal data.

## Security boundaries
- Cloudflare API token and account ID are repository Actions secrets, not committed files.
- Scope Cloudflare tokens to the required account and Worker deployment permissions.
- Custom-domain setup and teardown are consequential resource changes; verify zone ownership and explicit approval before applying them.
- Default deployments use `workers.dev` unless a custom hostname is explicitly configured.

## Open decisions
- Confirm the preferred default Cloudflare account and zone for new projects.
- Decide whether custom-domain provisioning should create DNS records or only attach Worker custom domains.
- Evaluate tokenless GitHub OIDC deployment only when a supported Cloudflare authentication path is documented.
