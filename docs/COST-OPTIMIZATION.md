# Cost Optimization Guide

Strategies for managing and optimizing infrastructure costs.

## Cost Overview

### Typical Monthly Costs (Estimates)

**Development Environment:**
- GKE Cluster: $75-100/month
- Cloud SQL (db-f1-micro): $15-20/month
- Redis (BASIC, 1GB): $25-30/month
- Load Balancers: $20-25/month
- **Total: ~$135-175/month**

**Staging Environment:**
- GKE Cluster: $150-200/month
- Cloud SQL (db-custom-1-4096): $80-100/month
- Redis (BASIC, 2GB): $50-60/month
- Load Balancers: $20-25/month
- **Total: ~$300-385/month**

**Production Environment:**
- GKE Cluster: $300-400/month
- Cloud SQL (db-custom-2-8192, REGIONAL): $200-250/month
- Redis (STANDARD_HA, 5GB): $150-180/month
- Load Balancers: $20-25/month
- **Total: ~$670-855/month**

## Cost Optimization Strategies

### 1. Use Preemptible Nodes (Dev/Staging)

**Savings: 60-80%**

Preemptible nodes are already enabled for non-production environments:

```hcl
# terraform/modules/gke/main.tf
node_config {
  preemptible = var.environment != "prod"  # Already configured
}
```

**Considerations:**
- Nodes can be terminated at any time
- Workloads must be fault-tolerant
- Not suitable for production

### 2. Right-Size Resources

**Savings: 20-40%**

Monitor actual resource usage and adjust:

```bash
# Check actual usage
kubectl top nodes
kubectl top pods --all-namespaces

# If usage is consistently low, reduce in tfvars:
# terraform/environments/dev.tfvars
gke_machine_type = "n1-standard-1"  # Instead of n1-standard-2
```

### 3. Use Committed Use Discounts

**Savings: 25-55%**

For predictable production workloads:

```bash
# 1-year or 3-year commitment for VMs
gcloud compute commitments create jobzy-commitment \
  --resources=vcpu=8,memory=32GB \
  --plan=twelve-month \
  --region=europe-north1
```

### 4. Auto-Scaling

**Savings: Variable**

Already configured but verify settings:

```hcl
# terraform/environments/prod.tfvars
gke_min_nodes = 2  # Scale down when idle
gke_max_nodes = 10 # Scale up under load
```

### 5. Database Optimization

#### Use Smaller Instances for Dev/Staging

```hcl
# dev.tfvars
database_tier = "db-f1-micro"  # $15/month instead of $80/month
```

#### Use Zonal for Non-Production

```hcl
# Avoid REGIONAL for dev/staging
availability_type = "ZONAL"  # Half the cost of REGIONAL
```

#### Optimize Backups

```hcl
# Reduce backup retention for dev
backup_retention_settings {
  retained_backups = 3  # Instead of 7
}
```

### 6. Redis Optimization

#### Use BASIC Tier for Non-Production

```hcl
# dev.tfvars
tier = "BASIC"  # Half the cost of STANDARD_HA
```

#### Right-Size Memory

```bash
# Monitor actual Redis usage
kubectl exec -it deployment/kong -n kong-system -- \
  redis-cli -h $REDIS_HOST info memory

# Adjust size if overprovisioned
redis_size_gb = 1  # Start small, scale as needed
```

### 7. Reduce Pod Replicas

**For Dev Environment:**

```hcl
# terraform/environments/dev.tfvars
kong_replicas = 1
keycloak_replicas = 1
```

### 8. Clean Up Unused Resources

Regular cleanup script:

```bash
#!/bin/bash
# scripts/cleanup-unused.sh

# Delete unused disks
gcloud compute disks list --filter="users:null" --format="value(name)" | \
  xargs -I {} gcloud compute disks delete {} --quiet

# Delete unused IPs
gcloud compute addresses list --filter="users:null" --format="value(name)" | \
  xargs -I {} gcloud compute addresses delete {} --quiet

# Delete old snapshots
gcloud compute snapshots list --filter="creationTimestamp<$(date -d '30 days ago' +%Y-%m-%d)" \
  --format="value(name)" | \
  xargs -I {} gcloud compute snapshots delete {} --quiet
```

### 9. Use Spot VMs for Batch Jobs

For non-critical workloads:

```yaml
# kubernetes/batch-job.yaml
spec:
  template:
    spec:
      nodeSelector:
        cloud.google.com/gke-preemptible: "true"
```

### 10. Optimize Network Costs

- Use internal IPs for inter-service communication
- Enable VPC Native cluster
- Use Cloud CDN for static content

