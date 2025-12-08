k8s-resources/
└── manifests/
    ├── 00-namespace.yaml                    # vote-app namespace
    │
    ├── 01-base-config/
    │   ├── serviceaccounts.yaml             # Workload Identity SAs (vote, worker, result)
    │   ├── configmap-voteapp.yaml           # Redis IP, Cloud SQL connection details
    │   ├── secret-voteapp.yaml              # DB password (or use Secret Manager)
    │   ├── allow-dns.yaml                   # Network policy (keep)
    │   └── default-deny-all-traffic.yaml    # Network policy (keep)
    │
    ├── 02-vote/
    │   ├── deployment.yaml                  # NO sidecar (connects to Redis directly via IP)
    │   ├── service.yaml                     # LoadBalancer or keep as-is
    │   ├── hpa.yaml                         # Keep autoscaling
    │   ├── allow-ingress-to-vote.yaml       # Network policy
    │   └── vote-egress-redis.yaml           # Network policy (allow Redis IP)
    │
    ├── 03-worker/
    │   ├── deployment.yaml                  # WITH Cloud SQL Proxy sidecar
    │   ├── vpa.yaml                         # Keep VPA
    │   └── worker-egress.yaml               # Network policy (allow Cloud SQL + Redis)
    │
    └── 04-result/
        ├── deployment.yaml                  # WITH Cloud SQL Proxy sidecar
        ├── service.yaml                     # LoadBalancer or NodePort
        ├── hpa.yaml                         # Keep autoscaling
        ├── allow-ingress-to-result.yaml     # Network policy
        └── result-egress-cloudsql.yaml      # Network policy (allow Private Service Access)
