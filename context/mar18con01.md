# Helm Chart Lifecycle Automation - Internal Platform Flow

## 🎯 Objective
Automate the full lifecycle of mirroring public Helm charts, customizing them, securely packaging them, and deploying via Harness to EKS—while preserving upstream chart purity and managing internal customizations.

---

## 🏗️ Solution Architecture Overview

### Repositories

| Repo Name                    | Purpose                                                     |
|------------------------------|-------------------------------------------------------------|
| `helm-upstreams`             | Read-only mirror of public Helm charts (for reference only) |
| `helm-overlays`              | Internal repo containing copied Helm charts + customizations |

### Public Registry → Internal Registry Flow

| Source                                      | Target                                     |
|---------------------------------------------|--------------------------------------------|
| Public Helm repos (e.g., Jetstack, Bitnami) | `helm-upstreams` repo                      |
| `helm-upstreams/<chart>`                    | `helm-overlays/<chart>`                    |
| `helm-overlays/<chart>`                     | JFrog Artifactory Helm repo (packaged `.tgz`) |
| JFrog Artifactory Helm repo                 | Harness pipeline for EKS deployment        |

---

## 🛠️ Pipelines Overview

### 🔹 Pipeline 1: Upstream Mirror Pipeline

**Purpose:**  
Mirror upstream Helm charts into `helm-upstreams`.

**Trigger:**  
Manual or automated (e.g., scheduled sync).

---

### 🔹 Pipeline 2: Upstream → Overlays Sync Pipeline

**Purpose:**  
Sync upstream chart into `helm-overlays` while preserving:
- `values-*.yaml` (custom values)
- `custom-templates/` or overlays
- CI/CD configs

**Sync mechanism:**  
- `rsync` (preferred)
- or `git subtree merge`

**Output:**  
PR into `helm-overlays` repo with upstream updates.

---

### 🔹 Pipeline 3: Jenkins Packaging Pipeline

**Purpose:**  
Package customized Helm charts from `helm-overlays` and push them to JFrog Artifactory.

**Steps:**
- Helm lint (optional)
- Checkmarx One scan (IaC security)
- Helm dependency update + package
- Push `.tgz` to JFrog with semver + environment tag (e.g., `1.13.2-prod`)
- Update `index.yaml` in Artifactory Helm repo

---

### 🔹 Harness Deployment Pipeline

**Purpose:**  
Deploy Helm charts from JFrog into the private EKS cluster.

---

## 🧩 Key Technical Decisions

- Two repo strategy (`helm-upstreams` + `helm-overlays`).
- Automate partial sync from `helm-upstreams` → `helm-overlays`.
- Jenkins packaging pipeline works **only from `helm-overlays` repo**.
- Unified security scanning via **Checkmarx One** CLI.
- Semantic versioning and tagging (e.g., `1.13.2-stage`, `1.13.2-prod`) for Helm artifacts in JFrog.

---

## 💡 Optional Future Improvements

- Helm umbrella chart to bundle cert-manager + ingress-nginx + keycloak.
- Chart promotion pipeline (dev → staging → prod) inside JFrog.
- Slack/MS Teams notifications for Jenkins pipelines.
- Dry-run + diff reports on upstream sync pipeline.

---

## 🚦 Next Actionable Steps

1. ✅ Implement **Pipeline 1** (mirror public Helm charts to `helm-upstreams`).
2. ✅ Implement **Pipeline 2** (sync `helm-upstreams` → `helm-overlays`).
3. ✅ Implement **Pipeline 3** (package & push Helm charts to JFrog).
4. ✅ Configure Harness pipeline to deploy Helm charts from Artifactory.
5. 🟢 Rollout the flow to EKS using Harness.
6. 🟢 Optional: Implement promotion pipelines, umbrella charts, notifications.

---

> _Maintainer Note: Please update this README as new automation or architectural changes are introduced._
