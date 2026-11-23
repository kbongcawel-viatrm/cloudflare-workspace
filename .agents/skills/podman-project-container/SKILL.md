---
name: podman-project-container
description: Prepare, validate, deploy, and verify a project's rootless Podman container stack under projects/<name>/compose.yaml — registry whitelisting, compose rules, host-side podman-compose/podman wrappers, health checks. Use before running workspace-deploy or whenever a cloudflare-workspace project needs containers.
---

# Podman project container workflow

Runs BEFORE `workspace-deploy`/project release whenever a project needs a
container. All podman/podman-compose commands MUST go through the host
wrappers so they execute on the host, not inside Toolbox:

- `./scripts/podman-compose-host.sh` — podman-compose on the host
- `./scripts/podman-host.sh` — podman on the host
- `./scripts/host-exec.sh` — generic host-namespace exec (flatpak-spawn)

## 1. Whitelist the registry

Check `/etc/containers/policy.json` — if the registry of the needed image
is not covered, add it. If the Dockerfile's base image is not yet
whitelisted, add it together with the `localhost` image being built.

```json
"localhost/gondar-v2_uptime-agent": [
    {
         "type": "insecureAcceptAnything"
    }
],
```

Note: editing `/etc/containers/policy.json` needs root — ask the operator
(polkit prompt) first. Alternative: the host wrappers honor a
project-local `containers-policy.json` at the workspace root via
`CONTAINERS_POLICY_JSON`; prefer that when possible (no root needed).

## 2. Validate the policy file

```bash
jq empty /etc/containers/policy.json
# or for the project-local file:
jq empty containers-policy.json
```

- No output (exit 0): valid JSON.
- Error: shows the exact line/column of the syntax error.

## 3. Prepare and validate `projects/<project_name>/compose.yaml`

Rules:
- `pull_policy: never` on built/local images.
- Resource limits under `deploy.resources.limits`:

```yaml
deploy:
  resources:
    limits:
      cpus: '0.1'
      memory: 64M
```

Adjust as needed, but ASK FOR APPROVAL when cpu > 1.0 or memory > 256M.

Validate the file (normalized YAML, resolved vars/paths):

```bash
cd $HOME/workspace/cloudflare-workspace/
./scripts/podman-compose-host.sh -f projects/<project_name>/compose.yaml config > /dev/null
```

- Exit 0: valid.
- Non-zero: YAML/parse traceback or unsupported field — fix before deploy.

## 4. Deploy

```bash
./scripts/podman-compose-host.sh -f projects/<project_name>/compose.yaml up -d
```

Container start/stop is consequential — get operator approval first
(polkit may prompt; let the operator approve).

## 5. Verify health

```bash
# Container status
./scripts/podman-host.sh ps | grep <project_name>

# Logs
./scripts/podman-host.sh logs <project_name>_<service>_1
# (or: podman-compose-host.sh -f ... logs <service>)
```

Ensure the container reports healthy (compose `healthcheck` or
`podman inspect --format '{{.State.Health.Status}}'`). Then verify the
published endpoint (`curl http://127.0.0.1:<port>/health`) and the public
tunnel hostname if one exists.

## Destructive ops — always ask first

`down`, `rm`, `rmi`, `system prune`, `reset`, image deletion, and any
`podman-host.sh` mutation beyond `ps`/`logs`/`inspect`.
