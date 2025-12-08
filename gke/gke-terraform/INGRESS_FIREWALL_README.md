# GCE Load Balancer Firewall Rule for Ingress

## What Was Added

Added a firewall rule to `modules/network/main.tf` that allows GCE Load Balancer traffic to reach your GKE cluster.

### Resource: `google_compute_firewall.allow_gce_lb`

**Purpose**: Enable GKE Ingress to work by allowing:
- Health check traffic
- HTTP/HTTPS proxy traffic

**Source IP Ranges**:
- `130.211.0.0/22` - Legacy health check range
- `35.191.0.0/16` - Current health check and proxy range

These are Google Cloud's official IP ranges for load balancer operations.

## How to Apply

When you recreate your lab environment:

```bash
cd gke-terraform

# Plan to see the change
terraform plan

# Apply the firewall rule
terraform apply
```

This will create the firewall rule automatically as part of your infrastructure.

## Why This Is Needed

Without this firewall rule:
- GKE Ingress resources are created ✅
- Load Balancer gets an IP address ✅
- Health checks may pass ✅
- **BUT actual user traffic fails with "Empty reply from server"** ❌

The firewall rule allows the Load Balancer's proxy layer to forward HTTP/HTTPS traffic to your GKE pods.

## Verification

After applying, verify the rule exists:

```bash
gcloud compute firewall-rules describe allow-gce-health-checks \
  --format="table(name,network,allowed[].map().firewall_rule().list().join(),sourceRanges.list())"
```

## Alternative: Target Specific GKE Nodes

If you want to restrict the rule to only GKE nodes (more secure), you can add target tags:

```hcl
resource "google_compute_firewall" "allow_gce_lb" {
  name    = "allow-gce-health-checks"
  network = google_compute_network.vpc.name
  project = var.project_id

  description = "Allow GCE Load Balancer health checks and proxy traffic for Ingress"

  allow {
    protocol = "tcp"
  }

  source_ranges = [
    "130.211.0.0/22",
    "35.191.0.0/16"
  ]

  # Only apply to GKE nodes
  target_tags = ["gke-${var.network_name}"]  # Adjust based on your GKE node tags
}
```

The current configuration applies to all instances in the VPC for simplicity.
