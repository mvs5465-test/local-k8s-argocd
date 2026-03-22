# Local K8s Infrastructure

ArgoCD bootstrap and shared cluster policy for a local Kubernetes cluster. Pair this repo with [`local-k8s-apps`](https://github.com/mvs5465-test/local-k8s-apps), which holds the day-to-day `Application` manifests consumed by the ApplicationSet defined here.

## What This Repo Owns

- ArgoCD installation and bootstrap entrypoint in `quick-start.sh`
- Root ArgoCD applications in `manifests/argocd/`
- The cluster app `ApplicationSet` in `manifests/applicationsets/cluster-apps.yaml`
- Shared AppProject policy and repo allowlists in `manifests/config/appproject.yaml`

## Quick Start

### Prerequisites

```bash
brew install colima docker kubectl
colima start --kubernetes --cpu 4 --memory 6 \
  --mount ~/clusterstorage:w \
  --mount ~/.secrets:/mnt/secrets:ro
```

### Bootstrap ArgoCD

```bash
cd ~/projects/local-k8s-argocd
chmod +x quick-start.sh
./quick-start.sh
```

`quick-start.sh`:

- installs ArgoCD via Helm
- applies the root ArgoCD resources from `manifests/argocd/`
- creates idempotent master secrets in `external-secrets` from `~/.secrets/` when those files are present

## Access Cluster Services

1. Port-forward the ingress controller:

   ```bash
   sudo kubectl port-forward -n ingress-nginx svc/nginx-ingress-ingress-nginx-controller 80:80 443:443
   ```

2. Add a wildcard entry to `/etc/hosts`:

   ```text
   127.0.0.1 *.lan
   ```

3. Open `http://home.lan`.

## Repo Layout

```text
manifests/argocd/
  appproject-app.yaml      # self-manages shared AppProject config
  applicationset-app.yaml  # self-manages the cluster app ApplicationSet
manifests/applicationsets/
  cluster-apps.yaml        # generates live app Applications from local-k8s-apps
manifests/config/
  appproject.yaml          # sourceRepos allowlist and cluster policy
quick-start.sh             # local bootstrap entrypoint
```

## Working In This Repo

- Keep routine app additions in `local-k8s-apps`, not here.
- If an app in `local-k8s-apps` pulls from a git repo, add that repo URL to `manifests/config/appproject.yaml` or ArgoCD will reject it.
- When bootstrap behavior or user-facing cluster docs change, update the seeded docs in `cluster-lite-wiki` as a companion PR.

See `AGENTS.md` and `CLAUDE.md` for contributor-specific guidance.
