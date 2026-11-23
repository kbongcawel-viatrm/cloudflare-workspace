#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  cat <<'USAGE'
Usage: workspace-validate [--install] [--skip-wrangler] [--help]

Run local validation without deploying:
  - Bash syntax checks for workspace scripts
  - Node.js syntax checks for JavaScript build scripts
  - npm tests, TypeScript type-check, and application build
  - Wrangler deploy --dry-run to validate Worker packaging/configuration

Options:
  --install       Run npm install if dependencies are missing
  --skip-wrangler Skip the Wrangler packaging dry-run
  -h, --help      Show this help
USAGE
}

die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

INSTALL=0
SKIP_WRANGLER=0
while (($#)); do
  case "$1" in
    --install) INSTALL=1; shift ;;
    --skip-wrangler) SKIP_WRANGLER=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown option: $1" ;;
  esac
done

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

for cmd in bash node npm; do
  command -v "$cmd" >/dev/null 2>&1 || die "Required command not found: $cmd"
done

printf '\n==> Checking Bash syntax\n'
for script in scripts/*.sh; do
  bash -n "$script"
  printf '  OK %s\n' "$script"
done

printf '\n==> Checking JavaScript syntax\n'
for script in scripts/*.mjs; do
  node --check "$script"
  printf '  OK %s\n' "$script"
done

if [[ ! -d node_modules ]]; then
  if (( INSTALL )); then
    printf '\n==> Installing npm dependencies\n'
    npm install
  else
    die 'node_modules is missing. Run npm install, or rerun workspace-validate --install.'
  fi
fi

printf '\n==> Running tests\n'
npm test

printf '\n==> Running TypeScript type-check\n'
npm run typecheck

printf '\n==> Running application build\n'
npm run build

if (( ! SKIP_WRANGLER )); then
  printf '\n==> Validating Wrangler deployment package (no deployment)\n'
  if [[ -x node_modules/.bin/wrangler ]]; then
    node_modules/.bin/wrangler deploy --dry-run
  else
    die 'Local Wrangler binary not found. Run npm install or workspace-validate --install.'
  fi
fi

printf '\nValidation passed. No Cloudflare deployment was performed.\n'
