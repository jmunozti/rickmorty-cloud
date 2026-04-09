FROM hashicorp/terraform:1.7 AS terraform
FROM alpine:3.20

# Install all prerequisites in one image
RUN apk add --no-cache \
    aws-cli \
    bash \
    curl \
    docker-cli \
    git \
    helm \
    jq \
    python3

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/v1.29.0/bin/linux/amd64/kubectl" && \
    chmod +x kubectl && mv kubectl /usr/local/bin/

# Copy Terraform from official image
COPY --from=terraform /bin/terraform /usr/local/bin/terraform

WORKDIR /infra

COPY deploy.sh /usr/local/bin/deploy
RUN chmod +x /usr/local/bin/deploy

ENTRYPOINT ["deploy"]
