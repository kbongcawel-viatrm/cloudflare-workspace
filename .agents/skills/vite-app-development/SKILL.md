---
name: vite-app-development
description: Adapt Vite and TypeScript application development for Cloudflare Workers static assets and builds.
license: MIT
---

# Vite and TypeScript app development

- Keep application code in the framework's expected source tree.
- For Vite frontend apps, configure Workers Static Assets according to current Cloudflare framework guidance.
- Validate Vite base paths, asset URLs, SPA fallback behavior, and API routing.
- Keep local development and CI build commands consistent.
- Do not carry forward home-network tunnel, Podman, or production hostname assumptions from the upstream ai-stack project.

Reference: https://developers.cloudflare.com/workers/static-assets/
