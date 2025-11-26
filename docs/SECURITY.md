# Security Best Practices

Security considerations and recommendations for Jobzy infrastructure.

## Security Layers

```
┌─────────────────────────────────────┐
│      Network Security               │
├─────────────────────────────────────┤
│      Authentication & Authorization │
├─────────────────────────────────────┤
│      Secrets Management             │
├─────────────────────────────────────┤
│      Encryption                     │
├─────────────────────────────────────┤
│      Access Control                 │
└─────────────────────────────────────┘
```

## Network Security

### Private IPs Only for Databases

Already implemented:

```hcl
# Cloud SQL
ip_configuration {
  ipv4_enabled = false  # No public IP
  private_network = data.google_compute_network.default.id
}
```

### VPC Security

```bash
# Create custom VPC (recommended for production)
gcloud compute networks create jobzy-vpc \
  --subnet-mode=custom

# Create subnets
gcloud compute networks subnets create jobzy-subnet \
  --network=jobzy-vpc \
  --region=europe-north1 \
  --range=10.0.0.0/24

# Update terraform to use custom VPC
```

### Firewall Rules

```bash
# Allow only necessary traffic
gcloud compute firewall-rules create allow-internal \
  --network=jobzy-vpc \
  --allow=tcp,udp,icmp \
  --source-ranges=10.0.0.0/24

# Allow HTTPS from internet
gcloud compute firewall-rules create allow-https \
  --network=jobzy-vpc \
  --allow=tcp:443 \
  --source-ranges=0.0.0.0/0
```

### Network Policies

```yaml
# kubernetes/network-policies/deny-all.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-ingress
  namespace: kong-system
spec:
  podSelector: {}
  policyTypes:
  - Ingress
---
# Allow specific traffic
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-kong-ingress
  namespace: kong-system
spec:
  podSelector:
    matchLabels:
      app: kong
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector: {}
    ports:
    - protocol: TCP
      port: 8000
    - protocol: TCP
      port: 8443
```

## Authentication & Authorization

### Workload Identity

Already configured for GKE:

```hcl
workload_identity_config {
  workload_pool = "${var.project_id}.svc.id.goog"
}
```

### Service Account Best Practices

```bash
# Create dedicated service accounts
gcloud iam service-accounts create kong-sa \
  --display-name="Kong Service Account"

# Grant minimum permissions
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:kong-sa@PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/cloudsql.client"

# Bind to Kubernetes service account
kubectl annotate serviceaccount kong \
  -n kong-system \
  iam.gke.io/gcp-service-account=kong-sa@PROJECT_ID.iam.gserviceaccount.com
```

### RBAC (Role-Based Access Control)

```yaml
# kubernetes/rbac/kong-role.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: kong-system
  name: kong-role
rules:
- apiGroups: [""]
  resources: ["secrets", "configmaps"]
  verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: kong-rolebinding
  namespace: kong-system
subjects:
- kind: ServiceAccount
  name: kong
  namespace: kong-system
roleRef:
  kind: Role
  name: kong-role
  apiGroup: rbac.authorization.k8s.io
```

## Secrets Management

### Use Google Secret Manager

```bash
# Create secret
echo -n "SuperSecretPassword" | gcloud secrets create keycloak-admin-password \
  --data-file=- \
  --replication-policy="automatic"

# Grant access
gcloud secrets add-iam-policy-binding keycloak-admin-password \
  --member="serviceAccount:keycloak-sa@PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"
```

### Kubernetes Secrets Best Practices

```bash
# Never commit secrets to git
# Use sealed secrets or external secrets operator

# Install sealed secrets
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/controller.yaml

# Seal a secret
kubeseal --format=yaml < secret.yaml > sealed-secret.yaml
```

### Rotate Secrets Regularly

```bash
# Rotate database passwords
gcloud sql users set-password kong \
  --instance=jobzy-prod-postgres \
  --password=$(openssl rand -base64 32)

# Update Kubernetes secret
kubectl create secret generic kong-postgres-secret \
  -n kong-system \
  --from-literal=password=$(openssl rand -base64 32) \
  --dry-run=client -o yaml | kubectl apply -f -

# Restart pods to pick up new secret
kubectl rollout restart deployment/kong -n kong-system
```

## Encryption

### Encryption at Rest

All GCP services use encryption at rest by default:

- GKE persistent disks
- Cloud SQL databases
- Redis instances
- GCS buckets

For additional security, use Customer-Managed Encryption Keys (CMEK):

```bash
# Create key ring
gcloud kms keyrings create jobzy-keyring \
  --location=europe-north1

# Create key
gcloud kms keys create jobzy-key \
  --location=europe-north1 \
  --keyring=jobzy-keyring \
  --purpose=encryption

# Use in Cloud SQL
gcloud sql instances patch jobzy-prod-postgres \
  --disk-encryption-key=projects/PROJECT_ID/locations/europe-north1/keyRings/jobzy-keyring/cryptoKeys/jobzy-key
```

### Encryption in Transit

#### Enable SSL for Cloud SQL

Already configured:

```hcl
ip_configuration {
  require_ssl = true
}
```

#### TLS for Kong

