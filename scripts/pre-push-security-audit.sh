#!/usr/bin/env bash
# Devin PreToolUse hook: run the live security-headers audit before any
# `git push` in this workspace. Blocks the push if the MUST header baseline
# or workers.dev lockdown has regressed.
set -euo pipefail

PAYLOAD=$(cat)
COMMAND=$(echo "$PAYLOAD" | jq -r '.tool_input.command // empty')

# Only intercept git push commands
if [[ "$COMMAND" != *"git push"* ]]; then
  exit 0
fi

ROOT="${DEVIN_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
cd "$ROOT"

block() {
  jq -n --arg r "$1" '{decision:"block", reason:$r}'
  exit 0
}

AUDIT="$ROOT/scripts/security-headers-audit.sh"
if [[ ! -x "$AUDIT" ]]; then
  # script may live at workspace root even when pushing from a project repo
  WS_ROOT="$(git -C "$ROOT" rev-parse --show-toplevel 2>/dev/null || echo "$ROOT")"
  for cand in "$ROOT/scripts/security-headers-audit.sh" \
              "$WS_ROOT/../../scripts/security-headers-audit.sh" \
              "$HOME/workspace/cloudflare-workspace/scripts/security-headers-audit.sh"; do
    [ -x "$cand" ] && AUDIT="$cand" && break
  done
fi

if [[ ! -x "$AUDIT" ]]; then
  echo "pre-push-security-audit: audit script not found, skipping" >&2
  exit 0
fi

if ! AUDIT_OUT=$(bash "$AUDIT" 2>&1); then
  block "security-headers audit failed — push blocked. Fix regressions (missing MUST headers or live workers.dev endpoint) and retry.\n$(printf '%s' "$AUDIT_OUT" | tail -40)"
fi

echo "pre-push-security-audit: passed" >&2
exit 0
