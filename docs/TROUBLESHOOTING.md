# Troubleshooting Guide

Common issues and their solutions.

## Terraform Issues

### Issue: Terraform State Lock

**Symptom:**
```
Error: Error acquiring the state lock
```

**Solution:**
```bash
# List locks
terraform force-unlock <LOCK_ID>

# If stuck, manually remove lock in GCS bucket
gsutil rm gs://jobzy-terraform-state-prod/jobzy/prod/default.tflock
```

### Issue: Provider Authentication Failed

**Symptom:**
```
Error: google: could not find default credentials
```

**Solution:**
```bash
# Set credentials
export GOOGLE_APPLICATION_CREDENTIALS="./terraform-key.json"

# Or authenticate with gcloud
gcloud auth application-default login
```

### Issue: Resource Already Exists

**Symptom:**
```
Error: A resource with this name already exists
```

**Solution:**
```bash
# Import existing resource
terraform import <resource_type>.<name> <resource_id>

# Or remove from state
terraform state rm <resource_type>.<name>
```

## GKE Issues

### Issue: Cluster Not Accessible

**Symptom:**
```
Unable to connect to the server: dial tcp: lookup ... no such host
```

**Solution:**
```bash
# Get fresh credentials
gcloud container clusters get-credentials jobzy-production \
  --region europe-north1

# Verify cluster exists
gcloud container clusters list
```

### Issue: Nodes Not Healthy

**Symptom:**
```
kubectl get nodes
NAME                STATUS     ROLES    AGE   VERSION
node-1              NotReady   <none>   1d    v1.27.0
```

**Solution:**
```bash
# Describe node for details
kubectl describe node node-1

# Check node logs in GCP Console
# Or delete unhealthy node (will auto-recreate)
kubectl delete node node-1
```

### Issue: Pods CrashLoopBackOff

**Symptom:**
```
NAME                    READY   STATUS             RESTARTS   AGE
kong-xxxx-yyyy          0/1     CrashLoopBackOff   5          5m
```

**Solution:**
```bash
# Check pod logs
kubectl logs kong-xxxx-yyyy -n kong-system

# Check pod events
kubectl describe pod kong-xxxx-yyyy -n kong-system

# Check resource limits
kubectl describe pod kong-xxxx-yyyy -n kong-system | grep -A 5 "Limits"

# Common fixes:
# 1. Database connection issue - verify Cloud SQL
# 2. Missing secrets - check kubectl get secrets
# 3. Resource limits - increase in deployment
```

## Kong Issues

### Issue: Kong Migrations Not Run

**Symptom:**
```
Kong fails to start with database migration errors
```

**Solution:**
```bash
# Run migrations
kubectl exec -it deployment/kong -n kong-system -- kong migrations bootstrap

# Or if already run
kubectl exec -it deployment/kong -n kong-system -- kong migrations up
```

### Issue: Kong Admin API Not Accessible

**Symptom:**
```
curl http://localhost:8001
Connection refused
```

**Solution:**
```bash
# Port forward to admin service
kubectl port-forward -n kong-system svc/kong-admin 8001:8001

# Then access
curl http://localhost:8001
```

### Issue: Kong Proxy Not Working

**Symptom:**
```
502 Bad Gateway from Kong
```

**Solution:**
```bash
# Check Kong logs
kubectl logs -l app=kong -n kong-system

# Check database connection
kubectl exec -it deployment/kong -n kong-system -- \
  kong config db_export

# Verify routes configured
kubectl port-forward -n kong-system svc/kong-admin 8001:8001
curl http://localhost:8001/routes
```

## Keycloak Issues

### Issue: Cannot Access Keycloak Admin Console

**Symptom:**
```
404 Not Found when accessing /admin
```

**Solution:**
```bash
# Check Keycloak is running
kubectl get pods -n keycloak

# Check logs
kubectl logs -l app=keycloak -n keycloak

# Verify database connection
kubectl describe pod -l app=keycloak -n keycloak
```

### Issue: Keycloak Login Fails

**Symptom:**
```
Invalid username or password
```

**Solution:**
```bash
# Check admin secret
kubectl get secret keycloak-admin-secret -n keycloak -o yaml

# Reset admin password
kubectl delete secret keycloak-admin-secret -n keycloak
kubectl create secret generic keycloak-admin-secret \
  -n keycloak \
  --from-literal=username=admin \
  --from-literal=password=NewSecurePassword123!

# Restart Keycloak
kubectl rollout restart deployment/keycloak -n keycloak
```

### Issue: Keycloak Database Connection Failed

**Symptom:**
```
Keycloak logs show database connection errors
```

**Solution:**
```bash
# Verify Cloud SQL is running
gcloud sql instances describe jobzy-prod-postgres

# Check database credentials
kubectl get secret keycloak-postgres-secret -n keycloak -o yaml

# Test connection from pod
kubectl exec -it deployment/keycloak -n keycloak -- \
  bash -c 'pg_isready -h $KC_DB_URL_HOST -p $KC_DB_URL_PORT'
```

## Cloud SQL Issues

### Issue: Cloud SQL Not Accessible

**Symptom:**
```
Connection to Cloud SQL times out
```

