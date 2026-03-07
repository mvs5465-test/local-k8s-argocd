# Local K8s ArgoCD - Infrastructure Configuration

This repo contains ArgoCD infrastructure and configuration. Pair with [`local-k8s-apps`](https://github.com/mvs5465-test/local-k8s-apps) for application definitions.

## Two-Repo Architecture

**Why separate repos?**
- Prevents "chicken-and-egg": ArgoCD watches main branch for its own config, but also watches app repos
- Allows safe feature-branch testing in applications repo without modifying ArgoCD
- Clear separation: infrastructure (stable) vs applications (active development)

**This Repo** (`local-k8s-argocd`):
- AppProject, root applications, ArgoCD installation
- Application manifests: `manifests/argocd/root-system-app.yaml`, `manifests/argocd/root-apps-app.yaml`
- These point to `local-k8s-apps` repo

**Other Repo** (`local-k8s-apps`):
- Actual application definitions (Prometheus, Grafana, Dashboard, File Server, Loki MCP)
- Can iterate freely without touching this repo's ArgoCD config

**Adding new application repositories:**
When you add a new Application in `local-k8s-apps` that pulls its Helm chart from a git repo (not a public Helm repo), you must whitelist that repo's URL in `manifests/config/appproject.yaml` under `sourceRepos`. Example: loki-mcp-server pulls from its own GitHub repo, so `https://github.com/mvs5465-test/loki-mcp-server` was added to sourceRepos.

## Colima Configuration

**Recommended specs** (with native Ollama on Mac):
```bash
colima start --kubernetes --cpu 4 --memory 6 \
  --mount ~/clusterstorage:w \
  --mount ~/.secrets:/mnt/secrets:ro
```

**Why these limits?**
- 4 CPU: Headroom for k3s scheduling and service performance
- 6GB memory: k3s VM overhead + cluster services (~1-2GB); leaves room for caching/buffers
- `~/clusterstorage`: Persistent storage for Jellyfin, local app data, and caches across resets
- Ollama GPU: Runs natively on macOS M2 with Metal acceleration (separate from cluster)

**Full Colima reset** (if needed):
```bash
colima delete -f && colima prune -af
colima start --kubernetes --cpu 4 --memory 6 \
  --mount ~/clusterstorage:w \
  --mount ~/.secrets:/mnt/secrets:ro
```

## Guidelines for Claude Code

### Versioning & Releases
**Release strategy:** Batch 2-3 changes per release to keep history clean and readable.

1. **Update RELEASES.md** with each PR (add to `[Unreleased]` section)
2. **When releasing (after 2-3 PRs merged):**
   - Move `[Unreleased]` changes to new version section (e.g., `[v0.3.0] - YYYY-MM-DD`)
   - Use semantic versioning: MAJOR.MINOR.PATCH
     - MINOR bump for features/enhancements
     - PATCH bump for bug fixes/tweaks
   - Create git tag: `git tag -a vX.Y.Z -m "release message"`
   - Push tag: `git push origin vX.Y.Z`
   - Create GitHub release: `gh release create vX.Y.Z --notes-file RELEASES.md`

### Release Notes
- Add changes under `[Unreleased]` section during development
- Use standard categories: Added, Changed, Fixed, Removed, Security
- Keep notes brief and user-focused

### Documentation Strategy
- README.md: Tech stack summary + setup only
- RELEASES.md: Change history and feature tracking
- CLAUDE.md: Project instructions for Claude Code
- No separate human docs (Claude is the maintainer)

### Future Enhancements
- MCP server for Claude to query cluster state
- Automated deployment via ArgoCD itself

## File Server - Final Approach
Nginx static file server using hostPath volume.

**Design:**
- Container: nginx
- Files location: `/tmp/files` on k3s node
- Volume: hostPath, read-only
- Pod: pinned to node with `nodeName: colima`
- Expose: NodePort 30080
- Manifest: `manifests/fileserver.yaml`

**Setup requirement:**
Files must be placed in `/tmp/files` inside Colima VM (via `colima ssh` or copied in)

**Discarded approaches:**
- Flask app + ConfigMaps (removed)
- PersistentVolume / NFS / SMB (too complex)
- Custom app logic (not needed)
