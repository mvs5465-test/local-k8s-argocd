# Release Notes

## [Unreleased]

### Changed
- Replaced direct app-of-apps fan-out with an `ApplicationSet` rollout
- Root bootstrap application now applies `manifests/applicationsets` from this repo
- `quick-start.sh` now bootstraps the root ArgoCD `Application` resources so this repo self-manages
- Generated applications now render with auto-sync explicitly enabled
- Renamed the bootstrap `Application` for ApplicationSets from `applicationset-app` to `appset`
- Cluster `ApplicationSet` now reads wave-based app folders (`apps/wave-0`, `apps/wave-1`, `apps/wave-2`) and assigns generated apps both `cluster.local/wave` and `argocd.argoproj.io/sync-wave`

### Added
- AppProject source repo allowlist entry for `cluster-lite-wiki`
- AppProject source repo allowlist entry for `cluster-home`
- AppProject source repo allowlist entry for `grafana-community`

### Removed
- Outline namespace destination from the AppProject
- Outline secret bootstrap logic from `quick-start.sh`
- Homepage references in bootstrap and README (Cluster Home is now the primary entrypoint)
- Ollama external application from the cluster ApplicationSet

## [v1.3.1] - 2026-02-22 - Documentation Cleanup

### Changed
- Improved README readability with simplified architecture diagram
- Updated colima startup command with all necessary mounts and 8GB memory
- Simplified service access section to link directly to homepage
- Removed redundant "What's Inside" section

### Removed
- Misleading authentication comments from values.yaml
- Bootstrap loop comment from appproject-app.yaml
- architecture.svg file (replaced with text-based diagram)

## [v1.3.0] - 2026-02-22 - ArgoCD Metrics & Quick-Start Automation

### Added
- **ArgoCD metrics services** — enabled dedicated metrics services for server, controller, repo-server, applicationset-controller
- **Quick-start automation** — port-forward runs automatically after homepage is ready
- **Quick-start pbcopy** — ArgoCD admin password copied to clipboard automatically

### Fixed
- ArgoCD values.yaml structure — extraArgs and ingress were detached from server block causing --insecure to bleed into applicationset-controller
- quick-start.sh port-forward output redirection removed to surface errors
- quick-start.sh waits for homepage pod (not service) before port-forward

## [v1.2.0] - 2026-02-21 - AppProject Stabilization

### Fixed
- quick-start.sh secret key names alignment with actual environment variables
- Postgres hostname in database URL configuration
- AppProject Helm repository URL to match app-template repository location
- Removed root app dependency to make AppProject independent and self-managed

### Added
- Outline namespace whitelisting in AppProject
- App-template chart repository support
- External Secrets Operator whitelisting for managed secret provisioning
- Outline secrets setup documentation in quick-start.sh

### Changed
- AppProject now self-managed with 10s sync interval for faster feedback
- Simplified AppProject architecture by removing circular dependency

## [v1.0.0] - 2026-02-20 - Phase 1 Complete: Baseline Cluster

### Added
- GitHub token authentication for ArgoCD (reads from `~/.secrets/github/token`)
- `argocd-repo-creds` secret auto-creation in quick-start.sh with proper labeling
- Fast ArgoCD reconciliation: 10s polling interval (360 req/hr, safe with authenticated GitHub access)

### Changed
- Reconciliation timeout: 3min → 10s (requires authenticated GitHub access)
- quick-start.sh now idempotent: deletes + recreates repo-creds secret, labels guaranteed

### Fixed
- ArgoCD repo credential secret labeling: now uses delete+create instead of apply+label for atomicity

### Infrastructure Stability
- **Idempotent bootstrap**: quick-start.sh can safely re-run on existing clusters
- **All services self-healing**: ArgoCD auto-sync enabled with prune + self-heal
- **Resource-optimized**: Cluster utilization ~35% (1.4GB used of 4GB available)
- **Custom dashboards**: Replaced broken imported gnetId dashboards with verified, maintainable custom versions

### Phase 1 Summary
This release marks a complete, working baseline for the local Kubernetes learning cluster:
- ✅ Idempotent infrastructure (re-run quick-start.sh anytime, guaranteed consistent state)
- ✅ Fast feedback loop (10s config sync, no manual ArgoCD syncs needed)
- ✅ Production patterns (resource limits, security contexts, app-of-apps architecture)
- ✅ Monitoring + logging (Prometheus, Grafana, Loki, Promtail)
- ✅ Service discovery (Homepage dashboard with live k8s widget)
- Phase 2: Hardening, Raspberry Pi migration strategy, webhook-based syncing

## [v0.2.0] - 2026-02-16

### Added
- ArgoCD installation now codified in `manifests/argocd-install.yaml` via installer Job
- Architecture diagram in README showing cluster structure and port-forwarding
- SecurityContext to all containers (runAsNonRoot, readOnlyRootFilesystem, allowPrivilegeEscalation: false)
- emptyDir volumes for nginx /var/run and /var/cache directories

### Changed
- Simplified README to tech stack summary + setup only
- quick-start.sh now applies ArgoCD manifest instead of manual kubectl commands
- ArgoCD auth disabled for local development (no login required)
- Removed separate documentation files (GETTING_STARTED, SETUP, WORKFLOW, etc.)
- Removed docs-server pod and manifest
- Cleaned up broken Ingress resources (cluster-ingress)

### Fixed
- Standardized all labels to use `app.kubernetes.io/name` convention (Kubernetes recommended)
- Pinned nginx image tags from `latest` to `1.27.4-alpine` for reproducibility
- Removed orphaned/bare Pods from cluster (test-curl, fileserver bare pod)

### Removed
- docs-server deployment and ConfigMap
- Separate documentation files (moved to Claude Code maintenance)
- Manual Ingress resources (port-forwarding is sufficient for local dev)
- Login requirement for ArgoCD UI

## [v0.1.0] - Initial Release

### Added
- Local k3s cluster setup via Colima
- ArgoCD for GitOps deployments
- Prometheus for metrics collection
- Grafana for visualization
- Dashboard UI linking to all services
- File server using Nginx with hostPath volume
- quick-start.sh installation script

### Architecture
- k3s running in Colima with Docker
- 5 main services: ArgoCD, Grafana, Prometheus, Dashboard UI, File Server
- All exposed via port-forwarding to localhost
