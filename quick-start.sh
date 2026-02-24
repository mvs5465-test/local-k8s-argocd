#!/bin/bash
# Quick start script for local K8s + ArgoCD

set -e

echo "🚀 Local K8s + ArgoCD Quick Start"
echo "=================================="
echo ""

# Check kubectl and helm
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl not found. Install Docker Desktop or minikube first."
    exit 1
fi

if ! command -v helm &> /dev/null; then
    echo "❌ helm not found. Install helm first: brew install helm"
    exit 1
fi

echo "✅ kubectl found"
kubectl version --client
echo "✅ helm found"
helm version --short

echo ""
echo "📋 Cluster status:"
kubectl cluster-info || {
    echo "❌ No cluster running. Start Docker Desktop K8s or minikube."
    exit 1
}

echo ""
echo "🔄 Setting up ArgoCD namespace..."
kubectl create namespace argocd || true

echo ""
echo "📦 Adding ArgoCD Helm repository..."
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

echo ""
echo "📦 Installing ArgoCD via Helm..."
helm upgrade --install argocd argo/argo-cd -n argocd \
  --values manifests/config/values.yaml \
  --wait --timeout 5m

echo ""
echo "⏳ Waiting for ArgoCD to be ready (this takes ~60 seconds)..."
kubectl wait -n argocd --for=condition=ready pod -l app.kubernetes.io/name=argocd-server --timeout=300s || {
    echo "⚠️  Timeout waiting for ArgoCD. Check status with:"
    echo "   kubectl get pods -n argocd"
    exit 1
}

echo ""
echo "🔑 Configuring GitHub credentials for ArgoCD..."
GITHUB_TOKEN_FILE="$HOME/.secrets/github/token"
if [ -f "$GITHUB_TOKEN_FILE" ]; then
    GITHUB_TOKEN=$(cat "$GITHUB_TOKEN_FILE")
    kubectl delete secret argocd-repo-creds -n argocd --ignore-not-found
    kubectl create secret generic argocd-repo-creds \
      -n argocd \
      --from-literal=type=git \
      --from-literal=url=https://github.com/mvs5465 \
      --from-literal=username=mvs5465 \
      --from-literal=password="$GITHUB_TOKEN"
    kubectl label secret argocd-repo-creds -n argocd \
      argocd.argoproj.io/secret-type=repo-creds
    echo "✅ GitHub credentials configured"
else
    echo "⚠️  No token found at $GITHUB_TOKEN_FILE — skipping. ArgoCD will use unauthenticated access."
fi

echo ""
echo "🔐 Setting up GHCR image pull secret..."
GITHUB_TOKEN_FILE="$HOME/.secrets/github/token"
if [ -f "$GITHUB_TOKEN_FILE" ]; then
    GITHUB_TOKEN=$(cat "$GITHUB_TOKEN_FILE")
    kubectl create namespace ai || true
    kubectl delete secret ghcr-secret -n ai --ignore-not-found
    kubectl create secret docker-registry ghcr-secret \
      -n ai \
      --docker-server=ghcr.io \
      --docker-username=mvs5465 \
      --docker-password="$GITHUB_TOKEN" \
      --docker-email=noreply@github.com
    echo "✅ GHCR image pull secret configured"
else
    echo "⚠️  No token found at $GITHUB_TOKEN_FILE — skipping. ollama-mcp-bridge may fail to pull image."
fi

echo ""
echo "📦 Applying AppProject..."
kubectl apply -f manifests/config/appproject.yaml

echo ""
echo "🔐 Setting up Outline secrets..."
SECRETS_DIR="$HOME/.secrets/outline"
if [ ! -d "$SECRETS_DIR" ]; then
    echo "⚠️  No secrets found at $SECRETS_DIR"
    echo "   Create the directory and add these files:"
    echo "   - secret_key (64 hex characters)"
    echo "   - utils_secret (64 hex characters)"
    echo "   - postgres_password"
    echo "   - postgres_user (default: outline)"
    echo "   - postgres_db (default: outline)"
    echo ""
    echo "   Generate secret_key: openssl rand -hex 32"
    echo "   Generate utils_secret: openssl rand -hex 32"
    echo ""
    echo "⚠️  Outline will not be available until secrets are configured."
