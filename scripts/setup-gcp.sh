#!/bin/bash
# =============================================================================
# Jobzy Platform - GCP Setup Script
# =============================================================================
# This script sets up the complete GCP infrastructure foundation:
# - Creates/configures GCP project
# - Enables required APIs
# - Creates service accounts
# - Sets up Workload Identity Federation
# - Creates Terraform state bucket
# - Configures IAM permissions
# =============================================================================

set -euo pipefail

# =============================================================================
# CONFIGURATION
# =============================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values (can be overridden via environment variables)
PROJECT_ID="${PROJECT_ID:-jobzy-prod}"
PROJECT_NAME="${PROJECT_NAME:-Jobzy Production}"
REGION="${REGION:-europe-north1}"
BILLING_ACCOUNT="${BILLING_ACCOUNT:-}"
GITHUB_ORG="${GITHUB_ORG:-}"
GITHUB_REPO="${GITHUB_REPO:-Jobzy-infra}"

# Service account names
TERRAFORM_SA="terraform-admin"
GKE_SA="gke-workload"

# State bucket
STATE_BUCKET="${PROJECT_ID}-terraform-state"

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_command() {
    if ! command -v "$1" &> /dev/null; then
        log_error "$1 is not installed. Please install it first."
        exit 1
    fi
}

