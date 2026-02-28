# Local K8s ArgoCD

This repo owns ArgoCD bootstrap and shared cluster policy. Pair it with `local-k8s-apps`, which holds the actual application `Application` resources.

## Repo Shape
- Bootstrap manifests live in `manifests/argocd/`.
- The two root applications are:
  - `manifests/argocd/appproject-app.yaml`
  - `manifests/argocd/app-of-apps-app.yaml`
- Shared ArgoCD project policy lives in `manifests/config/appproject.yaml`.
- Helm values for the ArgoCD install live in `manifests/config/values.yaml`.

## Working Rules
- Keep infra changes here and day-to-day app additions in `local-k8s-apps`.
- If an app in `local-k8s-apps` pulls a Helm chart from a git repo, add that repo URL to `manifests/config/appproject.yaml` under `sourceRepos` or ArgoCD will reject it.
- Changes on `main` affect cluster bootstrap behavior, so favor small PRs and verify manifest paths carefully.
- `quick-start.sh` is the bootstrap entrypoint referenced by the README.

## Colima Baseline
- Recommended:

```bash
colima start --kubernetes --cpu 4 --memory 6 \
  --mount ~/clusterstorage:w \
  --mount ~/.secrets:/mnt/secrets:ro
```

- Full reset:

```bash
colima delete -f && colima prune -af
colima start --kubernetes --cpu 4 --memory 6 \
  --mount ~/clusterstorage:w \
  --mount ~/.secrets:/mnt/secrets:ro
```

## Releases
- Add each merged change to `RELEASES.md` under `[Unreleased]`.
- Batch roughly 2-3 changes per release.
- On release, move unreleased notes into a versioned section like `[v0.3.0] - YYYY-MM-DD`, tag it, and publish the GitHub release.
