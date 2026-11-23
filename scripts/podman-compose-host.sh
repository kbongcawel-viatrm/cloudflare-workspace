#!/usr/bin/env bash
# podman-compose wrapper that always runs on the HOST (not inside Toolbox)
#
# Usage:
#   ./scripts/podman-compose-host.sh -f compose.yaml up -d
#   ./scripts/podman-compose-host.sh -f compose.yaml ps

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
HOST_EXEC="$SCRIPT_DIR/host-exec.sh"

# Resolve physical host path so both Toolbox and Host see the exact same path
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"
POLICY_FILE="$PROJECT_ROOT/containers-policy.json"

run_on_host_shell() {
    local policy_file="$1"
    shift

    if [[ -r "$policy_file" ]]; then
        export CONTAINERS_POLICY_JSON="$policy_file"
    fi

    local executable
    executable="$(command -v podman-compose || true)"
    if [[ -z "$executable" ]]; then
        echo "Error: podman-compose is not installed on the host." >&2
        echo "Install the standalone podman-compose package on the host, then retry." >&2
        exit 127
    fi

    exec "$executable" "$@"
}

# Check if we're inside Toolbox (or Flatpak/Distrobox)
if [[ -e /run/.toolboxenv || -e /run/.containerenv ]]; then
    if [[ ! -x "$HOST_EXEC" ]]; then
        echo "Error: Helper script not found or not executable: $HOST_EXEC" >&2
        exit 1
    fi

    # 1. Unset CONTAINER_HOST so rootless podman uses the host's local socket/storage
    # 2. Explicitly cd into the current working directory on the host
    # 3. Pass POLICY_FILE as an explicit positional arg so it survives flatpak-spawn/host-spawn
    exec env -u CONTAINER_HOST "$HOST_EXEC" bash -c '
        target_dir="$1"
        policy_file="$2"
        shift 2

        cd "$target_dir" || {
            echo "Error: Cannot access directory $target_dir on host." >&2
            exit 1
        }

        if [[ -r "$policy_file" ]]; then
            export CONTAINERS_POLICY_JSON="$policy_file"
        fi

        executable="$(command -v podman-compose || true)"
        if [[ -z "$executable" ]]; then
            echo "Error: podman-compose is not installed on the host." >&2
            echo "Install the standalone podman-compose package on the host, then retry." >&2
            exit 127
        fi

        exec "$executable" "$@"
    ' bash "$PWD" "$POLICY_FILE" "$@"
else
    run_on_host_shell "$POLICY_FILE" "$@"
fi