confirm() {
    read -p "$1 [y/N] " response
    case "$response" in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# =============================================================================
# PRE-FLIGHT CHECKS
# =============================================================================

preflight_checks() {
    log_info "Running pre-flight checks..."

    check_command gcloud
    check_command gsutil
    check_command jq

    # Check gcloud authentication
    if ! gcloud auth list --filter="status:ACTIVE" --format="value(account)" | head -n1 | grep -q "@"; then
        log_error "Not authenticated with gcloud. Run: gcloud auth login"
        exit 1
    fi

    log_success "Pre-flight checks passed"
}

# =============================================================================
# PROJECT SETUP
# =============================================================================

setup_project() {
    log_info "Setting up GCP project: $PROJECT_ID"

    # Check if project exists
    if gcloud projects describe "$PROJECT_ID" &> /dev/null; then
        log_info "Project $PROJECT_ID already exists"
    else
        log_info "Creating project $PROJECT_ID..."
        gcloud projects create "$PROJECT_ID" --name="$PROJECT_NAME"
        log_success "Project created"
    fi

    # Set as default project
    gcloud config set project "$PROJECT_ID"
    log_success "Project set as default"
}

# =============================================================================
# BILLING SETUP
# =============================================================================

setup_billing() {
    if [ -z "$BILLING_ACCOUNT" ]; then
        log_info "Available billing accounts:"
        gcloud billing accounts list
        echo ""
        read -p "Enter billing account ID: " BILLING_ACCOUNT
    fi

    log_info "Linking billing account..."
    gcloud billing projects link "$PROJECT_ID" --billing-account="$BILLING_ACCOUNT"
    log_success "Billing account linked"
}

# =============================================================================
# ENABLE APIS
# =============================================================================

enable_apis() {
    log_info "Enabling required GCP APIs (this may take a few minutes)..."

    APIS=(
        # Core Infrastructure
        "compute.googleapis.com"
        "container.googleapis.com"
        "containerregistry.googleapis.com"
        "artifactregistry.googleapis.com"

        # Databases & Storage
        "sqladmin.googleapis.com"
        "redis.googleapis.com"
        "storage.googleapis.com"
        "storage-api.googleapis.com"

        # Networking
        "servicenetworking.googleapis.com"
        "dns.googleapis.com"
        "vpcaccess.googleapis.com"

        # Serverless
        "run.googleapis.com"
        "cloudbuild.googleapis.com"
        "cloudfunctions.googleapis.com"

        # IAM & Security
        "iam.googleapis.com"
        "iamcredentials.googleapis.com"
        "cloudresourcemanager.googleapis.com"
        "secretmanager.googleapis.com"
        "cloudkms.googleapis.com"

        # Monitoring & Logging
        "monitoring.googleapis.com"
        "logging.googleapis.com"
        "cloudtrace.googleapis.com"
        "clouderrorreporting.googleapis.com"

        # Security
        "securitycenter.googleapis.com"
        "binaryauthorization.googleapis.com"
    )

    for api in "${APIS[@]}"; do
        log_info "Enabling $api..."
        gcloud services enable "$api" --project="$PROJECT_ID" --quiet || true
    done

    log_success "All APIs enabled"
}

# =============================================================================
# CREATE SERVICE ACCOUNTS
# =============================================================================

create_service_accounts() {
    log_info "Creating service accounts..."

    # Terraform Admin Service Account
    if ! gcloud iam service-accounts describe "${TERRAFORM_SA}@${PROJECT_ID}.iam.gserviceaccount.com" &> /dev/null; then
        gcloud iam service-accounts create "$TERRAFORM_SA" \
            --display-name="Terraform Admin" \
            --description="Service account for Terraform infrastructure management"
        log_success "Created Terraform service account"
    else
        log_info "Terraform service account already exists"
    fi

    # GKE Workload Service Account
    if ! gcloud iam service-accounts describe "${GKE_SA}@${PROJECT_ID}.iam.gserviceaccount.com" &> /dev/null; then
        gcloud iam service-accounts create "$GKE_SA" \
            --display-name="GKE Workload Identity" \
            --description="Service account for GKE workloads"
        log_success "Created GKE service account"
    else
        log_info "GKE service account already exists"
    fi
}

# =============================================================================
# SETUP IAM PERMISSIONS
# =============================================================================

setup_iam() {
    log_info "Setting up IAM permissions..."

    TERRAFORM_SA_EMAIL="${TERRAFORM_SA}@${PROJECT_ID}.iam.gserviceaccount.com"
    GKE_SA_EMAIL="${GKE_SA}@${PROJECT_ID}.iam.gserviceaccount.com"

    # Terraform Admin permissions
    TERRAFORM_ROLES=(
        "roles/compute.admin"
        "roles/container.admin"
        "roles/cloudsql.admin"
        "roles/redis.admin"
        "roles/storage.admin"
        "roles/dns.admin"
        "roles/iam.serviceAccountAdmin"
        "roles/iam.serviceAccountUser"
        "roles/resourcemanager.projectIamAdmin"
        "roles/secretmanager.admin"
        "roles/run.admin"
        "roles/cloudbuild.builds.builder"
        "roles/vpcaccess.admin"
        "roles/servicenetworking.networksAdmin"
    )

    for role in "${TERRAFORM_ROLES[@]}"; do
        log_info "Granting $role to Terraform SA..."
        gcloud projects add-iam-policy-binding "$PROJECT_ID" \
            --member="serviceAccount:$TERRAFORM_SA_EMAIL" \
            --role="$role" \
            --quiet
    done

    # GKE Workload permissions
    GKE_ROLES=(
        "roles/storage.objectViewer"
        "roles/storage.objectCreator"
        "roles/cloudsql.client"
        "roles/secretmanager.secretAccessor"
        "roles/logging.logWriter"
        "roles/monitoring.metricWriter"
        "roles/cloudtrace.agent"
    )

    for role in "${GKE_ROLES[@]}"; do
        log_info "Granting $role to GKE SA..."
        gcloud projects add-iam-policy-binding "$PROJECT_ID" \
            --member="serviceAccount:$GKE_SA_EMAIL" \
            --role="$role" \
            --quiet
    done

    log_success "IAM permissions configured"
}

# =============================================================================
# CREATE TERRAFORM STATE BUCKET
# =============================================================================

create_state_bucket() {
    log_info "Creating Terraform state bucket: $STATE_BUCKET"

    if gsutil ls -b "gs://$STATE_BUCKET" &> /dev/null; then
        log_info "State bucket already exists"
    else
        gsutil mb -p "$PROJECT_ID" -l "$REGION" -b on "gs://$STATE_BUCKET"
        log_success "State bucket created"
    fi

    # Enable versioning
    gsutil versioning set on "gs://$STATE_BUCKET"
    log_info "Versioning enabled on state bucket"

    # Set lifecycle policy (keep last 10 versions)
    cat > /tmp/lifecycle.json << EOF
{
  "rule": [
    {
      "action": {"type": "Delete"},
      "condition": {"numNewerVersions": 10}
    }
  ]
}
EOF
    gsutil lifecycle set /tmp/lifecycle.json "gs://$STATE_BUCKET"
    rm /tmp/lifecycle.json
    log_success "Lifecycle policy set"
}

# =============================================================================
# SETUP WORKLOAD IDENTITY FEDERATION
# =============================================================================

setup_wif() {
    if [ -z "$GITHUB_ORG" ]; then
        log_warning "GitHub organization not set. Skipping WIF setup."
        log_info "To set up WIF later, run: ./scripts/setup-wif.sh"
        return 0
    fi

    log_info "Setting up Workload Identity Federation for GitHub Actions..."

    POOL_NAME="github-pool"
    PROVIDER_NAME="github-provider"
    TERRAFORM_SA_EMAIL="${TERRAFORM_SA}@${PROJECT_ID}.iam.gserviceaccount.com"

    # Create Workload Identity Pool
    if ! gcloud iam workload-identity-pools describe "$POOL_NAME" \
        --location="global" --project="$PROJECT_ID" &> /dev/null; then

        gcloud iam workload-identity-pools create "$POOL_NAME" \
            --location="global" \
            --display-name="GitHub Actions Pool" \
            --description="Workload Identity Pool for GitHub Actions CI/CD" \
            --project="$PROJECT_ID"
        log_success "Workload Identity Pool created"
    else
        log_info "Workload Identity Pool already exists"
    fi

    # Create OIDC Provider
    if ! gcloud iam workload-identity-pools providers describe "$PROVIDER_NAME" \
        --workload-identity-pool="$POOL_NAME" \
        --location="global" --project="$PROJECT_ID" &> /dev/null; then

        gcloud iam workload-identity-pools providers create-oidc "$PROVIDER_NAME" \
            --location="global" \
            --workload-identity-pool="$POOL_NAME" \
            --display-name="GitHub Provider" \
            --issuer-uri="https://token.actions.githubusercontent.com" \
            --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository,attribute.repository_owner=assertion.repository_owner" \
            --attribute-condition="assertion.repository_owner=='${GITHUB_ORG}'" \
            --project="$PROJECT_ID"
        log_success "OIDC Provider created"
    else
        log_info "OIDC Provider already exists"
    fi

    # Grant access to service account
    WORKLOAD_IDENTITY_POOL_ID=$(gcloud iam workload-identity-pools describe "$POOL_NAME" \
        --location="global" --project="$PROJECT_ID" --format="value(name)")

    gcloud iam service-accounts add-iam-policy-binding "$TERRAFORM_SA_EMAIL" \
        --project="$PROJECT_ID" \
        --role="roles/iam.workloadIdentityUser" \
        --member="principalSet://iam.googleapis.com/${WORKLOAD_IDENTITY_POOL_ID}/attribute.repository/${GITHUB_ORG}/${GITHUB_REPO}"

    log_success "Workload Identity Federation configured"

    # Output configuration for GitHub Actions
    echo ""
    log_info "=== GitHub Actions Configuration ==="
    echo ""
    echo "Add these secrets to your GitHub repository:"
    echo ""
    echo "GCP_PROJECT_ID: $PROJECT_ID"
    echo "GCP_WORKLOAD_IDENTITY_PROVIDER: projects/$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')/locations/global/workloadIdentityPools/$POOL_NAME/providers/$PROVIDER_NAME"
    echo "GCP_SERVICE_ACCOUNT: $TERRAFORM_SA_EMAIL"
    echo ""
}

# =============================================================================
# UPDATE TERRAFORM BACKEND
# =============================================================================

update_terraform_backend() {
    log_info "Updating Terraform backend configuration..."

    BACKEND_FILE="terraform/backend.tf"

    cat > "$BACKEND_FILE" << EOF
# =============================================================================
# Terraform Backend Configuration
# =============================================================================
# State is stored in Google Cloud Storage with versioning enabled
# =============================================================================

terraform {
  backend "gcs" {
    bucket = "${STATE_BUCKET}"
    prefix = "terraform/state"
  }
}
EOF

    log_success "Backend configuration updated"
}

# =============================================================================
# CREATE ENVIRONMENT TFVARS FILES
# =============================================================================

create_tfvars() {
    log_info "Creating environment tfvars files..."

    mkdir -p terraform/environments

    # Development
    cat > terraform/environments/dev.tfvars << EOF
# =============================================================================
# Development Environment Configuration
# =============================================================================

project_id   = "${PROJECT_ID}"
region       = "${REGION}"
environment  = "dev"
cluster_name = "jobzy-dev"
domain       = "dev.jobzy.fi"

# Minimal resources for development
gke_num_nodes    = 2
gke_min_nodes    = 1
gke_max_nodes    = 5
gke_machine_type = "n1-standard-2"

postgres_tier      = "db-f1-micro"
postgres_disk_size = 20

mysql_tier      = "db-f1-micro"
mysql_disk_size = 20

redis_size_gb = 1

kong_replicas     = 1
keycloak_replicas = 1

# Disable expensive features for dev
enable_observability = false
enable_elk           = false
enable_linkerd       = false
enable_jaeger        = false

# Frontend
frontend_max_instances = 2

# Keycloak (set via environment variable or prompt)
# keycloak_admin_password = ""
EOF

    # Staging
    cat > terraform/environments/staging.tfvars << EOF
# =============================================================================
# Staging Environment Configuration
# =============================================================================

project_id   = "${PROJECT_ID}"
region       = "${REGION}"
environment  = "staging"
cluster_name = "jobzy-staging"
domain       = "staging.jobzy.fi"

# Moderate resources for staging
gke_num_nodes    = 3
gke_min_nodes    = 2
gke_max_nodes    = 8
gke_machine_type = "n1-standard-4"

postgres_tier      = "db-custom-2-8192"
postgres_disk_size = 50

mysql_tier      = "db-custom-2-8192"
mysql_disk_size = 100

redis_size_gb = 4

kong_replicas     = 2
keycloak_replicas = 2

# Enable observability for staging
enable_observability = true
enable_elk           = true
enable_linkerd       = true
enable_jaeger        = true

# Frontend
frontend_max_instances = 5

# keycloak_admin_password = ""
EOF

    # Production
    cat > terraform/environments/prod.tfvars << EOF
# =============================================================================
# Production Environment Configuration
# =============================================================================

project_id   = "${PROJECT_ID}"
region       = "${REGION}"
environment  = "prod"
cluster_name = "jobzy-prod"
domain       = "jobzy.fi"

# Production resources
gke_num_nodes    = 3
gke_min_nodes    = 3
gke_max_nodes    = 20
gke_machine_type = "n1-standard-4"

postgres_tier      = "db-custom-4-16384"
postgres_disk_size = 100

mysql_tier      = "db-custom-4-16384"
mysql_disk_size = 200

redis_size_gb = 16

kong_replicas     = 3
keycloak_replicas = 2

# Enable all features for production
enable_observability = true
enable_elk           = true
enable_linkerd       = true
enable_jaeger        = true

# Frontend
frontend_max_instances = 10

# DNS
manage_dns                   = true
enable_service_subdomains    = true
enable_monitoring_subdomains = true

# keycloak_admin_password = ""
# grafana_admin_password = ""
# slack_webhook_url = ""
EOF

    log_success "Environment tfvars files created"
}

# =============================================================================
# VERIFY SETUP
# =============================================================================

verify_setup() {
    log_info "Verifying setup..."

    echo ""
    echo "=== Setup Summary ==="
    echo ""
    echo "Project ID:        $PROJECT_ID"
    echo "Region:            $REGION"
    echo "State Bucket:      gs://$STATE_BUCKET"
    echo ""
    echo "Service Accounts:"
    echo "  - ${TERRAFORM_SA}@${PROJECT_ID}.iam.gserviceaccount.com (Terraform)"
    echo "  - ${GKE_SA}@${PROJECT_ID}.iam.gserviceaccount.com (GKE Workloads)"
    echo ""

    # Verify APIs
    log_info "Enabled APIs:"
    gcloud services list --enabled --project="$PROJECT_ID" --format="value(config.name)" | head -20

    echo ""
    log_success "GCP setup complete!"
    echo ""
    echo "=== Next Steps ==="
    echo ""
    echo "1. Configure environment-specific secrets:"
    echo "   - Set keycloak_admin_password in tfvars"
    echo "   - Set grafana_admin_password in tfvars"
    echo ""
    echo "2. Initialize Terraform:"
    echo "   cd terraform"
    echo "   terraform init"
    echo ""
    echo "3. Deploy development environment:"
    echo "   terraform plan -var-file=environments/dev.tfvars"
    echo "   terraform apply -var-file=environments/dev.tfvars"
    echo ""
}

# =============================================================================
# MAIN
# =============================================================================

main() {
    echo ""
    echo "=============================================="
    echo "  Jobzy Platform - GCP Setup Script"
    echo "=============================================="
    echo ""
    echo "This script will set up the following:"
    echo "  - GCP Project: $PROJECT_ID"
    echo "  - Region: $REGION"
    echo "  - Required APIs"
    echo "  - Service Accounts"
    echo "  - IAM Permissions"
    echo "  - Terraform State Bucket"
    echo "  - Workload Identity Federation (optional)"
    echo ""

    if ! confirm "Do you want to proceed?"; then
        log_info "Setup cancelled"
        exit 0
    fi

    preflight_checks
    setup_project
    setup_billing
    enable_apis
    create_service_accounts
    setup_iam
    create_state_bucket
    setup_wif
    update_terraform_backend
    create_tfvars
    verify_setup
}

# Run main function
main "$@"
