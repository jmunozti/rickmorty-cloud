#!/bin/bash
# rickmorty-cloud deploy — one command to rule them all
set -euo pipefail

ACTION="${1:-help}"
ENV="${2:-dev}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[rickmorty-cloud]${NC} $1"; }
warn() { echo -e "${YELLOW}[rickmorty-cloud]${NC} $1"; }
err() { echo -e "${RED}[rickmorty-cloud]${NC} $1"; exit 1; }

check_aws() {
    aws sts get-caller-identity > /dev/null 2>&1 || err "AWS credentials not configured. Pass them via environment variables:
    docker run -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY -e AWS_DEFAULT_REGION ..."
    log "AWS authenticated as: $(aws sts get-caller-identity --query Arn --output text)"
}

init_backend() {
    BUCKET="eks-platform-tfstate"
    if aws s3 ls "s3://$BUCKET" > /dev/null 2>&1; then
        log "Backend already exists (s3://$BUCKET), skipping creation"
    else
        log "Creating Terraform backend (S3 + DynamoDB)..."
        cd /infra/backend
        terraform init
        terraform apply -auto-approve
        cd /infra
        log "Backend created"
    fi
}

deploy_infra() {
    log "Deploying $ENV environment..."

    if [ -z "${TF_VAR_db_password:-}" ]; then
        export TF_VAR_db_password="RickMorty$(date +%s | sha256sum | head -c 12)!"
        warn "Generated random DB password (export TF_VAR_db_password to set your own)"
    fi

    cd /infra/environments/$ENV
    terraform init
    terraform apply -auto-approve

    CLUSTER_NAME=$(terraform output -raw cluster_name)
    REGION=$(terraform output -raw region 2>/dev/null || echo "us-east-1")

    log "Configuring kubectl..."
    aws eks update-kubeconfig --name "$CLUSTER_NAME" --region "$REGION"

    log "Infrastructure deployed"
    cd /infra
}

push_images() {
    log "Building and pushing images to ECR..."

    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    REGION=$(cd /infra/environments/$ENV && terraform output -raw region 2>/dev/null || echo "us-east-1")
    ECR_BASE="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"

    # Auto ECR login
    aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$ECR_BASE"

    CLUSTER_NAME=$(cd /infra/environments/$ENV && terraform output -raw cluster_name)

    # Build and push backend
    log "Building backend..."
    docker build -t "$ECR_BASE/$CLUSTER_NAME/backend:latest" /infra/app/backend/
    docker push "$ECR_BASE/$CLUSTER_NAME/backend:latest"

    # Build and push frontend
    log "Building frontend..."
    docker build -t "$ECR_BASE/$CLUSTER_NAME/frontend:latest" /infra/app/frontend/
    docker push "$ECR_BASE/$CLUSTER_NAME/frontend:latest"

    log "Images pushed to ECR"
}

deploy_app() {
    log "Deploying app with Helm..."

    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    REGION=$(cd /infra/environments/$ENV && terraform output -raw region 2>/dev/null || echo "us-east-1")
    ECR_BASE="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"
    CLUSTER_NAME=$(cd /infra/environments/$ENV && terraform output -raw cluster_name)

    VALUES_FILE="/infra/helm/rickmorty/values.yaml"
    if [ "$ENV" = "prod" ]; then
        VALUES_FILE="/infra/helm/rickmorty/values-prod.yaml"
    fi

    helm upgrade --install rickmorty /infra/helm/rickmorty \
        --namespace rickmorty \
        --create-namespace \
        --set backend.image="$ECR_BASE/$CLUSTER_NAME/backend:latest" \
        --set frontend.image="$ECR_BASE/$CLUSTER_NAME/frontend:latest" \
        -f "$VALUES_FILE" \
        --wait --timeout 300s

    log "App deployed. Getting ALB URL..."
    sleep 10
    kubectl get ingress -n rickmorty
}

show_status() {
    cd /infra/environments/$ENV
    terraform init -input=false > /dev/null 2>&1

    log "=== Outputs ==="
    terraform output 2>/dev/null || warn "No outputs yet"

    log "=== Nodes ==="
    kubectl get nodes 2>/dev/null || warn "Cluster not accessible yet"

    log "=== Pods ==="
    kubectl get pods -A 2>/dev/null || true
}

destroy() {
    warn "Destroying $ENV environment..."
    cd /infra/environments/$ENV
    terraform init -input=false > /dev/null 2>&1
    terraform destroy -auto-approve
    log "$ENV destroyed"
}

case "$ACTION" in
    deploy)
        check_aws
        init_backend
        deploy_infra
        push_images
        deploy_app
        show_status
        log "Done! Your app is running on EKS."
        ;;
    infra)
        check_aws
        init_backend
        deploy_infra
        show_status
        ;;
    push)
        check_aws
        push_images
        ;;
    status)
        check_aws
        show_status
        ;;
    destroy)
        check_aws
        destroy
        ;;
    help|*)
        echo ""
        echo "rickmorty-cloud — Deploy Rick and Morty Explorer to AWS EKS"
        echo ""
        echo "Usage:"
        echo "  deploy [env]    Deploy everything (infra + images) to dev|prod"
        echo "  infra [env]     Deploy only infrastructure"
        echo "  push [env]      Build and push images to ECR"
        echo "  status [env]    Show cluster status and outputs"
        echo "  destroy [env]   Tear down everything"
        echo ""
        echo "Example:"
        echo "  docker run --rm \\"
        echo "    -e AWS_ACCESS_KEY_ID \\"
        echo "    -e AWS_SECRET_ACCESS_KEY \\"
        echo "    -e AWS_DEFAULT_REGION=us-east-1 \\"
        echo "    -v /var/run/docker.sock:/var/run/docker.sock \\"
        echo "    rickmorty-cloud deploy dev"
        echo ""
        ;;
esac
