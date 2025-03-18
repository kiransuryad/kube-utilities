Summary: Helm Chart Lifecycle Automation

🌐 Objective:

Automate the full lifecycle of mirroring public Helm charts, customizing them, securely packaging them, and deploying via Harness to EKS—while preserving upstream chart purity and managing internal customizations in a clean, scalable way.

🎯 Solution Architecture Overview

Repositories:
helm-upstreams (Bitbucket Repo #1)
Read-only mirror of official/public Helm charts.
Used purely for reference and periodic updates.
helm-overlays (Bitbucket Repo #2)
Contains:
Copied upstream chart (from helm-upstreams).
Internal customizations:
values-prod.yaml, values-stage.yaml, etc.
Custom templates/ overrides (if needed).
Optional overlays (e.g., Kustomize patches or Helm hooks).
Public Registry → Internal Registry Flow:
Source	Target
Public Helm repos (Jetstack, Bitnami, etc.)	helm-upstreams (Repo #1)
helm-upstreams/<chart>	helm-overlays/<chart> (Repo #2)
helm-overlays/<chart>	JFrog Artifactory Helm repository (packaged .tgz)
JFrog Artifactory Helm repo	Harness pipeline for EKS deployments
🛠️ Pipelines Overview

🔹 Pipeline 1: Upstream Mirror Pipeline
Purpose:
Mirror or sync upstream Helm chart into helm-upstreams.
Trigger:
Manual or scheduled sync (e.g., weekly).
🔹 Pipeline 2: Upstream → Overlays Sync Pipeline
Purpose:
Sync helm-upstreams/<chart> → helm-overlays/<chart> while preserving:
Custom values-*.yaml
Custom templates or overlays
Any custom CI/CD configurations
Sync mechanism:
rsync or Git subtree merge (you chose rsync for now).
Output:
A PR in helm-overlays repo updating upstream Helm chart content, leaving custom files intact.
🔹 Pipeline 3: Jenkins Packaging Pipeline
Purpose:
Package the customized Helm chart from helm-overlays and push it to JFrog Artifactory with semver + environment tagging.
Steps:
Helm lint (optional)
Checkmarx One scan (for IaC misconfigs)
Helm dependency update + packaging
Push to JFrog Artifactory (via Helm CLI or curl)
Update index.yaml
🔹 Harness Deployment Pipeline
Purpose:
Deploy charts from JFrog Helm repo into private EKS cluster.
Steps:
Standard Harness Helm deployment pipeline consuming the Helm artifact.
🧩 Key Technical Decisions:

Split upstream Helm charts and internal customizations into 2 repos.
Automate partial chart syncing from upstream → overlays repo.
Centralize artifact packaging from the overlays repo only.
Unified security scanning via Checkmarx One in Jenkins Pipeline 3.
Follow semantic versioning + env tags (e.g., 1.13.2-prod) in JFrog Artifactory.
💡 Optional Future Improvements:

Helm umbrella chart in helm-overlays for bundling cert-manager + ingress-nginx + keycloak.
Automated chart promotion pipeline (dev → stage → prod) inside JFrog.
Slack/MS Teams notifications for sync/packaging/deployment pipelines.
Automatic dry-run + diff reporting as part of sync pipeline.
Next Actionable Steps (Suggested Order):

✅ Implement Pipeline 1 to mirror upstream charts into helm-upstreams.
✅ Implement Pipeline 2 for rsync-based sync from helm-upstreams → helm-overlays.
✅ Implement Pipeline 3 for packaging + JFrog push + Checkmarx One scan.
✅ Configure Harness to consume JFrog chart artifacts.
🟢 Rollout into EKS (via Harness pipeline).
🟢 Optional: add promotion pipelines, notifications, umbrella charts.
