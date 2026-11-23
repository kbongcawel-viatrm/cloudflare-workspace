#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  cat <<'USAGE'
Usage: install-mcp-servers.sh [--config PATH] [--github-token TOKEN]

Merge the repository's Cline MCP server definitions into the local Cline
configuration. Existing unrelated MCP servers are preserved. Credentials are
written only to the local user config (mode 0600), never to this repository.
USAGE
}
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE="$ROOT/.cline/mcp.json"
CONFIG="${CLINE_MCP_CONFIG:-$HOME/.cline/cline_mcp_settings.json}"
GITHUB_TOKEN="${GITHUB_MCP_TOKEN:-}"

while (($#)); do
  case "$1" in
    --config) CONFIG="${2:?missing config path}"; shift 2 ;;
    --github-token) GITHUB_TOKEN="${2:?missing token}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown argument: $1" ;;
  esac
done

command -v jq >/dev/null 2>&1 || die "jq is required."
[[ -f "$TEMPLATE" ]] || die "MCP template not found: $TEMPLATE"
jq -e '.mcpServers | type == "object"' "$TEMPLATE" >/dev/null || die "Invalid MCP template JSON."

if [[ -z "$GITHUB_TOKEN" ]]; then
  printf 'GitHub read-only fine-grained token for the GitHub MCP server (leave blank to configure without GitHub auth): '
  read -r -s GITHUB_TOKEN || true
  printf '\n'
fi

mkdir -p "$(dirname -- "$CONFIG")"
chmod 700 "$(dirname -- "$CONFIG")"
if [[ -e "$CONFIG" ]]; then
  [[ ! -L "$CONFIG" ]] || die "Refusing to overwrite symlinked MCP config: $CONFIG"
  jq -e 'type == "object"' "$CONFIG" >/dev/null || die "Existing MCP config is not valid JSON: $CONFIG"
  TMP="$(mktemp "${CONFIG}.XXXXXX")"
else
  TMP="$(mktemp "${CONFIG}.XXXXXX")"
  printf '{"mcpServers":{}}\n' > "$TMP"
fi

# Preserve existing unrelated server entries. Template entries intentionally
# replace same-named servers so their endpoint/transport/security defaults stay current.
jq --slurpfile template "$TEMPLATE" --arg token "$GITHUB_TOKEN" '
  .mcpServers = ((.mcpServers // {}) + $template[0].mcpServers)
  | if ($token | length) > 0 then
      .mcpServers.github.headers = {Authorization: ("Bearer " + $token)}
    else
      del(.mcpServers.github.headers)
    end
' "$CONFIG" > "$TMP"
chmod 600 "$TMP"
mv -f -- "$TMP" "$CONFIG"
unset GITHUB_TOKEN

printf 'Merged MCP server definitions into %s\n' "$CONFIG"
printf 'Configured servers: '
jq -r '.mcpServers | keys | join(", ")' "$CONFIG"
printf '\nNext: open Cline MCP Servers and reload/reconnect. Complete OAuth/device authentication for Cloudflare, Firecrawl, Linear (if requested), and Jikida.\n'
