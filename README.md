# 🔭 OpenTelemetry Demo - GitOps on KIND with ArgoCD, Helm, and Ingress

This repository deploys the [OpenTelemetry Demo](https://github.com/open-telemetry/opentelemetry-demo) using:

- ✅ **GitOps** with ArgoCD (App of Apps pattern)
- 🧭 **Helm** charts for modular, repeatable deployments
- 🐳 **KIND** (Kubernetes in Docker) for local clusters
- 🌐 **NGINX Ingress** with TLS for realistic service routing
- 📦 Pre-configured routes for all major OpenTelemetry microservices

Perfect for local development, observability workshops, and testing OpenTelemetry end-to-end.

---

## 🚀 Features

- KIND cluster with production-like networking
- ArgoCD auto-sync with Helm-based apps
- TLS support using self-signed certs or cert-manager
- Realistic microservice routing for services like:
  - `/frontend`, `/cart`, `/checkout`, `/product`, etc.
- One-click bootstrap with `bootstrap.sh`

