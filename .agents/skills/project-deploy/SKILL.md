---
name: project-deploy
description: Deploy a cloudflare-workspace project end to end — validate, push/Actions or wrangler deploy for the Worker, provision Cloudflare resources (KV, tunnels, DNS), and build/up the project's own podman compose stack under projects/<name>/. Use when asked to deploy, release, or bring a project live.
---

# Project deploy workflow

Deploys a `projects/<name>/` app from this workspace. Never skip approval
gates; never claim success without verification.

## 0. Preconditions

- `CLOUDFLARE_ACCOUNT_ID` exported (see `~/.config/cf-creds.env`).
- `gh` and `wrangler` authenticated; Node 22+ on PATH (nvm).
- Podman only works on the host, NOT inside toolbox sessions — if
  `podman ps` fails with "cannot re-exec process to join the existing user
  namespace", ask the operator to run podman commands or reboot.
- Permission-blocked commands: prefix with `run0` (e.g. `run0 <cmd>`) to
  trigger the operator's polkit auth prompt — always tell the operator to
  approve it. Destructive operations still need explicit approval first.

## 1. Validate (always first — before ANY deploy step)

```bash
cd projects/<name>
workspace-validate          # or: bash scripts/workspace-validate.sh
```

Must pass before proceeding to Worker deploy OR podman steps: bash/JS
syntax, `npm test`, `tsc --noEmit`, build, and `wrangler deploy --dry-run`
(packaging check incl. KV/binding resolution — do not pass
`--skip-wrangler` unless the operator asks). Do not deploy on failure.

## 2. Worker deploy — pick ONE, with approval

- **GitHub Actions (default):** commit intended files only, `git push origin
  main` after explicit operator approval. The workflow validates, deploys,
  and writes the app URL to the job summary.
- **Direct:** `wrangler deploy` after explicit approval. Faster for
  iterating; bypasses CI checks — run `workspace-validate` first regardless.

## 3. Cloudflare resources (only if the project needs them)

`workspace-init`, `wrangler deploy`, and GitHub Actions do NOT create these.
Check `wrangler.jsonc` bindings and app docs; create missing pieces via
`wrangler kv namespace create`, the Cloudflare API, or the cloudflare MCP
`execute` tool — each is a consequential change requiring operator approval:

- KV namespaces → paste the returned `id` into `wrangler.jsonc`.
- Tunnels → remotely-managed ingress via
  `PUT /accounts/{acc}/cfd_tunnel/{tid}/configurations` (preserve existing
  rules verbatim; new hostnames go BEFORE the `http_status:404` catch-all).
- DNS → proxied CNAME to `<tunnel-id>.cfargotunnel.com` (CF_API_TOKEN may
  lack DNS scope; use the cloudflare MCP or ask for a scoped token).
- Access apps → required for user-facing hostnames per
  `vite-apps/docs/public-hostname.md`; skip for machine-facing endpoints.

## 4. Podman services (only if `compose.yaml` exists)

Project containers live in `projects/<name>/compose.yaml` — never add them
to shared stacks. Follow the **`podman-project-container`** skill for the
full procedure: registry whitelisting (`/etc/containers/policy.json` or
project-local `containers-policy.json`), compose rules (`pull_policy:
never`, resource limits — ask before cpu > 1.0 or memory > 256M),
validation via `./scripts/podman-compose-host.sh ... config`, deploy via
`./scripts/podman-compose-host.sh ... up -d`, and health verification via
`./scripts/podman-host.sh ps|logs`.

- All podman commands go through `scripts/podman-*-host.sh` wrappers —
  they run on the host even from Toolbox.
- Container creation/start/stop needs operator approval (polkit may prompt —
  let the operator approve).
- Destructive compose ops (`down`, `rm`, prune) need explicit approval.
- If a host process already serves the port, retire it after the container
  is healthy (check `ss -tlnp`).

## 5. Verify — report actual results

- Worker: `curl https://<worker>.<subdomain>.workers.dev/health` → 200.
- Dashboard/API: `curl /api/status` returns expected JSON.
- Public hostnames: `curl -sI https://<host>/` — expect 200 (app) or 302 to
  `cloudflareaccess.com` (Access-gated). Check `cf-cache-status`/`age`
  headers; purge stale edge cache via zone `purge_cache` if needed.
- Containers: `podman-compose ps` shows healthy; `curl` the published port.
- Cron-driven features: wait one interval, then confirm data appears.

## 6. Document & hand off

- Update the project README (endpoints, resources created, credentials
  needed) and `.agents/sessions/` plan/handoff.
- Report exact commands run and their outcomes; list anything not verified.
