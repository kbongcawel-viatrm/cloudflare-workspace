#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  cat <<'USAGE'
Usage:
  workspace-destroy [--repo OWNER/REPO] [--account-id ID] [--zone-id ID] [--domain HOST] [--yes] [--dry-run]

Dry-run is the default. --yes executes remote teardown and removes the local checkout.
USAGE
}
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || die "Required command missing: $1"; }

REPO=""
ACCOUNT_ID="${CLOUDFLARE_ACCOUNT_ID:-}"
ZONE_ID="${CLOUDFLARE_ZONE_ID:-}"
DOMAIN=""
YES=0
DRY_RUN=1
while (($#)); do
  case "$1" in
    --repo) REPO="${2:?missing value}"; shift 2 ;;
    --account-id) ACCOUNT_ID="${2:?missing value}"; shift 2 ;;
    --zone-id) ZONE_ID="${2:?missing value}"; shift 2 ;;
    --domain) DOMAIN="${2:?missing value}"; shift 2 ;;
    --yes) YES=1; DRY_RUN=0; shift ;;
    --dry-run) YES=0; DRY_RUN=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown argument: $1" ;;
  esac
done

for cmd in git gh jq curl; do need "$cmd"; done
gh auth status >/dev/null 2>&1 || die "Run gh auth login first."
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || die "Run inside a project checkout."
[[ "$ROOT" == "$PWD" ]] || die "Run from the repository root."
[[ "$ROOT" != "$HOME" && "$ROOT" != "/" ]] || die "Unsafe local path."
[[ -d "$ROOT/.git" || -f "$ROOT/.git" ]] || die "Not a Git worktree."

PROJECT_NAME="$(jq -r '.name // empty' "$ROOT/wrangler.jsonc" 2>/dev/null)"
[[ -n "$PROJECT_NAME" ]] || die "Cannot determine Worker name from wrangler.jsonc."
if [[ -z "$REPO" ]]; then
  REPO="$(gh repo view --json nameWithOwner --jq .nameWithOwner 2>/dev/null)" || die "Set --repo OWNER/REPO."
