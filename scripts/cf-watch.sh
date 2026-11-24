#!/usr/bin/env bash
# cf-watch.sh — tail Cloudflare HTTP requests for the home-sec-uk account.
#
# Polls the GraphQL Analytics API (httpRequestsAdaptiveGroups) and prints
# new requests as they appear: time, method, status, host, path, country.
#
# Usage:
#   scripts/cf-watch.sh [--interval SEC] [--window MIN] [--host HOST]
#
# Requires CF_API_TOKEN + CLOUDFLARE_ACCOUNT_ID (sources ~/.config/cf-creds.env).
set -Eeuo pipefail

CRED_FILE="${CF_CREDS_FILE:-$HOME/.config/cf-creds.env}"
[[ -f "$CRED_FILE" ]] && source "$CRED_FILE"
: "${CF_API_TOKEN:?set CF_API_TOKEN (or CF_CREDS_FILE)}"
ACCOUNT_ID="${CLOUDFLARE_ACCOUNT_ID:?set CLOUDFLARE_ACCOUNT_ID}"
ZONE_NAME="${CF_ZONE_NAME:-home-security.uk}"
INTERVAL="${CF_WATCH_INTERVAL:-30}"
WINDOW_MIN="${CF_WATCH_WINDOW:-10}"
FILTER_HOST="${CF_WATCH_HOST:-}"
FORMAT_FLAGS=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --interval) INTERVAL="$2"; shift 2 ;;
    --window)   WINDOW_MIN="$2"; shift 2 ;;
    --host)     FILTER_HOST="$2"; shift 2 ;;
    --only-200) FORMAT_FLAGS="$FORMAT_FLAGS --only-200"; shift ;;
    --no-200)   FORMAT_FLAGS="$FORMAT_FLAGS --no-200"; shift ;;
    --status)   FORMAT_FLAGS="$FORMAT_FLAGS --status $2"; shift 2 ;;
    --[0-9]*x|--[0-9]*X|--[0-9][0-9][0-9]) FORMAT_FLAGS="$FORMAT_FLAGS --status ${1#--}"; shift ;;
    --zone)     ZONE_NAME="$2"; shift 2 ;;
    -h|--help)  sed -n '2,12p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

API="https://api.cloudflare.com/client/v4/graphql"
SEEN=/tmp/cf-watch-seen.$$
trap 'rm -f "$SEEN"' EXIT
: > "$SEEN"

GEQ="$(date -u -d "-$WINDOW_MIN minutes" +%Y-%m-%dT%H:%M:%SZ)"

host_filter=""
[[ -n "$FILTER_HOST" ]] && host_filter=", clientRequestHTTPHost: \"$FILTER_HOST\""

QUERY="{\"query\":\"query { viewer { accounts(filter: {accountTag: \\\"$ACCOUNT_ID\\\"}) { httpRequestsAdaptiveGroups(limit: 1000, filter: {datetime_geq: \\\"$GEQ\\\", datetime_leq: \\\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\\\"$host_filter}, orderBy: [datetime_DESC]) { count dimensions { datetime clientRequestHTTPMethodName clientRequestPath clientRequestHTTPHost edgeResponseStatus clientCountryName securityAction } } } } }\"}"

echo "watching account $ACCOUNT_ID ($ZONE_NAME) — interval ${INTERVAL}s, window ${WINDOW_MIN}m — Ctrl-C to stop" >&2

while true; do
  NOW="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  GEQ="$(date -u -d "-$WINDOW_MIN minutes" +%Y-%m-%dT%H:%M:%SZ)"
  QUERY="{\"query\":\"query { viewer { accounts(filter: {accountTag: \\\"$ACCOUNT_ID\\\"}) { httpRequestsAdaptiveGroups(limit: 1000, filter: {datetime_geq: \\\"$GEQ\\\", datetime_leq: \\\"$NOW\\\"$host_filter}, orderBy: [datetime_ASC]) { count dimensions { datetime clientRequestHTTPMethodName clientRequestPath clientRequestHTTPHost edgeResponseStatus clientCountryName securityAction } } } } }\"}"

  RESP="$(curl -sf --max-time 20 "$API" \
    -H "Authorization: Bearer $CF_API_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$QUERY" || true)"

  [[ -n "$RESP" ]] || { sleep "$INTERVAL"; continue; }

  printf '%s' "$RESP" | python3 "$(dirname "$0")/cf-watch-format.py" "$SEEN"$FORMAT_FLAGS

  sleep "$INTERVAL"
done
