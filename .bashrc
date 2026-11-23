# Project shell profile adapted from:
# https://github.com/kbongcawel-viatrm/ai-stack/blob/main/projects/bash/bashrc_template
#
# Only portable terminal helpers are enabled. Host-specific operations,
# privilege wrappers, firewall/network changes, personal paths, credential
# loaders, Cline auto-approval, and forced inactivity logout are intentionally
# excluded from this Codespaces-safe profile.

if [[ -f /etc/bashrc ]]; then
  . /etc/bashrc
fi

for _dir in "$HOME/.local/bin" "$HOME/bin"; do
  if [[ -d "$_dir" && ":$PATH:" != *":$_dir:"* ]]; then
    PATH="$_dir:$PATH"
  fi
done
unset _dir

export PATH
export EDITOR="${EDITOR:-vi}"
export VISUAL="${VISUAL:-$EDITOR}"
export HISTCONTROL=ignoreboth
shopt -s histappend 2>/dev/null || true

# Portable terminal helpers from the upstream template.
tcat() {
  [[ "${KIMCTL_QUIET:-0}" == 1 ]] && return 0
  [[ -w /dev/tty ]] || { printf 'Error: No writable terminal available.\n' >&2; return 1; }
  command cat -- "$@" > /dev/tty
}

_terminal_msg() {
  local status="${1:-normal}" label color
  case "$status" in
    success|error|warning|normal) shift ;;
    *) status=normal ;;
  esac
  [[ "${KIMCTL_QUIET:-0}" == 1 ]] && return 0
  case "$status" in
    success) label=" OK  "; color='1;32' ;;
    error) label="FAIL "; color='1;31' ;;
    warning) label="WARN "; color='1;33' ;;
    normal) label="INFO "; color='1;36' ;;
  esac
  if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
    printf '  \033[%sm[%s]\033[0m %s\n' "$color" "$label" "$*"
  else
    printf '  [%s] %s\n' "$label" "$*"
  fi
}

_terminal_line() {
  [[ "${KIMCTL_QUIET:-0}" == 1 ]] && return 0
  local type="${1:-normal}" width="${2:-32}" char='\u2500' color='1;36' line
  case "$type" in
    success) color='1;32' ;;
    warning) color='1;33' ;;
    error) color='1;31' ;;
  esac
  (( width > 48 )) && width=48
  (( width < 8 )) && width=8
  printf -v line '%*s' "$width" ''
  line="${line// /$char}"
  if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
    printf '  \033[%sm%s\033[0m\n' "$color" "$line"
  else
    printf '  %s\n' "$line"
  fi
}

run_with_loader() {
  local label="${1:-Running}"
  shift
  (( $# > 0 )) || { printf 'Usage: run_with_loader "label" command [arguments...]\n' >&2; return 2; }
  "$@"
}

givemespace() { printf '\n\n'; }

workspace-root() {
  git rev-parse --show-toplevel 2>/dev/null || printf '%s\n' "$PWD"
}

workspace-push() {
  local root
  root="$(workspace-root)" || return
  [[ -x "$root/scripts/workspace-push.sh" ]] || {
    printf 'workspace-push script not found under %s\n' "$root" >&2
    return 127
  }
  "$root/scripts/workspace-push.sh" "$@"
}
