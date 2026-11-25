# Cloudflare App Workspace
[Cloudflare](https://img.shields.io/badge/just%20the%20message-#F38020)
[Cloudflare Workers](https://img.shields.io/badge/just%20the%20message-#F38020)
[Vite](https://img.shields.io/badge/just%20the%20message-9135FF)

## Repository
![GitHub repo](https://github-readme-insight-terminal-asci.vercel.app/svg/repo?repo=kbongcawel-viatrm/cloudflare-workspace&theme=mac)

## Stack
![Skills](https://github-readme-insight-terminal-asci.vercel.app/svg/skills?i=vite,react,cloudflare,cloudflareworkers,githubactions,github,&theme=mac&perline=10)

## Last commit
![Recent commits](https://github-readme-insight-terminal-asci.vercel.app/svg/git-log?user=kbongcawel-viatrm&theme=mac&lines=3)

Reusable starter for GitHub + GitHub Actions + Cloudflare Workers projects, including Codespaces and a portable AI-agent workspace.

## Included

- `workspace-init`: create a GitHub repository from this template, configure Wrangler, add Actions secrets, clone locally, install the project Bash profile, and merge MCP server definitions into local Cline settings.
- `workspace-push`: review, stage, commit, and push project changes to `main` after interactive confirmation.
- `workspace-destroy`: dry-run-first teardown of the GitHub repository, matching Cloudflare Worker/domain/route/DNS resources, and local checkout.
- `workspace-validate`: local syntax, tests, TypeScript type-check, build, and Wrangler packaging dry-run; it never deploys.
- `install-mcp-servers`: independently merge this repository's MCP definitions into local Cline configuration.
- GitHub Actions: install, test/build, validate Wrangler packaging, deploy, summarize the app URL, and upload deployment metadata.
- Codespaces Dev Container with Node.js 22, GitHub CLI, and editor extensions.
- `.agents/` canonical rules, curated project memory, session templates, providers, and selected skills adapted from `kbongcawel-viatrm/ai-stack`.

## Requirements

Run the commands below in a POSIX-compatible terminal (Fedora Toolbox is suitable; host-level installation is not required). Install and authenticate:

- Git, GitHub CLI (`gh`), `jq`, Node.js 22+, npm, and Bash.
- Wrangler CLI (`npm install --global wrangler`) and Cloudflare authentication (`wrangler login`).
- GitHub authentication (`gh auth login`) with permission to create repositories and manage repository Actions secrets/variables.
- A Cloudflare account ID and an API token scoped to deploy the Worker.
- For MCP installation: `jq`; Cline; optional GitHub fine-grained read-only token. OAuth/device sign-ins for the hosted MCP providers are completed separately in Cline.

## Install this workspace's commands

From the cloned template repository root:

```bash
npm install
npm install --global wrangler
npm link
wrangler login
gh auth login
```

`npm link` registers the command names in the current Node.js global prefix. Run it again when using a different nvm-managed Node.js installation.

## Command reference

### `workspace-init`

```text
workspace-init <project-name> [--visibility private|public]
               [--domain app.example.com] [--user-bash-hook] [--skip-mcp]
```

Creates `<authenticated-github-user>/<project-name>` from the `cloudflare-app-workspace` template, clones it into `./projects/<project-name>`, sets the Wrangler Worker name, installs npm dependencies, configures GitHub Actions secrets, optionally configures a custom domain, installs a project Bash profile, and installs MCP definitions locally by default.

| Flag | Description |
|---|---|
| `--visibility private\|public` | Set GitHub repository visibility. Defaults to `private`. |
| `--domain HOST` | Add `HOST` as a Wrangler custom-domain route and set the GitHub `APP_URL` variable to `https://HOST`. The hostname must be configured in Cloudflare. |
| `--user-bash-hook` | Back up an existing `~/.bashrc` and append a guarded interactive hook to source `~/.bashrc.workspace`. Without this flag, only the separate profile file is installed. |
| `--skip-mcp` | Do not merge MCP definitions into the local Cline settings. |
| `-h`, `--help` | Print usage and exit. |

Required environment variable:

```bash
export CLOUDFLARE_ACCOUNT_ID="<cloudflare-account-id>"
```

Example:

```bash
workspace-init my-new-app
workspace-init my-public-app --visibility public
workspace-init my-site --domain app.example.com
workspace-init my-site --domain app.example.com --user-bash-hook
workspace-init my-site --skip-mcp
```

The initializer prompts for a Cloudflare API token and stores it as the `CLOUDFLARE_API_TOKEN` GitHub Actions secret; `CLOUDFLARE_ACCOUNT_ID` is also stored as a secret. The token is not written into the project. The command expects the template repository to be named `cloudflare-app-workspace` under the authenticated GitHub account. It fails rather than cloning over an existing local path or creating an already-existing repository.

### `workspace-validate`

```text
workspace-validate [--install] [--skip-wrangler] [-h|--help]
```

Runs local checks only: Bash syntax, JavaScript syntax, npm tests, TypeScript type-check, application build, and (by default) `wrangler deploy --dry-run`. It does not deploy.

| Flag | Description |
|---|---|
| `--install` | Run `npm install` when `node_modules/` is absent. Without this flag, missing dependencies cause a clear error. |
| `--skip-wrangler` | Skip only the Wrangler packaging dry-run. Tests, type-check, and build still run. |
| `-h`, `--help` | Print usage and exit. |

Examples:

```bash
workspace-validate
workspace-validate --install
workspace-validate --skip-wrangler
workspace-validate --install --skip-wrangler
```

Equivalent npm script: `npm run validate -- --skip-wrangler`.

### `workspace-push`

```text
workspace-push [commit-message]
```

Stages tracked and untracked changes, checks the staged diff with `git diff --cached --check`, displays the staged summary and paths, asks for confirmation, commits, and pushes `main` to `origin/main`. The current branch must be `main`; an `origin` remote and at least one change are required.

| Argument | Description |
|---|---|
| `commit-message` | Optional commit message. Defaults to `chore: update application`. |
| `-h`, `--help` | Print usage and exit. |

Examples:

```bash
workspace-push
workspace-push "feat: add health endpoint"
```

The command does not bypass branch protection. Use a pull request when direct pushes to `main` are restricted.

### `workspace-destroy`

```text
workspace-destroy [--repo OWNER/REPO] [--account-id ID] [--zone-id ID]
                  [--domain HOST] [--yes] [--dry-run] [-h|--help]
```

Inventories and, when explicitly requested, removes the matching Worker Domain object, Worker routes, exact matching DNS CNAME, Worker script, GitHub repository, and local checkout. It must be run from the project checkout root with a clean Git worktree.

| Flag | Description |
|---|---|
| `--repo OWNER/REPO` | GitHub repository to delete. Defaults to the repository detected by `gh` from the current checkout. |
| `--account-id ID` | Cloudflare account ID. Defaults to `CLOUDFLARE_ACCOUNT_ID`. |
| `--zone-id ID` | Cloudflare zone ID for route/DNS inventory and deletion. Defaults to `CLOUDFLARE_ZONE_ID`. |
| `--domain HOST` | Custom hostname to match. Defaults to the custom-domain route in `wrangler.jsonc`, if present. |
| `--dry-run` | Print the plan without remote or local deletion. This is the default. |
| `--yes` | Execute deletion without the project-name confirmation prompt. Still requires a clean worktree and valid credentials. |
| `-h`, `--help` | Print usage and exit. |

Required for execution:

```bash
export CLOUDFLARE_API_TOKEN="<scoped-cloudflare-api-token>"
export CLOUDFLARE_ACCOUNT_ID="<cloudflare-account-id>"
# Only when a custom domain/route is configured:
export CLOUDFLARE_ZONE_ID="<cloudflare-zone-id>"
```

Examples:

```bash
workspace-destroy                         # safe inventory/dry-run
workspace-destroy --domain app.example.com --dry-run
workspace-destroy --repo owner/project --account-id ID --zone-id ID --domain app.example.com
workspace-destroy --yes                   # destructive; review dry-run first
```

**Destructive operation:** `--yes` deletes remote Cloudflare resources, the GitHub repository, and the local checkout (`rm -rf` of the checkout root). Verify the target account, repository, Worker name, zone, and hostname before executing. The command does not delete the Cloudflare zone or unrelated DNS records. GitHub CLI must be authenticated with repository administrator rights. Cloudflare API token permissions must cover Worker Scripts Write and, as applicable, Worker Routes Write and DNS Write. A dry-run does not prove that the credentials have write access.

### `install-mcp-servers`

```text
scripts/install-mcp-servers.sh [--config PATH] [--github-token TOKEN] [-h|--help]
```

Merges `.cline/mcp.json` into the local Cline user configuration. Existing unrelated server entries are preserved; same-named entries are updated from this repository's template. The destination directory is set to mode `0700` and the configuration file to `0600`.

| Flag / environment variable | Description |
|---|---|
| `--config PATH` | Write to an alternate Cline configuration path. Defaults to `$CLINE_MCP_CONFIG`, or `~/.cline/cline_mcp_settings.json`. |
| `--github-token TOKEN` | Supply a GitHub read-only token for the GitHub MCP server. Prefer the interactive hidden prompt or `GITHUB_MCP_TOKEN` to avoid putting secrets in shell history/process arguments. |
| `CLINE_MCP_CONFIG` | Alternate destination path when `--config` is not supplied. |
| `GITHUB_MCP_TOKEN` | GitHub read-only token when `--github-token` is not supplied. |
| `-h`, `--help` | Print usage and exit. |

Configured servers: GitHub (read-only), Cloudflare (OAuth), Firecrawl (OAuth), Linear (read-only), and Jikida (stdio through `npx`). The installer only writes endpoint metadata and, when supplied, the GitHub token. Complete provider sign-in separately in Cline and reload/reconnect the MCP servers. All `autoApprove` lists remain empty. See [docs-mcp-setup.md](docs-mcp-setup.md) for permission guidance and provider-specific authentication.

Examples:

```bash
scripts/install-mcp-servers.sh
scripts/install-mcp-servers.sh --config "$HOME/.config/cline/cline_mcp_settings.json"
GITHUB_MCP_TOKEN="<read-only-token>" scripts/install-mcp-servers.sh
```

Avoid passing actual secrets as literal command-line arguments because they can be retained in shell history or visible in process listings. Use the hidden prompt or a secret manager to set `GITHUB_MCP_TOKEN` for the process.

### `install-bashrc`

```text
scripts/install-bashrc.sh [--user-hook] [-h|--help]
```

Installs the project's portable Bash profile to `~/.bashrc.workspace`. It does not replace the existing `~/.bashrc` by default.

| Flag | Description |
|---|---|
| `--user-hook` | Back up an existing `~/.bashrc` and append a guarded interactive source hook. |
| `-h`, `--help` | Print usage and exit. |

Examples:

```bash
scripts/install-bashrc.sh
scripts/install-bashrc.sh --user-hook
```

## Quick start: create an app

After publishing this repository and enabling **Template repository** in GitHub Settings:

```bash
export CLOUDFLARE_ACCOUNT_ID="<cloudflare-account-id>"
workspace-init my-new-app --visibility private
cd my-new-app
npm run dev
```

To configure a custom hostname:

```bash
workspace-init my-site --domain app.example.com
```

Custom-domain setup requires the hostname to be in an active Cloudflare zone. The initializer adds a Wrangler custom-domain route and sets `APP_URL`; review zone/domain configuration and deployment permissions before deploying.

## Codespaces

Open the generated repository using **Code → Codespaces → Create codespace on main**. The `.devcontainer/devcontainer.json` provisions Node.js 22 and GitHub CLI; `postCreateCommand` installs npm dependencies.

```bash
npm run dev
```

Wrangler forwards port `8787`.

## Typical development and deployment flow

```bash
workspace-validate
workspace-push "feat: implement application change"
```

A push to `main` triggers GitHub Actions. The workflow validates the project, deploys the Worker using Wrangler, writes the app URL to the Actions job summary, and uploads a `deployment-metadata` artifact containing `deployment.env` with `APP_URL`.

## GitHub Actions configuration

The initializer configures these repository Actions secrets:

- `CLOUDFLARE_API_TOKEN`: narrowly scoped Cloudflare API token for Worker deployment.
- `CLOUDFLARE_ACCOUNT_ID`: Cloudflare account identifier.

Optional repository variables:

- `APP_URL`: exact public URL used in the deployment summary.
- `CLOUDFLARE_SUBDOMAIN`: `workers.dev` account subdomain override if required.

## AI coding tools and project context

- `AGENTS.md` is the primary agent entry point.
- `.agents/skills/` is the canonical skill store.
- `.agents/memory/` stores reviewed, project-specific technical facts and decisions, not raw transcripts.
- `.agents/sessions/templates/` contains session plan and handoff templates.
- `.clinerules/`, `.cline/`, `.claude/`, and `.github/copilot-instructions.md` provide tool-specific pointers.
- `.agents/providers/mcp.md` and `docs-mcp-setup.md` document MCP setup and safe operation. Every client authenticates separately; credentials are not committed.

Only reusable agent context and relevant skills were imported from `kbongcawel-viatrm/ai-stack`. Personal host memory and historical session records were deliberately excluded. See `SOURCES.md`.

## Bash profile safety

The generated `.bashrc` imports portable terminal/status helpers only. The original upstream Bash template includes machine-specific paths, privileged commands, firewall/network mutation functions, credential loaders, automatic inactivity logout, and `cline --auto-approve`; these are intentionally excluded from the sourced profile. Review upstream content separately before adapting it to a host. The project profile is installed to `~/.bashrc.workspace`, with optional guarded sourcing using `--user-bash-hook`.

## Local validation

Run `workspace-validate` before pushing. It performs Bash and JavaScript syntax checks, `npm test`, TypeScript type-check, application build, and Wrangler packaging dry-run. It does not deploy or change Cloudflare resources. The same validation command is used by GitHub Actions before deployment.

## Author
![ASCII avatar](https://github-readme-insight-terminal-asci.vercel.app/svg/ascii?user=kbongcawel-viatrm&theme=mac&cols=24&color=1)

<img src="https://github-readme-insight-terminal-asci.vercel.app/svg/ascii?user=kbongcawel-viatrm&amp;theme=mac&amp;cols=24&amp;color=1" alt="ASCII avatar">
