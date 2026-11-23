#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  cat <<'USAGE'
Usage:
  workspace-init <project-name> [--visibility private|public] [--domain app.example.com] [--user-bash-hook] [--skip-mcp]

Creates a repository from this template, configures Wrangler, seeds GitHub
Actions secrets, clones the new project, and installs the project Bash profile.
USAGE
}
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"; }

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then usage; exit 0; fi
[[ $# -ge 1 ]] || { usage; exit 2; }
PROJECT_NAME="$1"; shift
VISIBILITY="private"
CUSTOM_DOMAIN=""
INSTALL_USER_HOOK=0
INSTALL_MCP=1
while (($#)); do
  case "$1" in
    --visibility) VISIBILITY="${2:?missing value}"; shift 2 ;;
    --domain) CUSTOM_DOMAIN="${2:?missing value}"; shift 2 ;;
    --user-bash-hook) INSTALL_USER_HOOK=1; shift ;;
    --skip-mcp) INSTALL_MCP=0; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown option: $1" ;;
  esac
done

[[ "$PROJECT_NAME" =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]{0,95}$ ]] || die "Invalid project name."
[[ "$VISIBILITY" == private || "$VISIBILITY" == public ]] || die "Visibility must be private or public."
[[ -z "$CUSTOM_DOMAIN" || "$CUSTOM_DOMAIN" =~ ^([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}$ ]] || die "Invalid custom domain."
for cmd in git gh jq node npm npx bash; do need "$cmd"; done
gh auth status >/dev/null 2>&1 || die "Run gh auth login first."
wrangler --version >/dev/null 2>&1 || die "Wrangler missing. Run npm install -g wrangler."
wrangler whoami >/dev/null 2>&1 || die "Run wrangler login first."

SCRIPT_PATH="${BASH_SOURCE[0]}"
while [[ -L "$SCRIPT_PATH" ]]; do
  _dir="$(cd -P "$(dirname -- "$SCRIPT_PATH")" && pwd)"
  SCRIPT_PATH="$(readlink -- "$SCRIPT_PATH")"
  [[ "$SCRIPT_PATH" != /* ]] && SCRIPT_PATH="$_dir/$SCRIPT_PATH"
done
SCRIPT_DIR="$(cd -P "$(dirname -- "$SCRIPT_PATH")" && pwd)"
TEMPLATE_ROOT="$(cd -P "$SCRIPT_DIR/.." && pwd)"
OWNER="$(gh api user --jq .login)"
REPO="$OWNER/$PROJECT_NAME"
TARGET_DIR="$PWD/$PROJECT_NAME"
[[ ! -e "$TARGET_DIR" ]] || die "Target path already exists: $TARGET_DIR"
ACCOUNT_ID="${CLOUDFLARE_ACCOUNT_ID:-}"
[[ -n "$ACCOUNT_ID" ]] || die "Set CLOUDFLARE_ACCOUNT_ID to the intended Cloudflare account ID."
gh repo view "$REPO" >/dev/null 2>&1 && die "Repository already exists: $REPO"

printf 'Creating %s (%s) from template\n' "$REPO" "$VISIBILITY"
gh repo create "$REPO" "--$VISIBILITY" --template "$OWNER/cloudflare-app-workspace" --clone=false
git clone "https://github.com/$REPO.git" "$TARGET_DIR"
cd -- "$TARGET_DIR"

jq --arg name "$PROJECT_NAME" '.name = $name' wrangler.jsonc > wrangler.jsonc.tmp
mv wrangler.jsonc.tmp wrangler.jsonc
if [[ -n "$CUSTOM_DOMAIN" ]]; then
  jq --arg domain "$CUSTOM_DOMAIN" '. + {routes: [{pattern: $domain, custom_domain: true}]}' wrangler.jsonc > wrangler.jsonc.tmp
  mv wrangler.jsonc.tmp wrangler.jsonc
fi

npm install
bash -n scripts/workspace-init.sh scripts/workspace-push.sh scripts/workspace-destroy.sh scripts/workspace-validate.sh scripts/install-bashrc.sh scripts/install-mcp-servers.sh

# Merge the ai-stack MCP endpoint template into the local Cline config.
# Existing unrelated servers are preserved; credentials stay outside Git.
if (( INSTALL_MCP )); then
  scripts/install-mcp-servers.sh
fi

read -rsp "Cloudflare API token for GitHub Actions (input hidden): " CF_TOKEN
printf '\n'
[[ -n "$CF_TOKEN" ]] || die "Cloudflare API token is required."
printf '%s' "$CF_TOKEN" | gh secret set CLOUDFLARE_API_TOKEN --repo "$REPO"
unset CF_TOKEN
printf '%s' "$ACCOUNT_ID" | gh secret set CLOUDFLARE_ACCOUNT_ID --repo "$REPO"
if [[ -n "$CUSTOM_DOMAIN" ]]; then
  gh variable set APP_URL --body "https://$CUSTOM_DOMAIN" --repo "$REPO"
fi

# Install the generated project .bashrc as ~/.bashrc.workspace.
# Updating ~/.bashrc to source it is opt-in, and the installer backs it up.
if (( INSTALL_USER_HOOK )); then
  scripts/install-bashrc.sh --user-hook
else
  scripts/install-bashrc.sh
fi

printf '\nWorkspace created:\n  Repository: https://github.com/%s\n  Local path: %s\n  Worker: %s\n' "$REPO" "$TARGET_DIR" "$PROJECT_NAME"
printf '\nNext:\n  cd %q\n  npm run dev\n  workspace-push\n' "$TARGET_DIR"
