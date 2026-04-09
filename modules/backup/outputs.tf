output "vault_arn" {
  description = "Backup vault ARN"
  value       = aws_backup_vault.this.arn
}

output "daily_plan_id" {
  description = "Daily backup plan ID"
  value       = aws_backup_plan.daily.id
}

output "weekly_plan_id" {
  description = "Weekly backup plan ID"
  value       = aws_backup_plan.weekly.id
}
