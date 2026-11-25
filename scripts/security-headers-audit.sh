#!/usr/bin/env bash
# security-headers-audit.sh — verify the MUST header baseline
# (.agents/rules/security-headers.md) across all public endpoints, and
# confirm workers.dev subdomains stay disabled.
#
# Usage: scripts/security-headers-audit.sh [-v]
# Exit 0 = all checks pass, 1 = one or more failures.
#
# Discovery: if CLOUDFLARE_API_TOKEN + CLOUDFLARE_ZONE_ID are available (env or
# ~/.config/cf-creds.env), hosts and workers are enumerated live via the
# Cloudflare API. Otherwise falls back to the static lists below — keep
# them in sync when adding hosts/workers.

set -u
VERBOSE=0
[ "${1:-}" = "-v" ] && VERBOSE=1

# Optional credentials (never required for the checks themselves)
[ -f "$HOME/.config/cf-creds.env" ] && . "$HOME/.config/cf-creds.env"
CLOUDFLARE_API_TOKEN="${CLOUDFLARE_API_TOKEN:-}"
CF_ACCOUNT_ID="${CLOUDFLARE_ACCOUNT_ID:-}"
CF_ZONE_ID="${CF_ZONE_ID:-f5c4bcafdbbd8b96b8d9b584d0523535}"
CF_ZONE_NAME="home-security.uk"
WORKERS_SUBDOMAIN="home-security-uk"

# Static fallbacks (used when CF API is unavailable)
STATIC_HOSTS=(
  home-security.uk bio.home-security.uk v2.home-security.uk
  gondar.home-security.uk shadow-fiend.home-security.uk
  files.home-security.uk natures-prophet.home-security.uk
  status.home-security.uk totp.home-security.uk
)
STATIC_WORKERS=(
  gondar-v2 home-totp-authenticator ip-blocklist-adder jit-totp-gate
  kevin-bongcawel-portfolio natures-prophet natures-prophet-shipper
  shadow-fiend v2-home-security-uk
)

cf_api() { # cf_api METHOD PATH [JSON_BODY]
  local method="$1" path="$2" body="${3:-}"
  local args=(-sS --max-time 20 -X "$method"
    -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN"
    -H "Content-Type: application/json")
  [ -n "$body" ] && args+=(-d "$body")
  curl "${args[@]}" "https://api.cloudflare.com/client/v4$path"
}

ZONE_HOSTS=(); WORKERS_DEV=()
if [ -n "$CLOUDFLARE_API_TOKEN" ]; then
  echo "== Discovery via Cloudflare API =="
  dns_json=$(cf_api GET "/zones/$CF_ZONE_ID/dns_records?per_page=500" 2>/dev/null) || dns_json=""
  if [ -n "$dns_json" ]; then
    mapfile -t ZONE_HOSTS < <(echo "$dns_json" | python3 -c '
import json,sys
d=json.load(sys.stdin)
hosts=sorted({r["name"] for r in d.get("result",[]) if r.get("type") in ("A","AAAA","CNAME")})
for h in hosts:
    if h.endswith("home-security.uk") and not h.startswith(("_","*")): print(h)' 2>/dev/null)
  fi
  wk_json=$(cf_api GET "/accounts/$CF_ACCOUNT_ID/workers/scripts?per_page=100" 2>/dev/null) || wk_json=""
  if [ -n "$wk_json" ]; then
    mapfile -t WORKERS_DEV < <(echo "$wk_json" | python3 -c '
import json,sys
d=json.load(sys.stdin)
for s in d.get("result",[]): print(s["id"])' 2>/dev/null)
  fi
  [ ${#ZONE_HOSTS[@]} -eq 0 ] && { echo "WARN: API discovery failed, using static lists"; ZONE_HOSTS=("${STATIC_HOSTS[@]}"); WORKERS_DEV=("${STATIC_WORKERS[@]}"); }
else
  echo "== Static host/worker lists (no CLOUDFLARE_API_TOKEN) =="
  ZONE_HOSTS=("${STATIC_HOSTS[@]}"); WORKERS_DEV=("${STATIC_WORKERS[@]}")
fi

# MUST headers from .agents/rules/security-headers.md
REQUIRED_HEADERS=(
  "strict-transport-security|max-age=31536000"
  "content-security-policy|default-src 'self'"
  "x-content-type-options|nosniff"
  "x-frame-options|DENY"
  "cross-origin-opener-policy|same-origin"
  "cross-origin-resource-policy|same-origin"
  "referrer-policy|"
  "permissions-policy|camera=()"
)

FAIL=0
TMPD="$(mktemp -d)"; trap 'rm -rf "$TMPD"' EXIT

check_host() {
  local host="$1" url="https://$1/" headers_file="$TMPD/h"
  local code
  code=$(curl -sS -o /dev/null -D "$headers_file" -A "sec-headers-audit/1.0" \
        --max-time 15 -w '%{http_code}' "$url" 2>/dev/null) || {
    echo "FAIL $host — unreachable"; FAIL=1; return; }
  [ "$VERBOSE" = 1 ] && echo "--- $host ($code)"

  local missing=0 pair name want got
  for pair in "${REQUIRED_HEADERS[@]}"; do
    name="${pair%%|*}"; want="${pair#*|}"
    got=$(grep -i "^${name}:" "$headers_file" | head -1 | tr -d '\r')
    if [ -z "$got" ]; then
      echo "FAIL $host — missing $name"; missing=1; continue
    fi
    if [ -n "$want" ] && ! echo "$got" | grep -qi "$want"; then
      echo "FAIL $host — $name is '$got' (want substring: $want)"; missing=1
    fi
  done
  [ "$missing" = 0 ] && echo "PASS $host ($code)"
  [ "$missing" = 1 ] && FAIL=1
}

check_workers_dev() {
  local w code
  for w in "${WORKERS_DEV[@]}"; do
    code=$(curl -sS -o /dev/null -w '%{http_code}' --max-time 15 \
          -A "sec-headers-audit/1.0" \
          "https://${w}.${WORKERS_SUBDOMAIN}.workers.dev/" 2>/dev/null) || code="000"
    if [ "$code" = "404" ] || [ "$code" = "000" ]; then
      echo "PASS ${w}.workers.dev ($code)"
    else
      echo "FAIL ${w}.workers.dev — HTTP $code (expected 404; workers.dev bypasses zone controls)"
      FAIL=1
    fi
  done
}

echo "== Zone hosts (${#ZONE_HOSTS[@]}) =="
for h in "${ZONE_HOSTS[@]}"; do check_host "$h"; done
echo "== workers.dev endpoints (${#WORKERS_DEV[@]}, must be 404) =="
check_workers_dev
[ "$FAIL" = 0 ] && echo "ALL CHECKS PASSED" || echo "FAILURES FOUND"
exit "$FAIL"
