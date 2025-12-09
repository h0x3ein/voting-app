# TO-DO LIST: Unified Helm Chart Migration

This document outlines the process to combine all your separate microservices into a single **Unified Helm Chart** (`helm-chart-unified`). This approach simplifies management by having one `values.yaml` and one install command for the entire stack.

## Goal
Create a directory `helm-chart-unified` containing a single Chart that deploys:
1.  **Common Resources** (ConfigMap, Secret, ServiceAccount)
2.  **Vote App** (Deployment, Service, Ingress)
3.  **Result App** (Deployment, Service, Ingress)
4.  **Worker App** (Deployment)

## Phase 1: Chart Initialization
- [ ] **Step 1.1:** Create `helm-chart-unified` directory and `Chart.yaml`.
- [ ] **Step 1.2:** Create a consolidated `values.yaml` structure.
    -   Define global keys for `projectID`, `redis`, `db`.
    -   Define app-specific sections: `vote`, `result`, `worker`.

## Phase 2: Migrate Templates
*We will copy and adapt templates from the `helm-charts-separate` work, organizing them logically.*

- [ ] **Step 2.1:** **Common Templates**:
    -   Create `templates/common-configmap.yaml`
    -   Create `templates/common-secret.yaml`
    -   Create `templates/common-serviceaccount.yaml`
- [ ] **Step 2.2:** **Vote App Templates**:
    -   Create `templates/vote-deployment.yaml`
    -   Create `templates/vote-service.yaml`
    -   Create `templates/vote-ingress.yaml`
- [ ] **Step 2.3:** **Result App Templates**:
    -   Create `templates/result-deployment.yaml` (w/ Cloud SQL Sidecar logic)
    -   Create `templates/result-service.yaml`
    -   Create `templates/result-ingress.yaml`
- [ ] **Step 2.4:** **Worker App Templates**:
    -   Create `templates/worker-deployment.yaml` (w/ Cloud SQL Sidecar logic)

## Phase 3: Verification
- [ ] **Step 3.1:** Verify with `helm template`.
- [ ] **Step 3.2:** Create `install.sh` for the unified chart.
