---
name: create-helm-chart
description: "Instructions for creating new helm charts."
---

## When this applies

Applies when creating or deploying helm charts.


## Rules

- Never use `kubectl` to modify cluster state (`apply`, `edit`, `patch`,
  `scale`, `delete`, `replace`, `rollout restart`, `create`, `cordon`,
  `drain`). Cluster state is reconciled from manifests committed to the
  repo via the project's GitOps controller (Argo CD, Flux) or CI pipeline.
- Read-only `kubectl` is fine: `get`, `describe`, `logs`, `top`, `events`,
  `explain`, `auth can-i`.
- When a change is needed, edit the manifest in the repo and commit; let
  the GitOps controller or CI roll it out.

## Examples

**DO:**

```yaml
# k8s/deployment.yaml — edit and commit; GitOps reconciles.
spec:
  replicas: 5
```

**DON'T:**

```bash
kubectl scale deployment foo --replicas=5
```
