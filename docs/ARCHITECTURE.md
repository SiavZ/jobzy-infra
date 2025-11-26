# Jobzy Infrastructure Architecture

## Overview

The Jobzy infrastructure is designed as a cloud-native microservices platform running on Google Cloud Platform (GCP). It uses Kubernetes (GKE) for container orchestration, with Kong as an API Gateway and Keycloak for identity and access management.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                      Internet/Users                          │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
              ┌───────────────┐
              │ Load Balancer │
              └───────┬───────┘
                      │
        ┌─────────────┴─────────────┐
        ▼                           ▼
┌───────────────┐          ┌────────────────┐
│ Kong Gateway  │          │   Keycloak     │
│  (API GW)     │◄────────►│     (IAM)      │
└───────┬───────┘          └────────┬───────┘
        │                           │
        │        ┌──────────────────┘
        │        │
        ▼        ▼
┌────────────────────────────┐
│   GKE Kubernetes Cluster   │
│  ┌──────────────────────┐  │
│  │  Microservices Pods  │  │
│  └──────────────────────┘  │
└────────────┬───────────────┘
             │
    ┌────────┴────────┐
    ▼                 ▼
┌──────────┐    ┌───────────┐
│ Cloud SQL│    │ Redis     │
│(Postgres)│    │(Memstore) │
└──────────┘    └───────────┘
```

## Components

### 1. Google Kubernetes Engine (GKE)

**Purpose:** Container orchestration platform

**Features:**
- Regional cluster for high availability
- Autoscaling node pools (1-10 nodes)
- Workload Identity enabled
- Preemptible nodes for non-production environments

**Configuration:**
- Machine type: `n1-standard-2`
- Auto-repair and auto-upgrade enabled
- Network: Default VPC

### 2. Cloud SQL (PostgreSQL)

**Purpose:** Relational database for Kong and Keycloak

**Features:**
- PostgreSQL 15
- Private IP only (no public access)
- Automated backups (7-day retention)
- Point-in-time recovery (production)
- Regional availability (production)

**Databases:**
- `kong` - Kong Gateway configuration
- `keycloak` - Keycloak user data and sessions

### 3. Memorystore (Redis)

**Purpose:** Caching and session storage

**Features:**
- Redis 7.0
- Private service access
- STANDARD_HA tier for production
- BASIC tier for dev/staging

**Use Cases:**
- Kong rate limiting
- Keycloak session caching
- Application caching

### 4. Kong Gateway

**Purpose:** API Gateway and ingress controller

**Features:**
- Centralized API management
- Rate limiting
- Authentication
- Request/response transformation
- Load balancing

**Deployment:**
- Kubernetes Deployment (3 replicas in prod)
- LoadBalancer service for external access
- ClusterIP service for admin API

### 5. Keycloak

**Purpose:** Identity and Access Management (IAM)

**Features:**
- OAuth 2.0 / OpenID Connect
- Single Sign-On (SSO)
- User federation
- Multi-factor authentication
- Role-based access control

**Deployment:**
- Kubernetes Deployment (2 replicas in prod)
- LoadBalancer service for external access

## Network Architecture

### Connectivity

1. **External Traffic**
   - Users → Load Balancer → Kong/Keycloak
   - SSL/TLS termination at Kong

2. **Internal Traffic**
   - Microservices → Kong Admin API (ClusterIP)
   - Microservices → Keycloak (internal)
   - All services → Cloud SQL (private IP)
   - All services → Redis (private IP)

### Security

- **No public IPs** for databases
- **Private VPC peering** for Cloud SQL
- **Workload Identity** for pod authentication
- **Kubernetes secrets** for sensitive data
- **SSL/TLS** required for Cloud SQL connections

## Data Flow

1. **User Authentication:**
   ```
   User → Kong → Keycloak → Cloud SQL
                         → Redis (session cache)
   ```

2. **API Request:**
   ```
   User → Kong (auth check) → Microservice → Cloud SQL
                                         → Redis (cache)
   ```

## Scaling Strategy

### Horizontal Scaling

- **GKE Nodes:** Auto-scale 1-10 nodes based on resource usage
- **Kong Pods:** 1-3 replicas (environment-dependent)
- **Keycloak Pods:** 1-2 replicas (environment-dependent)
- **Microservices:** Auto-scale based on CPU/memory

### Vertical Scaling

- **Cloud SQL:** Upgrade tier as needed
- **Redis:** Increase memory size
- **GKE Nodes:** Change machine type

## High Availability

### Production Environment

- Regional GKE cluster (multi-zone)
- Regional Cloud SQL (automatic failover)
- Redis STANDARD_HA tier (replica)
- Multiple Kong replicas (3+)
- Multiple Keycloak replicas (2+)

### Disaster Recovery

- Automated database backups (daily)
- Point-in-time recovery (7 days)
- Terraform state in GCS with versioning
- Infrastructure as Code for fast rebuilding

## Monitoring and Observability

### Metrics

- GKE cluster metrics (Cloud Monitoring)
- Cloud SQL insights
- Kong metrics endpoint
- Keycloak metrics endpoint

### Logging

- GKE container logs (Cloud Logging)
- Kong access and error logs
- Keycloak logs
- Cloud SQL logs

### Alerting

- Node resource usage
- Pod health checks
- Database connections
- API response times

## Cost Optimization

### Development

- Preemptible nodes
- BASIC Redis tier
- ZONAL Cloud SQL
- Minimal replicas (1)
- Small machine types

### Production

- Standard nodes (for stability)
- STANDARD_HA Redis
- REGIONAL Cloud SQL
- Multiple replicas (HA)
- Appropriately sized resources

## Future Enhancements

1. **Service Mesh** - Istio for advanced traffic management
2. **GitOps** - ArgoCD for continuous deployment
3. **Observability** - Prometheus + Grafana
4. **Secrets Management** - Google Secret Manager integration
5. **Multi-region** - Global load balancing
6. **CDN** - Cloud CDN for static assets
