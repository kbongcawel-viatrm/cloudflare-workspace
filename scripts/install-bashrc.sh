#!/usr/bin/env bash
set -Eeuo pipefail

usage() { printf 'Usage: install-bashrc.sh [--user-hook]\n'; }
INSTALL_USER_HOOK=0
while (($#)); do
  case "$1" in
    --user-hook) INSTALL_USER_HOOK=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

SCRIPT_PATH="${BASH_SOURCE[0]}"
while [[ -L "$SCRIPT_PATH" ]]; do
  _dir="$(cd -P "$(dirname -- "$SCRIPT_PATH")" && pwd)"
  SCRIPT_PATH="$(readlink -- "$SCRIPT_PATH")"
  [[ "$SCRIPT_PATH" != /* ]] && SCRIPT_PATH="$_dir/$SCRIPT_PATH"
done
ROOT="$(cd -P "$(dirname -- "$SCRIPT_PATH")/.." && pwd)"
PROFILE="$ROOT/.bashrc"
TARGET="$HOME/.bashrc.workspace"
USER_BASHRC="$HOME/.bashrc"
MARKER="# >>> cloudflare-app-workspace >>>"

[[ -f "$PROFILE" ]] || { printf 'Missing project .bashrc: %s\n' "$PROFILE" >&2; exit 1; }
bash -n "$PROFILE"
install -m 600 -- "$PROFILE" "$TARGET"
printf 'Installed project Bash profile: %s\n' "$TARGET"

if (( INSTALL_USER_HOOK )); then
  [[ ! -L "$USER_BASHRC" ]] || { printf 'Refusing to modify symlinked %s\n' "$USER_BASHRC" >&2; exit 1; }
  if [[ -f "$USER_BASHRC" ]] && grep -Fq "$MARKER" "$USER_BASHRC"; then
    printf 'Bash hook already exists in %s; unchanged.\n' "$USER_BASHRC"
    exit 0
  fi
  if [[ -e "$USER_BASHRC" ]]; then
    cp -p -- "$USER_BASHRC" "$USER_BASHRC.bak.$(date +%Y%m%d%H%M%S)"
  else
    install -m 600 /dev/null "$USER_BASHRC"
  fi
  {
    printf '\n%s\n' "$MARKER"
    printf 'if [[ $- == *i* && -f "$HOME/.bashrc.workspace" ]]; then\n'
    printf '  . "$HOME/.bashrc.workspace"\n'
    printf 'fi\n'
    printf '# <<< cloudflare-app-workspace <<<\n'
  } >> "$USER_BASHRC"
  printf 'Added guarded interactive Bash hook. A backup was retained if ~/.bashrc existed.\n'
fi
