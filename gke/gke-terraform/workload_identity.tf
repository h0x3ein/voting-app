# =============================================================================
# Workload Identity Bindings
# =============================================================================
# This file manages Workload Identity bindings between Google Service Accounts (GSA)
# and Kubernetes Service Accounts (KSA).
#
# Why separate file?
# - Workload Identity pool is created when GKE cluster is provisioned
# - Bindings must be created AFTER the cluster exists
# - This avoids circular dependencies in the project module
# =============================================================================

resource "google_service_account_iam_member" "cloud_sql_workload_identity" {
  service_account_id = module.project.cloud_sql_sa_name # Uses full resource name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[${var.ksa_namespace}/${var.ksa_name}]"

  # Critical: Must wait for GKE cluster to create the workload identity pool
  depends_on = [module.gke]
}