```yaml
# Configure TLS certificate
apiVersion: v1
kind: Secret
metadata:
  name: kong-tls
  namespace: kong-system
type: kubernetes.io/tls
data:
  tls.crt: <base64-encoded-cert>
  tls.key: <base64-encoded-key>
---
# Update Kong service
spec:
  tls:
  - secretName: kong-tls
```

#### TLS for Keycloak

```yaml
# Update Keycloak deployment
env:
- name: KC_HTTPS_CERTIFICATE_FILE
  value: /etc/x509/https/tls.crt
- name: KC_HTTPS_CERTIFICATE_KEY_FILE
  value: /etc/x509/https/tls.key
```

## Access Control

### GCP IAM Policies

Principle of Least Privilege:

```bash
# Developer access (read-only)
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="user:developer@jobzy.fi" \
  --role="roles/viewer"

# DevOps access (full access to specific resources)
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="user:devops@jobzy.fi" \
  --role="roles/container.admin"

# Admin access (owner)
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="user:admin@jobzy.fi" \
  --role="roles/owner"
```

### GKE Authentication

```bash
# Use Google OAuth for kubectl
gcloud container clusters get-credentials jobzy-production \
  --region=europe-north1

# Or create dedicated kubeconfig for CI/CD
gcloud container clusters get-credentials jobzy-production \
  --region=europe-north1 \
  --internal-ip
```

### Audit Logging

Enable audit logs:

```bash
# Enable admin activity logs (free)
# Enable data access logs (paid)
gcloud projects set-iam-policy PROJECT_ID policy.yaml
```

policy.yaml:
```yaml
auditConfigs:
- auditLogConfigs:
  - logType: ADMIN_READ
  - logType: DATA_WRITE
  - logType: DATA_READ
  service: allServices
```

## Container Security

### Scan Images for Vulnerabilities

```bash
# Enable Container Scanning
gcloud services enable containerscanning.googleapis.com

# Scan image
gcloud container images scan IMAGE_URL

# View vulnerabilities
gcloud container images describe IMAGE_URL \
  --show-package-vulnerability
```

### Use Minimal Base Images

```dockerfile
# Use distroless images
FROM gcr.io/distroless/base-debian11

# Or alpine
FROM alpine:3.18
```

### Pod Security Standards

```yaml
# Apply restricted pod security standard
apiVersion: v1
kind: Namespace
metadata:
  name: kong-system
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
```

### Security Context

```yaml
# Run containers as non-root
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 1000
  containers:
  - name: kong
    securityContext:
      allowPrivilegeEscalation: false
      capabilities:
        drop:
        - ALL
      readOnlyRootFilesystem: true
```

## Compliance

### Enable Binary Authorization

```bash
# Create attestor
gcloud container binauthz attestors create prod-attestor \
  --project=PROJECT_ID

# Create policy
gcloud container binauthz policy import policy.yaml
```

### Regular Security Audits

Monthly checklist:

- [ ] Review IAM permissions
- [ ] Rotate credentials
- [ ] Update dependencies
- [ ] Scan for vulnerabilities
- [ ] Review audit logs
- [ ] Check for exposed secrets
- [ ] Update security patches
- [ ] Review network policies

## Incident Response

### Security Incident Plan

1. **Detect**: Monitor logs and alerts
2. **Contain**: Isolate affected resources
3. **Eradicate**: Remove threat
4. **Recover**: Restore services
5. **Learn**: Post-incident review

### Break-Glass Procedures

```bash
# Emergency access to cluster
gcloud container clusters get-credentials CLUSTER \
  --region REGION

# Revoke access immediately after
gcloud container clusters update CLUSTER \
  --no-enable-basic-auth \
  --no-issue-client-certificate
```

## Security Monitoring

### Enable Security Command Center

```bash
gcloud services enable securitycenter.googleapis.com

# View findings
gcloud scc findings list ORGANIZATION_ID
```

### Set Up Alerts

```yaml
# Alerting policy for suspicious activity
displayName: "Suspicious kubectl activity"
conditions:
- displayName: "kubectl exec commands"
  conditionThreshold:
    filter: 'resource.type="k8s_cluster" AND protoPayload.methodName="io.k8s.core.v1.pods.exec"'
    comparison: COMPARISON_GT
    thresholdValue: 10
    duration: 60s
```

## Security Checklist

### Pre-Production

- [ ] All secrets stored in Secret Manager
- [ ] No hardcoded credentials
- [ ] SSL/TLS enabled everywhere
- [ ] Private IPs for databases
- [ ] Workload Identity configured
- [ ] RBAC policies defined
- [ ] Network policies applied
- [ ] Container images scanned
- [ ] Audit logging enabled

### Production

- [ ] Binary Authorization enabled
- [ ] Regular security scans scheduled
- [ ] Monitoring and alerting configured
- [ ] Incident response plan documented
- [ ] Backup and recovery tested
- [ ] Compliance requirements met
- [ ] Security training completed

## References

- [GCP Security Best Practices](https://cloud.google.com/security/best-practices)
- [GKE Security Hardening](https://cloud.google.com/kubernetes-engine/docs/how-to/hardening-your-cluster)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [CIS Benchmarks](https://www.cisecurity.org/cis-benchmarks/)
