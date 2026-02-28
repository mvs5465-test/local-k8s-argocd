# Local K8s ArgoCD

This repo owns ArgoCD bootstrap and shared cluster policy. Pair it with `local-k8s-apps`, which holds the day-to-day application `Application` resources.

## Repo Shape
- Bootstrap manifests live in `manifests/argocd/`
- Shared ArgoCD config lives in `manifests/config/`
- The two root applications are:
  - `manifests/argocd/appproject-app.yaml`
  - `manifests/argocd/applicationset-app.yaml`
- `manifests/config/appproject.yaml` is the main cross-repo allowlist and policy file
- `quick-start.sh` is the bootstrap entrypoint referenced by the README

## Working Rules
- Keep bootstrap, shared policy, and ArgoCD infra changes here.
- Put routine app additions and app-specific ArgoCD manifests in `local-k8s-apps`, not here.
- If an app repo is sourced directly from git, add that repo URL to `manifests/config/appproject.yaml` `sourceRepos` or ArgoCD will reject it.
- Changes on `main` affect cluster bootstrap behavior, so keep PRs small and verify paths and repo URLs carefully.
- PR titles must use the same Conventional Commit format as commits: `<type>(<scope>): <description>`.
- Before handing off a PR, verify the latest commit message and the PR title both match that format.
- If a bootstrap, namespace, access, or entrypoint change affects how the cluster is documented, update `cluster-lite-wiki/seed/pages/` in a companion PR so seeded docs stay aligned.

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

## Validation
- Sanity-check manifest paths after any move or rename.
- Treat `manifests/config/appproject.yaml` changes as high-impact because they control what ArgoCD can sync.
- If you change bootstrap behavior, verify it still lines up with the repo structure in `local-k8s-apps`.
