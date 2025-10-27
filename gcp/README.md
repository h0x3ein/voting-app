```
gcp/
├── secretmanager/
│   ├── create-secrets.sh                 # gcloud commands to create/update secrets
│   ├── gcp-secret-store.yaml             # SecretStore definition for External Secrets Operator (ESO)
│   ├── service-account/
│   │   ├── create-sa.sh                  # script to create ESO Service Account
│   │   └── key.json                      # (⚠️ gitignore this!) ESO service account key
│   ├── README.md                         # explains how to create secrets and IAM permissions
│
├── mysql/
│   ├── mysql-external-secret.yaml        # maps db-password from Secret Manager to Kubernetes Secret
│   ├── cloudsql-proxy-deployment.yaml    # Cloud SQL proxy connection config
│   ├── cloudsql-service.yaml             # internal K8s service for apps to reach MySQL
│   ├── setup-mysql.md                    # how to connect Cloud SQL to GKE
│
├── redis/
│   ├── redis-external-secret.yaml        # optional — if Redis password is stored in Secret Manager
│   ├── memorystore-service.yaml          # internal K8s service representing Memorystore instance
│   ├── setup-redis.md                    # how to connect Memorystore to GKE
│
└── README.md                             # overview of all GCP resources (Secret Manager, MySQL, Redis)
```