# 🔭 OpenTelemetry Demo - GitOps on KIND with ArgoCD, Helm, and Ingress

This repository deploys the [OpenTelemetry Demo](https://github.com/open-telemetry/opentelemetry-demo) using:

* ✅ **GitOps** with ArgoCD (App of Apps pattern)
* 🤭 **Helm** charts for modular, repeatable deployments
* 🐳 **KIND** (Kubernetes in Docker) for local clusters
* 🌐 **NGINX Ingress** with TLS for realistic service routing
* 📦 Pre-configured routes for all major OpenTelemetry microservices

Perfect for local development, observability workshops, and testing OpenTelemetry end-to-end.

---

## 🚀 Features

* KIND cluster with production-like networking
* ArgoCD auto-sync with Helm-based apps
* TLS support using self-signed certs or cert-manager
* Realistic microservice routing for services like:

  * `/frontend`, `/cart`, `/checkout`, `/product`, etc.
* One-click bootstrap with `bootstrap.sh`

---

## 📚 Project Structure

```
otel-observability-gitops/
├── bootstrap/
│   └── app-of-apps.yaml
├── apps/
│   ├── argocd/
│   │   └── app.yaml
│   ├── ingress-nginx/
│   │   └── app.yaml
│   ├── otel-demo/
│   │   ├── app.yaml
│   │   └── values.yaml
│   └── tls/
│       └── app.yaml       
├── values/
│   └── nginx-values.yaml
├── kind-cluster.yaml
├── bootstrap.sh
└── README.md
```

---

## 🤝 Prerequisites

* Docker
* kubectl
* KIND
* Helm
* (optional) ArgoCD CLI

---

## 🚧 Setup Instructions

### 1. Create Cluster and Bootstrap

```bash
./bootstrap.sh
```

This script will:

* Create a KIND cluster with ports mapped to 80/443
* Install ArgoCD via manifests
* Apply the App of Apps pointing to all Helm-managed apps

### 2. Add Local DNS Entry

```bash
sudo echo "127.0.0.1 otel-demo.local" >> /etc/hosts
```

### 3. Access ArgoCD UI

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:80
```

Visit: [http://localhost:8080](http://localhost:8080)

Get the admin password:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo
```

---

## 👀 Test Ingress Routes

Once deployed, you can test the exposed services:

```bash
curl -k https://otel-demo.local/frontend
curl -k https://otel-demo.local/cart
curl -k https://otel-demo.local/checkout
```

---

## 🔐 TLS Support

You can use:

* Self-signed TLS cert (already supported by `bootstrap.sh`)
* Or optionally enable `apps/tls/app.yaml` for cert-manager

---

## ✨ Customization

* Modify service paths in `apps/otel-demo/values.yaml`
* Override NGINX config in `values/nginx-values.yaml`
* Add more ArgoCD apps in the `apps/` folder

---

## 🚤 Credits

* [OpenTelemetry Demo](https://github.com/open-telemetry/opentelemetry-demo)
* [ArgoCD](https://argo-cd.readthedocs.io)
* [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/)

---
