.PHONY: fmt validate plan-dev plan-prod init-backend

# Format all Terraform files
fmt:
	terraform fmt -recursive

# Validate all environments
validate:
	@for env in dev prod; do \
		echo "=== Validating $$env ===" && \
		cd environments/$$env && \
		terraform init -backend=false -input=false > /dev/null 2>&1 && \
		terraform validate && \
		cd ../.. ; \
	done

# Initialize the S3 backend (run once)
init-backend:
	cd backend && terraform init && terraform apply

# Plan dev environment
plan-dev:
	cd environments/dev && terraform init && terraform plan

# Plan prod environment
plan-prod:
	cd environments/prod && terraform init && terraform plan

# Apply dev environment
apply-dev:
	cd environments/dev && terraform init && terraform apply

# Apply prod environment (requires approval)
apply-prod:
	cd environments/prod && terraform init && terraform apply

# Destroy dev environment
destroy-dev:
	cd environments/dev && terraform destroy

# Show what's deployed
show-dev:
	cd environments/dev && terraform output

show-prod:
	cd environments/prod && terraform output