**Solution:**
```bash
# Verify instance is running
gcloud sql instances describe jobzy-prod-postgres

# Check VPC peering
gcloud services vpc-peerings list \
  --service=servicenetworking.googleapis.com

# Verify private IP
gcloud sql instances describe jobzy-prod-postgres \
  --format="get(ipAddresses[0].ipAddress)"
```

### Issue: Database User Cannot Connect

**Symptom:**
```
Authentication failed for user
```

**Solution:**
```bash
# List users
gcloud sql users list --instance=jobzy-prod-postgres

# Reset password
gcloud sql users set-password kong \
  --instance=jobzy-prod-postgres \
  --password=NewPassword123!

# Update Kubernetes secret
kubectl delete secret kong-postgres-secret -n kong-system
kubectl create secret generic kong-postgres-secret \
  -n kong-system \
  --from-literal=username=kong \
  --from-literal=password=NewPassword123!
```

### Issue: Out of Connections

**Symptom:**
```
FATAL: remaining connection slots are reserved
```

**Solution:**
```bash
# Check current connections
gcloud sql operations list --instance=jobzy-prod-postgres

# Increase max_connections flag
gcloud sql instances patch jobzy-prod-postgres \
  --database-flags=max_connections=300

# Or scale up instance tier
# Edit terraform/environments/prod.tfvars
database_tier = "db-custom-4-16384"
terraform apply -var-file="environments/prod.tfvars"
```

## Redis Issues

### Issue: Redis Not Accessible

**Symptom:**
```
Connection to Redis failed
```

**Solution:**
```bash
# Verify instance exists
gcloud redis instances describe jobzy-prod-redis --region=europe-north1

# Check host and port
gcloud redis instances describe jobzy-prod-redis \
  --region=europe-north1 \
  --format="get(host,port)"

# Test from pod
kubectl run -it --rm redis-test --image=redis:7.0 --restart=Never -- \
  redis-cli -h <REDIS_HOST> ping
```

### Issue: Redis Out of Memory

**Symptom:**
```
OOM command not allowed when used memory > 'maxmemory'
```

**Solution:**
```bash
# Check memory usage
gcloud redis instances describe jobzy-prod-redis \
  --region=europe-north1 \
  --format="get(memorySizeGb)"

# Increase Redis size
# Edit terraform/environments/prod.tfvars
redis_size_gb = 10
terraform apply -var-file="environments/prod.tfvars"
```

## Network Issues

### Issue: LoadBalancer IP Not Assigned

**Symptom:**
```
EXTERNAL-IP is <pending> for LoadBalancer service
```

**Solution:**
```bash
# Check service events
kubectl describe svc kong-proxy -n kong-system

# Check quota
gcloud compute project-info describe --project=jobzy-production

# Manually reserve IP
gcloud compute addresses create kong-ip --region=europe-north1

# Update service to use reserved IP
kubectl patch svc kong-proxy -n kong-system -p \
  '{"spec":{"loadBalancerIP":"<RESERVED_IP>"}}'
```

### Issue: Cannot Reach Service from Internet

**Symptom:**
```
Connection timeout when accessing LoadBalancer IP
```

**Solution:**
```bash
# Check firewall rules
gcloud compute firewall-rules list

# Verify service has external IP
kubectl get svc -n kong-system

# Check GKE node health
kubectl get nodes

# Test from within cluster
kubectl run -it --rm curl --image=curlimages/curl --restart=Never -- \
  curl http://kong-proxy.kong-system.svc.cluster.local
```

## Performance Issues

### Issue: High Pod CPU Usage

**Solution:**
```bash
# Check pod resources
kubectl top pods -n kong-system
kubectl top pods -n keycloak

# Increase resource limits
# Edit module deployment or overlay
# Then apply changes
terraform apply -var-file="environments/prod.tfvars"

# Or scale horizontally
kubectl scale deployment kong -n kong-system --replicas=5
```

### Issue: Slow Database Queries

**Solution:**
```bash
# Check Cloud SQL insights
gcloud sql operations list --instance=jobzy-prod-postgres

# Enable query insights (if not enabled)
gcloud sql instances patch jobzy-prod-postgres \
  --insights-config-query-insights-enabled

# Scale up database tier
# Edit terraform/environments/prod.tfvars
database_tier = "db-custom-4-16384"
terraform apply -var-file="environments/prod.tfvars"
```

## Getting Help

### Collect Debug Information

```bash
# Cluster info
kubectl cluster-info dump > cluster-dump.txt

# All pod logs
kubectl logs -l app=kong -n kong-system > kong-logs.txt
kubectl logs -l app=keycloak -n keycloak > keycloak-logs.txt

# Terraform state
terraform show > terraform-state.txt

# GCP resources
gcloud sql instances list > sql-instances.txt
gcloud redis instances list --region=europe-north1 > redis-instances.txt
```

### Check Cloud Logging

```bash
# View logs in console
gcloud logging read "resource.type=k8s_pod" --limit 50
```

### Contact Support

Include in your support request:
1. Error messages
2. Steps to reproduce
3. Environment (dev/staging/prod)
4. Recent changes
5. Debug information collected above
