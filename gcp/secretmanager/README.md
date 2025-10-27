# 🔐 Using Google Secret Manager with External Secrets Operator in Kubernetes

This guide explains how to sync secrets from **Google Secret Manager (GSM)** into a **Kubernetes cluster** using the **External Secrets Operator (ESO)**.

It works on any cluster — **Kind**, **Minikube**, **GKE**, etc.

---

## 🧰 Prerequisites

* Google Cloud SDK (`gcloud`) installed and authenticated
* A Google Cloud project
* `kubectl` and `helm` installed
* Access to your Kubernetes cluster

---

## 🧩 Define Your Project ID

Before running any commands, define your project ID as an environment variable:

```bash
export PROJECT_ID=<your-gcp-project-id>
```

Verify it:

```bash
echo $PROJECT_ID
```

This ensures you can reuse it across all following commands.

---

## 1️⃣ Authenticate and configure project

```bash
gcloud auth login
gcloud config set project $PROJECT_ID
```

---

## 2️⃣ Enable Secret Manager API

```bash
gcloud services enable secretmanager.googleapis.com
```

---

## 3️⃣ Create secrets in Google Secret Manager

Now we’ll create the same secrets you have locally in Kubernetes.

```bash
# Make sure you have your project set
gcloud config set project $PROJECT_ID

# Create MYSQL_PASSWORD secret
echo -n "rootpass" | gcloud secrets create mysql-password \
  --replication-policy="automatic" \
  --data-file=-

# Create MYSQL_ROOT_PASSWORD secret
echo -n "rootpass" | gcloud secrets create mysql-root-password \
  --replication-policy="automatic" \
  --data-file=-

# Create MYSQL_USER secret
echo -n "voteuser" | gcloud secrets create mysql-user \
  --replication-policy="automatic" \
  --data-file=-
```

Confirm they exist:

```bash
gcloud secrets list
```

Verify one:

```bash
gcloud secrets versions access latest --secret=mysql-password
```

---

## 4️⃣ Create a Service Account for ESO

Create a service account that will be used by External Secrets Operator to access GCP Secret Manager:

```bash
gcloud iam service-accounts create eso-sa --display-name="ESO Service Account"
```

Grant it permission to read secrets:

```bash
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:eso-sa@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"
```

Generate a key file (JSON):

```bash
gcloud iam service-accounts keys create key.json \
  --iam-account=eso-sa@$PROJECT_ID.iam.gserviceaccount.com
```

---

## 5️⃣ Install External Secrets Operator

Add the Helm repository and install the chart:

```bash
helm repo add external-secrets https://charts.external-secrets.io
helm repo update

helm install external-secrets \
   external-secrets/external-secrets \
   -n external-secrets \
   --create-namespace
```

Check pods:

```bash
kubectl get pods -n external-secrets
```

Expected output:

```
external-secrets-xxxx
external-secrets-cert-controller-xxxx
external-secrets-webhook-xxxx
```

---

## 6️⃣ Add GCP service account credentials to Kubernetes

```bash
kubectl create secret generic gcp-credentials \
  --from-file=credentials.json=key.json
```

---

## 7️⃣ Create a SecretStore

Create a file called **`gcp-secret-store.yaml`**:

```yaml
apiVersion: external-secrets.io/v1
kind: SecretStore
metadata:
  name: gcp-secret-store
spec:
  provider:
    gcpsm:
      projectID: "${PROJECT_ID}"
      auth:
        secretRef:
          secretAccessKeySecretRef:
            name: gcp-credentials
            key: credentials.json
```

Apply it **using envsubst** so your `${PROJECT_ID}` gets replaced:

```bash
envsubst < gcp-secret-store.yaml | kubectl apply -f -
```

> ⚠️ **Note:** Kubernetes does **not** replace shell variables automatically in YAML.
> Always apply manifests that contain variables using `envsubst`.

Verify:

```bash
kubectl get secretstores
```

---

## 8️⃣ Create an ExternalSecret for your MySQL credentials

Create **`mysql-credentials-external-secret.yaml`**:

```yaml
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: mysql-credentials
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: gcp-secret-store
    kind: SecretStore
  target:
    name: mysql-credentials
    creationPolicy: Owner
  data:
    - secretKey: MYSQL_PASSWORD
      remoteRef:
        key: mysql-password
    - secretKey: MYSQL_ROOT_PASSWORD
      remoteRef:
        key: mysql-root-password
    - secretKey: MYSQL_USER
      remoteRef:
        key: mysql-user
```

Apply it:

```bash
kubectl apply -f mysql-credentials-external-secret.yaml
```

---

## 9️⃣ Check the synced secret in Kubernetes

```bash
kubectl get secret mysql-credentials -o yaml
```

Decode one of the values:

```bash
kubectl get secret mysql-credentials -o jsonpath="{.data.MYSQL_PASSWORD}" | base64 --decode
```

Output:

```
rootpass
```

🎉 **Success!**
Your MySQL secrets from **Google Secret Manager** are now automatically synced into **Kubernetes**.

---

## 🔄 Updating secrets

When you update a secret in Google Secret Manager (create a new version), ESO automatically re-syncs based on your defined `refreshInterval` (default: 1h).

To force an immediate sync, run:

```bash
kubectl annotate externalsecret mysql-credentials force-sync=$(date +%s) --overwrite
```

---

## ⚙️ Optional: Faster refresh for testing

For faster testing, reduce the interval to 1 minute:

```yaml
spec:
  refreshInterval: 1m
```

---

## 🧹 Cleanup

To remove all resources from both your cluster and GCP, run the cleanup script (see below) or use the commands manually:

```bash
helm uninstall external-secrets -n external-secrets
kubectl delete secret gcp-credentials
kubectl delete secretstore gcp-secret-store
kubectl delete externalsecret mysql-credentials
kubectl delete ns external-secrets
```

If you also want to remove from GCP:

```bash
gcloud secrets delete mysql-password --quiet
gcloud secrets delete mysql-root-password --quiet
gcloud secrets delete mysql-user --quiet
gcloud iam service-accounts delete eso-sa@$PROJECT_ID.iam.gserviceaccount.com --quiet
rm -f key.json
```

---

## 🧠 Notes

* `SecretStore` defines **how ESO authenticates** to Google Secret Manager.
* `ExternalSecret` defines **which secrets** to pull and **how to map** them into Kubernetes.
* ESO automatically keeps secrets updated — no manual syncing required.

---

✅ **Done!**
You now have a working pipeline from **Google Secret Manager → Kubernetes Secret**, managed by **External Secrets Operator**, with full MySQL credential sync.

---

