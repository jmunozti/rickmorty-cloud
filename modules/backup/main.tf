# AWS Backup — centralized backup management
# Automates backups for RDS, EBS, and S3 with lifecycle policies

resource "aws_backup_vault" "this" {
  name = "${var.name}-vault"

  tags = {
    Name = "${var.name}-vault"
  }
}

resource "aws_iam_role" "backup" {
  name = "${var.name}-backup"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "backup.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "backup" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role_policy_attachment" "restore" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

# Daily backup plan
resource "aws_backup_plan" "daily" {
  name = "${var.name}-daily"

  rule {
    rule_name         = "daily-backup"
    target_vault_name = aws_backup_vault.this.name
    schedule          = "cron(0 3 * * ? *)" # 3 AM UTC daily

    lifecycle {
      delete_after = var.retention_days
    }

    copy_action {
      destination_vault_arn = aws_backup_vault.this.arn

      lifecycle {
        delete_after = var.retention_days
      }
    }
  }

  tags = {
    Name = "${var.name}-daily"
  }
}

# Weekly backup plan (longer retention)
resource "aws_backup_plan" "weekly" {
  name = "${var.name}-weekly"

  rule {
    rule_name         = "weekly-backup"
    target_vault_name = aws_backup_vault.this.name
    schedule          = "cron(0 4 ? * SUN *)" # 4 AM UTC every Sunday

    lifecycle {
      cold_storage_after = var.cold_storage_after
      delete_after       = var.weekly_retention_days
    }
  }

  tags = {
    Name = "${var.name}-weekly"
  }
}

# Select resources to backup by tag
resource "aws_backup_selection" "daily" {
  name         = "${var.name}-daily"
  plan_id      = aws_backup_plan.daily.id
  iam_role_arn = aws_iam_role.backup.arn

  selection_tag {
    type  = "STRINGEQUALS"
    key   = "backup"
    value = "daily"
  }
}

resource "aws_backup_selection" "weekly" {
  name         = "${var.name}-weekly"
  plan_id      = aws_backup_plan.weekly.id
  iam_role_arn = aws_iam_role.backup.arn

  selection_tag {
    type  = "STRINGEQUALS"
    key   = "backup"
    value = "weekly"
  }
}