elif [ -f "$SECRETS_DIR/secret_key" ] && [ -f "$SECRETS_DIR/utils_secret" ] && [ -f "$SECRETS_DIR/postgres_password" ]; then
    echo "✅ Outline secrets directory found"
    echo ""
    echo "📦 Creating Kubernetes secret for Outline..."
    kubectl create namespace outline || true
    kubectl delete secret outline-secrets -n outline --ignore-not-found
    kubectl create secret generic outline-secrets \
      -n outline \
      --from-literal=secret-key="$(cat "$SECRETS_DIR/secret_key")" \
      --from-literal=utils-secret="$(cat "$SECRETS_DIR/utils_secret")" \
      --from-literal=postgres-password="$(cat "$SECRETS_DIR/postgres_password")" \
      --from-literal=postgres-user="$(cat "$SECRETS_DIR/postgres_user" 2>/dev/null || echo "outline")" \
      --from-literal=postgres-db="$(cat "$SECRETS_DIR/postgres_db" 2>/dev/null || echo "outline")" \
      --from-literal=database-url="postgresql://$(cat "$SECRETS_DIR/postgres_user" 2>/dev/null || echo "outline"):$(cat "$SECRETS_DIR/postgres_password")@outline-postgres:5432/$(cat "$SECRETS_DIR/postgres_db" 2>/dev/null || echo "outline")"
    echo "✅ Outline secrets created"
else
    echo "⚠️  Incomplete secrets in $SECRETS_DIR (missing required files)"
    echo "   Required: secret_key, utils_secret, postgres_password"
fi

echo ""
echo "📦 Bootstrapping AppProject and applications..."
kubectl apply -f manifests/argocd/appproject-app.yaml
kubectl apply -f manifests/argocd/app-of-apps-app.yaml

echo ""
echo "⏳ Waiting for applications to sync (this takes ~30 seconds)..."
for i in {1..60}; do
    SYNC_STATUS=$(kubectl get application app-of-apps -n argocd -o jsonpath='{.status.sync.status}' 2>/dev/null)
    if [ "$SYNC_STATUS" = "Synced" ]; then
        break
    fi
    sleep 1
done

if [ "$SYNC_STATUS" != "Synced" ]; then
    echo "⚠️  Applications didn't sync. Check status with:"
    echo "   kubectl get applications -n argocd"
    exit 1
fi

echo ""
echo "✅ Root applications synced! ArgoCD is now deploying child applications."
echo ""
echo "⏳ Child applications should be ready in about 15 seconds."
echo ""
echo "⏳ Getting ArgoCD admin password..."
echo "To get ArgoCD admin password:"
echo "  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"

echo ""
echo "🔐 Setting up port-forward..."
echo "To start port-forward (requires sudo):"
echo "  sudo kubectl port-forward -n ingress-nginx svc/nginx-ingress-ingress-nginx-controller 80:80 443:443"

echo ""
echo "📌 Next steps:"
echo ""
echo "1. Start port-forward (in a new terminal):"
echo "   sudo kubectl port-forward -n ingress-nginx svc/nginx-ingress-ingress-nginx-controller 80:80 443:443"
echo ""
echo "2. Add wildcard hostname to /etc/hosts:"
echo "   127.0.0.1 *.lan"
echo ""
echo "3. Get ArgoCD admin password:"
echo "   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
echo "   (user: admin)"
echo ""
echo "4. Open browser:"
echo "   http://homepage.lan"
echo ""
echo "All services are linked from the homepage dashboard."
echo ""
