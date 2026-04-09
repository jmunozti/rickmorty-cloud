IMAGE_NAME := rickmorty-cloud
DOCKER_RUN := docker run --rm \
	-e AWS_ACCESS_KEY_ID \
	-e AWS_SECRET_ACCESS_KEY \
	-e AWS_DEFAULT_REGION \
	-e TF_VAR_db_password \
	-v /var/run/docker.sock:/var/run/docker.sock \
	-v $(PWD):/infra \
	$(IMAGE_NAME)

.PHONY: build deploy deploy-prod infra push status destroy destroy-prod fmt validate test lint

# Build the deploy container (once)
build:
	docker build -t $(IMAGE_NAME) deploy/

# Deploy everything to dev (infra + app images)
deploy: build
	$(DOCKER_RUN) deploy dev

# Deploy everything to prod
deploy-prod: build
	$(DOCKER_RUN) deploy prod

# Deploy only infrastructure
infra: build
	$(DOCKER_RUN) infra dev

# Push app images to ECR
push: build
	$(DOCKER_RUN) push dev

# Show cluster status
status: build
	$(DOCKER_RUN) status dev

# Destroy dev
destroy: build
	$(DOCKER_RUN) destroy dev

# Destroy prod
destroy-prod: build
	$(DOCKER_RUN) destroy prod

# --- Local commands (no Docker needed) ---

# Format Terraform
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

# Run API tests
test:
	cd app/backend && poetry run pytest tests/ -v

# Lint API
lint:
	cd app/backend && poetry run ruff check .
