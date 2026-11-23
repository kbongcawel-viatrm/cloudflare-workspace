---
name: github-actions
description: Design and validate GitHub Actions CI/CD workflows, secrets, permissions, concurrency, artifacts, and deployment summaries.
---

# GitHub Actions

- Keep workflow permissions minimal and explicit.
- Pin actions to immutable SHAs for high-assurance environments; document update cadence when using tags.
- Use repository Actions secrets for credentials; never echo secrets or write them into artifacts.
- Use concurrency controls to avoid overlapping production deployments.
- Publish concise deployment URLs and commit metadata to `GITHUB_STEP_SUMMARY`.
- Upload only non-secret deployment metadata as artifacts.

References:
- https://docs.github.com/en/actions
- https://docs.github.com/en/actions/security-guides/automatic-token-authentication
