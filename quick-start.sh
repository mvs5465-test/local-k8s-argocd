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
echo "🔐 Setting up master GHCR secret for ESO..."
GITHUB_TOKEN_FILE="$HOME/.secrets/github/token"
if [ -f "$GITHUB_TOKEN_FILE" ]; then
    GITHUB_TOKEN=$(cat "$GITHUB_TOKEN_FILE")
    kubectl create namespace external-secrets --dry-run=client -o yaml | kubectl apply -f -
    kubectl delete secret ghcr-master-secret -n external-secrets --ignore-not-found
    kubectl create secret generic ghcr-master-secret \
      -n external-secrets \
      --from-literal=token="$GITHUB_TOKEN"
    echo "✅ Master GHCR secret created. ESO will sync ghcr-secret to all namespaces."
else
    echo "⚠️  No token found at $GITHUB_TOKEN_FILE — skipping ghcr-master-secret."
fi

echo ""
echo "🔐 Setting up master GitHub PR notifier secret for ESO..."
NOTIFIER_GH_PRIVATE_KEY_FILE="$HOME/.secrets/github-pr-slack-notifier/github_private_key.pem"
NOTIFIER_SLACK_TOKEN_FILE="$HOME/.secrets/github-pr-slack-notifier/slack_bot_token"
if [ -f "$NOTIFIER_GH_PRIVATE_KEY_FILE" ] && [ -f "$NOTIFIER_SLACK_TOKEN_FILE" ]; then
    NOTIFIER_GH_PRIVATE_KEY=$(cat "$NOTIFIER_GH_PRIVATE_KEY_FILE")
    NOTIFIER_SLACK_TOKEN=$(cat "$NOTIFIER_SLACK_TOKEN_FILE")
    kubectl create namespace external-secrets --dry-run=client -o yaml | kubectl apply -f -
    kubectl delete secret github-pr-slack-notifier-master-secret -n external-secrets --ignore-not-found
    kubectl create secret generic github-pr-slack-notifier-master-secret \
      -n external-secrets \
      --from-literal=github_app_private_key="$NOTIFIER_GH_PRIVATE_KEY" \
      --from-literal=slack_bot_token="$NOTIFIER_SLACK_TOKEN"
    echo "✅ Master notifier secret created. ESO will sync github-pr-slack-notifier-secret to github-pr-slack-notifier namespace."
else
    echo "⚠️  Missing notifier files — skipping github-pr-slack-notifier-master-secret."
    echo "   Expected files:"
    echo "   - $NOTIFIER_GH_PRIVATE_KEY_FILE"
    echo "   - $NOTIFIER_SLACK_TOKEN_FILE"
fi

echo ""
echo "📦 Applying root ArgoCD Applications..."
kubectl apply -f manifests/argocd/

echo ""
echo "⏳ Waiting for bootstrap ApplicationSet to render applications..."
for i in {1..60}; do
    APPSET_READY=$(kubectl get applicationset cluster-apps -n argocd -o jsonpath='{.status.conditions[?(@.type=="ParametersGenerated")].status}' 2>/dev/null)
    if [ "$APPSET_READY" = "True" ]; then
        break
    fi
    sleep 1
done

if [ "$APPSET_READY" != "True" ]; then
    echo "⚠️  Bootstrap ApplicationSet did not finish rendering. Check status with:"
    echo "   kubectl get applicationset cluster-apps -n argocd -o yaml"
    exit 1
fi

echo ""
echo "✅ ApplicationSet rendered. ArgoCD is now reconciling generated applications."
echo ""
echo "⏳ Generated applications should be ready in about 15 seconds."
echo ""
echo "📌 Access:"
echo ""
echo "1. Start port-forward:"
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
echo "   http://home.lan"
echo ""
echo "Cluster Home is the primary dashboard for the cluster."
echo ""
