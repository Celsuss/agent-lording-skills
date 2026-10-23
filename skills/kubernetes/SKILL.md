---
name: kubernetes
description: "Rules and conventions when working with Kubernetes manifests or kubectl. TRIGGER when: editing .yaml/.yml manifests under k8s/, manifests/, kustomize/, helm/, or any YAML containing both `apiVersion:` and `kind:`; or when invoking `kubectl`. SKIP when: editing unrelated YAML (CI configs, generic application config) or non-Kubernetes infrastructure. Enforces GitOps: cluster state changes go through manifests in the repo, never ad-hoc kubectl writes."
---

## When this applies

Applies when editing Kubernetes manifests (`.yaml`/`.yml` files under `k8s/`,
`manifests/`, `kustomize/`, `helm/`, or any YAML containing both `apiVersion:`
and `kind:`) or when running `kubectl` against a cluster.

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
