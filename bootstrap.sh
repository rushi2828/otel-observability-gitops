#!/bin/bash
set -e

# Constants
CLUSTER_NAME="otel-gitops"
ARGOCD_NAMESPACE="argocd"
ARGOCD_HELM_CHART_PATH="charts/argocd"
ARGOCD_VERSION="v2.11.3"
RELEASE_NAME="argocd"

echo "🔍 Checking if Kind cluster '${CLUSTER_NAME}' exists..."
if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
    echo "✅ Kind cluster '${CLUSTER_NAME}' already exists. Skipping creation."
else
    echo "🚀 Creating Kind cluster '${CLUSTER_NAME}'..."
    kind create cluster --name "${CLUSTER_NAME}" --config kind-config/kind-config.yaml
    echo "✅ Kind cluster created."

    echo "⏳ Waiting for nodes to be ready..."
    kubectl wait --for=condition=Ready nodes --all --timeout=120s

    echo "🔍 Cluster Info:"
    kubectl cluster-info --context kind-${CLUSTER_NAME}
    kubectl get nodes
fi

# Install Helm if not present
if ! command -v helm &> /dev/null; then
    echo "📦 Helm not found. Installing Helm..."
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
else
    echo "✅ Helm is already installed."
fi

# # Build Helm dependencies
# if [ ! -d "${ARGOCD_HELM_CHART_PATH}/charts" ] || [ -z "$(ls -A ${ARGOCD_HELM_CHART_PATH}/charts 2>/dev/null)" ]; then
#     echo "📦 Building Helm dependencies for ArgoCD chart..."
#     helm dependency build "${ARGOCD_HELM_CHART_PATH}"
# else
#     echo "✅ Helm dependencies already present."
# fi

# Create namespace if not exists
if kubectl get namespace "${ARGOCD_NAMESPACE}" &> /dev/null; then
    echo "✅ Namespace '${ARGOCD_NAMESPACE}' already exists."
else
    echo "🚀 Creating namespace '${ARGOCD_NAMESPACE}'..."
    kubectl create namespace "${ARGOCD_NAMESPACE}"
fi

# # Delete old CRDs to avoid Helm conflict
# echo "🧹 Deleting existing ArgoCD CRDs (if any)..."
# for crd in $(kubectl get crd -o name | grep 'argoproj.io'); do
#   kubectl delete "$crd" || true
# done

# # Wait a moment for CRDs to fully delete
# sleep 5

# # Install ArgoCD CRDs
# echo "📥 Installing ArgoCD CRDs (${ARGOCD_VERSION})..."
# kubectl -n "${ARGOCD_NAMESPACE}" apply -k https://github.com/argoproj/argo-cd/manifests/crds\?ref\=stable

# Wait for CRDs to be established
kubectl wait --for=condition=Established --timeout=60s crd/applications.argoproj.io

# 🔧 Patch ArgoCD CRDs with Helm metadata to avoid upgrade/delete issues
echo "🔧 Patching ArgoCD CRDs with Helm metadata..."
for crd in $(kubectl get crd -o name | grep 'argoproj.io'); do
  CRD_NAME=${crd#*/}  # Strip prefix
  echo "🛠️  Patching $CRD_NAME..."
  kubectl patch crd "$CRD_NAME" --type=merge -p "
metadata:
  labels:
    app.kubernetes.io/managed-by: Helm
  annotations:
    meta.helm.sh/release-name: ${RELEASE_NAME}
    meta.helm.sh/release-namespace: ${ARGOCD_NAMESPACE}
" && echo "✅ Patched $CRD_NAME" || echo "⚠️  Failed to patch $CRD_NAME"
done

# Install ArgoCD via Helm (skip CRDs in chart)
if helm ls -n "${ARGOCD_NAMESPACE}" | grep -q "^${RELEASE_NAME}"; then
    echo "✅ ArgoCD Helm release '${RELEASE_NAME}' already exists."
else
    echo "📥 Installing ArgoCD Helm chart..."
    helm install "${RELEASE_NAME}" "${ARGOCD_HELM_CHART_PATH}" -n "${ARGOCD_NAMESPACE}" \
        --skip-crds
    echo "✅ ArgoCD installation complete."
fi

# Optional: Show admin password and port-forward
echo "⏳ Waiting for all ArgoCD pods to be in 'Running' status..."
while true; do
    not_running=$(kubectl get pods -n "${ARGOCD_NAMESPACE}" --no-headers | grep -v 'Running' | wc -l)
    total=$(kubectl get pods -n "${ARGOCD_NAMESPACE}" --no-headers | wc -l)
    if [ "$total" -gt 0 ] && [ "$not_running" -eq 0 ]; then
        echo "✅ All ArgoCD pods are running."
        break
    else
        echo "⏳ Waiting... ($((total-not_running))/$total running)"
        sleep 5
    fi
done


echo "🔐 Argo CD admin password:"
kubectl -n "${ARGOCD_NAMESPACE}" get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo
sleep 5

# Apply our bootstrap app-of-apps
kubectl -n argocd apply -f bootstrap/app-of-apps.yaml


echo "🌐 Port forwarding ArgoCD server to https://localhost:8090"
kubectl port-forward svc/argocd-server -n "${ARGOCD_NAMESPACE}" 8090:443


