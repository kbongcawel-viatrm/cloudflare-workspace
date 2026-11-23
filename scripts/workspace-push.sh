#!/usr/bin/env bash
set -Eeuo pipefail

usage() { echo "Usage: workspace-push [commit-message]"; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then usage; exit 0; fi
MESSAGE="${1:-chore: update application}"
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || die "Run inside a Git repository."
cd -- "$ROOT"
BRANCH="$(git branch --show-current)"
[[ "$BRANCH" == "main" ]] || die "Current branch is '$BRANCH'; workspace-push only pushes main."
git remote get-url origin >/dev/null 2>&1 || die "No origin remote configured."

if git diff --quiet && git diff --cached --quiet && [[ -z "$(git ls-files --others --exclude-standard)" ]]; then
  die "No changes to commit."
fi

git add -u
git add -- .
git diff --cached --check
printf '\nStaged summary:\n'
git diff --cached --stat
printf '\nStaged paths:\n'
git status --short
read -r -p "Commit and push these changes to origin/main? [y/N] " CONFIRM
[[ "$CONFIRM" =~ ^[Yy]$ ]] || die "Aborted without committing or pushing."

git commit -m "$MESSAGE"
git push origin main
git status --short --branch
git log -1 --format='Committed: %h %s'