## Cost Monitoring

### Enable Budgets and Alerts

```bash
# Create budget alert
gcloud billing budgets create \
  --billing-account=BILLING_ACCOUNT_ID \
  --display-name="Jobzy Monthly Budget" \
  --budget-amount=1000 \
  --threshold-rule=percent=50 \
  --threshold-rule=percent=90 \
  --threshold-rule=percent=100
```

### Use Cost Breakdown Tools

```bash
# Export billing data to BigQuery
gcloud billing accounts get-billing-info

# View cost breakdown in console
# Navigation: Billing > Reports
```

### Regular Cost Reviews

Create a monthly review checklist:

- [ ] Check actual vs. budgeted costs
- [ ] Review top 10 cost items
- [ ] Identify unused resources
- [ ] Check for cost anomalies
- [ ] Review resource utilization
- [ ] Update resource sizing

## Development Environment Optimizations

### Option 1: Shutdown After Hours

```bash
# Stop cluster when not in use
gcloud container clusters resize jobzy-dev \
  --num-nodes=0 \
  --region=europe-north1

# Start when needed
gcloud container clusters resize jobzy-dev \
  --num-nodes=1 \
  --region=europe-north1
```

### Option 2: Scheduled Scaling

```yaml
# Use GKE autopilot for automatic scaling
# Or create scheduled jobs for scaling
apiVersion: batch/v1
kind: CronJob
metadata:
  name: scale-down-evening
spec:
  schedule: "0 18 * * 1-5"  # 6 PM weekdays
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: scaler
            image: google/cloud-sdk:slim
            command:
            - gcloud
            - container
            - clusters
            - resize
            - jobzy-dev
            - --num-nodes=0
```

## Production Cost Optimization

### 1. Enable Cluster Autoscaling

```hcl
# Already configured
autoscaling {
  min_node_count = 2
  max_node_count = 10
}
```

### 2. Use Horizontal Pod Autoscaling

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: kong-hpa
  namespace: kong-system
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: kong
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

### 3. Use PodDisruptionBudgets

Ensure availability while allowing node scale-down:

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: kong-pdb
  namespace: kong-system
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: kong
```

## Long-Term Cost Strategies

### 1. Multi-Tenancy

Share infrastructure across multiple environments:

```hcl
# Use namespaces instead of separate clusters
# Single cluster with multiple namespaces
namespaces = ["dev", "staging", "prod"]
```

### 2. Reserved Capacity

For stable production workloads:

- Committed use discounts (1 or 3 years)
- Sustained use discounts (automatic)

### 3. Alternative Services

Consider managed alternatives:

- **Cloud Run** instead of GKE for stateless services
- **Cloud Functions** for event-driven workloads
- **Firebase** for simple backends

## Cost Tracking Tags

Ensure all resources are tagged:

```hcl
# Already configured in locals.tf
labels = {
  project     = "jobzy"
  environment = var.environment
  managed_by  = "terraform"
}
```

Query costs by tag:

```sql
-- In BigQuery
SELECT
  labels.value AS environment,
  SUM(cost) AS total_cost
FROM `billing_export.gcp_billing_export_v1`
WHERE labels.key = 'environment'
GROUP BY environment
```

## Estimated Savings Summary

| Strategy | Savings | Effort | Impact |
|----------|---------|--------|--------|
| Preemptible nodes (dev) | 60-80% | Low | High |
| Right-size resources | 20-40% | Medium | Medium |
| Committed use discounts | 25-55% | Low | High |
| Optimize DB tier | 30-50% | Low | Medium |
| Use BASIC Redis (dev) | 50% | Low | Low |
| Auto-scaling | 20-30% | Low | Medium |
| Shutdown dev after hours | 60% of dev | Medium | Medium |

## Recommendations by Environment

### Development
1. Use preemptible nodes ✓
2. Use smallest viable instance sizes
3. Single replica for all services
4. BASIC Redis tier ✓
5. ZONAL Cloud SQL ✓
6. Shutdown after hours (optional)

**Potential Savings: 70-80% vs. production configuration**

### Staging
1. Use preemptible nodes ✓
2. Medium-sized instances
3. Minimal replicas for HA testing
4. BASIC Redis tier
5. ZONAL Cloud SQL ✓

**Potential Savings: 50-60% vs. production configuration**

### Production
1. Committed use discounts (1 year)
2. Auto-scaling enabled ✓
3. Horizontal Pod Autoscaling
4. Regular resource utilization reviews
5. Reserved IPs only where needed

**Potential Savings: 25-35% through optimizations**