fi
[[ "$REPO" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] || die "Invalid repository name."

if [[ -z "$DOMAIN" ]]; then
  DOMAIN="$(jq -r '.routes[]? | select(.custom_domain == true) | .pattern' "$ROOT/wrangler.jsonc" 2>/dev/null | head -n1 || true)"
  DOMAIN="${DOMAIN%/*}"
fi
[[ -n "$ACCOUNT_ID" ]] || die "Set --account-id or CLOUDFLARE_ACCOUNT_ID."
if [[ -n "$DOMAIN" && -z "$ZONE_ID" ]]; then
  die "Domain $DOMAIN configured; set --zone-id or CLOUDFLARE_ZONE_ID."
fi

printf 'Destroy plan\n  Repo: %s\n  Worker: %s\n  Account: %s\n  Domain: %s\n  Zone: %s\n  Local: %s\n' \
  "$REPO" "$PROJECT_NAME" "$ACCOUNT_ID" "${DOMAIN:-none}" "${ZONE_ID:-none}" "$ROOT"
if [[ -n "$(git -C "$ROOT" status --porcelain)" ]]; then
  git -C "$ROOT" status --short >&2
  die "Working tree is not clean. Preserve or commit local changes first."
fi
if (( DRY_RUN )); then
  echo "Dry run: no resources changed. Use --yes to execute."
  exit 0
fi
if (( ! YES )); then
  read -r -p "Type project name '$PROJECT_NAME' to continue: " confirm
  [[ "$confirm" == "$PROJECT_NAME" ]] || die "Confirmation failed."
fi

gh repo view "$REPO" --json nameWithOwner >/dev/null || die "GitHub repository inaccessible."
: "${CLOUDFLARE_API_TOKEN:?Set CLOUDFLARE_API_TOKEN with Worker and (when applicable) DNS/Routes write scopes}"

cf_api() {
  local method="$1" path="$2"
  curl --fail-with-body --silent --show-error -X "$method" "https://api.cloudflare.com/client/v4$path" \
    -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" -H "Content-Type: application/json"
}

# Inventory candidate resources before making any writes.
DOMAIN_OBJECTS='{"success":true,"result":[]}'
ROUTE_OBJECTS='{"success":true,"result":[]}'
DNS_OBJECTS='{"success":true,"result":[]}'
if [[ -n "$DOMAIN" ]]; then
  DOMAIN_OBJECTS="$(cf_api GET "/accounts/$ACCOUNT_ID/workers/domains?hostname=$DOMAIN")"
  echo "$DOMAIN_OBJECTS" | jq -e '.success == true' >/dev/null || die "Failed to list Worker domains."
fi
if [[ -n "$ZONE_ID" ]]; then
  ROUTE_OBJECTS="$(cf_api GET "/zones/$ZONE_ID/workers/routes")"
  echo "$ROUTE_OBJECTS" | jq -e '.success == true' >/dev/null || die "Failed to list Worker routes."
fi
if [[ -n "$DOMAIN" && -n "$ZONE_ID" ]]; then
  DNS_OBJECTS="$(cf_api GET "/zones/$ZONE_ID/dns_records?name=$DOMAIN")"
  echo "$DNS_OBJECTS" | jq -e '.success == true' >/dev/null || die "Failed to list DNS records."
fi

echo "Matched Cloudflare resources:"
echo "$DOMAIN_OBJECTS" | jq -r --arg h "$DOMAIN" --arg w "$PROJECT_NAME" '.result[]? | select(.hostname == $h and .service == $w) | "Worker domain: \(.id) \(.hostname)"'
echo "$ROUTE_OBJECTS" | jq -r --arg w "$PROJECT_NAME" --arg h "$DOMAIN" '.result[]? | select(.script == $w and ($h == "" or .pattern == ($h + "/*") or .pattern == $h)) | "Route: \(.id) \(.pattern)"'
echo "$DNS_OBJECTS" | jq -r --arg h "$DOMAIN" --arg t "$PROJECT_NAME.${WORKERS_DEV_SUBDOMAIN:-workers.dev}" '.result[]? | select(.name == $h and .type == "CNAME" and .content == $t) | "DNS: \(.id) \(.name) -> \(.content)"'

# Detach a Worker Domain only when hostname and Worker service both match.
if [[ -n "$DOMAIN" ]]; then
  while IFS= read -r id; do
    [[ -n "$id" ]] || continue
    cf_api DELETE "/accounts/$ACCOUNT_ID/workers/domains/$id" >/dev/null
  done < <(echo "$DOMAIN_OBJECTS" | jq -r --arg h "$DOMAIN" --arg w "$PROJECT_NAME" '.result[]? | select(.hostname == $h and .service == $w) | .id')
fi

# Delete only routes that explicitly target this Worker.
if [[ -n "$ZONE_ID" ]]; then
  while IFS= read -r id; do
    [[ -n "$id" ]] || continue
    cf_api DELETE "/zones/$ZONE_ID/workers/routes/$id" >/dev/null
  done < <(echo "$ROUTE_OBJECTS" | jq -r --arg w "$PROJECT_NAME" --arg h "$DOMAIN" '.result[]? | select(.script == $w and ($h == "" or .pattern == ($h + "/*") or .pattern == $h)) | .id')
fi

# Delete only an exact CNAME for the configured hostname pointing to this Worker.
if [[ -n "$DOMAIN" && -n "$ZONE_ID" ]]; then
  TARGET="$PROJECT_NAME.${WORKERS_DEV_SUBDOMAIN:-workers.dev}"
  while IFS= read -r id; do
    [[ -n "$id" ]] || continue
    cf_api DELETE "/zones/$ZONE_ID/dns_records/$id" >/dev/null
  done < <(echo "$DNS_OBJECTS" | jq -r --arg h "$DOMAIN" --arg t "$TARGET" '.result[]? | select(.name == $h and .type == "CNAME" and .content == $t) | .id')
fi

# Remove application Worker, then GitHub repository, then local checkout.
cf_api DELETE "/accounts/$ACCOUNT_ID/workers/scripts/$PROJECT_NAME" >/dev/null
gh repo delete "$REPO" --yes
rm -rf -- "$ROOT"
printf 'Destroyed %s and removed its local checkout.\n' "$REPO"
