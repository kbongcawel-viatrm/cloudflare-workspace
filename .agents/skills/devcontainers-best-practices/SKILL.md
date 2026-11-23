---
name: devcontainers-best-practices
description: Consult whenever setting up, editing, validating, or debugging a Dev Container, GitHub Codespaces, or devcontainer.json.
---

# Dev Containers and Codespaces

- Follow the Dev Container specification and official schema.
- Prefer `forwardPorts` for local service access.
- Use reproducible and idempotent lifecycle commands.
- Do not include credentials in the image, Dockerfile, devcontainer.json, or build args.
- Review lifecycle commands because they execute code inside the development environment.
- Rebuild the Codespace after changing the Dev Container definition.

References:
- https://containers.dev/implementors/spec/
- https://containers.dev/implementors/json_reference/
- https://containers.dev/implementors/json_schema/
- https://docs.github.com/en/codespaces
