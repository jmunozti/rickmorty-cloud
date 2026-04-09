# AWS Secrets Manager secrets for the application
resource "aws_secretsmanager_secret" "this" {
  for_each = var.secrets

  name                    = "${var.name}/${each.key}"
  description             = "Managed by Terraform for ${var.name}"
  recovery_window_in_days = var.recovery_window

  tags = {
    Name = "${var.name}-${each.key}"
  }
}

resource "aws_secretsmanager_secret_version" "this" {
  for_each = var.secrets

  secret_id     = aws_secretsmanager_secret.this[each.key].id
  secret_string = jsonencode(each.value)
}

# External Secrets Operator K8s manifests (to sync secrets into K8s)
# These would be applied via kubectl or ArgoCD after cluster is ready
resource "local_file" "external_secret_manifests" {
  for_each = var.secrets

  filename = "${path.module}/../../generated/external-secrets/${each.key}.yaml"

  content = yamlencode({
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ExternalSecret"
    metadata = {
      name      = each.key
      namespace = var.namespace
    }
    spec = {
      refreshInterval = "1h"
      secretStoreRef = {
        name = "aws-secrets-manager"
        kind = "ClusterSecretStore"
      }
      target = {
        name           = each.key
        creationPolicy = "Owner"
      }
      data = [
        for k, v in each.value : {
          secretKey = k
          remoteRef = {
            key      = "${var.name}/${each.key}"
            property = k
          }
        }
      ]
    }
  })
}

# ClusterSecretStore manifest
resource "local_file" "cluster_secret_store" {
  filename = "${path.module}/../../generated/external-secrets/cluster-secret-store.yaml"

  content = yamlencode({
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ClusterSecretStore"
    metadata = {
      name = "aws-secrets-manager"
    }
    spec = {
      provider = {
        aws = {
          service = "SecretsManager"
          region  = var.region
          auth = {
            jwt = {
              serviceAccountRef = {
                name      = "external-secrets"
                namespace = "external-secrets"
              }
            }
          }
        }
      }
    }
  })
}
