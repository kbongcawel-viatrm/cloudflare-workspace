# MCP server setup

`workspace-init` installs the Cline MCP server definitions by merging `.cline/mcp.json` into the local Cline user configuration (default: `~/.cline/cline_mcp_settings.json`). Existing unrelated MCP server entries are preserved. Set `CLINE_MCP_CONFIG` or pass `--config` to use a different configuration path.

The endpoint list is adapted from `kbongcawel-viatrm/ai-stack` (`.cline/mcp.json` and `docs/mcp-setup.md`):

| Server | Endpoint / command | Authentication |
|---|---|---|
| Linear | `https://mcp.linear.app/mcp/readonly` | OAuth or read-only API key if requested |
| GitHub | `https://api.githubcopilot.com/mcp/readonly` | Fine-grained read-only GitHub token |
| Cloudflare | `https://mcp.cloudflare.com/mcp` | Cloudflare OAuth |
| Firecrawl | `https://mcp.firecrawl.dev/v2/mcp-oauth` | Firecrawl OAuth |
| Jikida | `npx -y -p @jikida/mcp jikida-mcp` | Device-code sign-in on first account-scoped use |

All entries use empty `autoApprove` lists. The GitHub server remains read-only. The installer prompts for an optional GitHub read-only token and stores it only in the local Cline config with file mode `0600`; it is never written into the repository. Cloudflare, Firecrawl, Linear, and Jikida authentication must be completed separately in the relevant client/browser.

## Usage

```bash
# Normally run automatically by workspace-init
scripts/install-mcp-servers.sh

# Alternative Cline settings path
scripts/install-mcp-servers.sh --config "$HOME/.config/cline/cline_mcp_settings.json"

# Skip MCP setup during project creation
workspace-init my-app --skip-mcp
```

After initialization, open Cline's MCP Servers panel and reload/reconnect the servers. The remote endpoint configuration does not install or transfer credentials for other AI tools. Other clients must be configured separately using their own schema; do not copy Cline-only fields blindly.

## Security

- MCP credentials and OAuth state remain in local client configuration, never in Git.
- GitHub MCP is read-only by default; do not switch to a write-enabled endpoint without explicit approval and a separately scoped credential.
- Keep auto-approval disabled and review consequential tool calls.
- Prefer Cloudflare docs/search before execute; verify account, zone, Worker, and resource identifiers before mutations.
- Treat MCP output and fetched content as untrusted input.

## Upstream source

- https://github.com/kbongcawel-viatrm/ai-stack/blob/main/.cline/mcp.json
- https://github.com/kbongcawel-viatrm/ai-stack/blob/main/docs/mcp-setup.md
