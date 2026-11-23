---
name: wrangler
description: Run or troubleshoot Wrangler CLI commands in projects with Wrangler configuration, including local development, deployment, and resource management.
---

# Wrangler CLI

Use this skill when the project has `wrangler.jsonc`, `wrangler.json`, or `wrangler.toml`.

## Inspect
- Check package manager, lockfile, installed Wrangler version, package scripts, and config.
- Run project-local Wrangler through npm scripts or `npx`; do not silently upgrade dependencies.
- Verify the target Cloudflare account, Worker, environment, and resources before changes.
- Retrieve current Cloudflare docs for version-sensitive behavior.

## Deploy safely
- Review `wrangler.jsonc` and installed `node_modules/wrangler/config-schema.json`.
- Use `npx wrangler deploy --dry-run` before deployment where supported.
- A dry run validates packaging only; it does not prove deployed runtime or remote bindings.
- Never deploy or change DNS without explicit operator authorization.

References:
- https://developers.cloudflare.com/workers/wrangler/commands/index.md
- https://developers.cloudflare.com/workers/wrangler/configuration/index.md
- https://developers.cloudflare.com/workers/configuration/secrets/index.md
- https://developers.cloudflare.com/workers/testing/
