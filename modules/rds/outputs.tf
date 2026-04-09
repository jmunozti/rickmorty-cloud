output "endpoint" {
  description = "Aurora cluster endpoint (read/write)"
  value       = aws_rds_cluster.this.endpoint
}

output "reader_endpoint" {
  description = "Aurora reader endpoint (read-only, load balanced)"
  value       = aws_rds_cluster.this.reader_endpoint
}

output "address" {
  description = "Aurora cluster hostname"
  value       = aws_rds_cluster.this.endpoint
}

output "port" {
  description = "Aurora port"
  value       = aws_rds_cluster.this.port
}

output "db_name" {
  description = "Database name"
  value       = aws_rds_cluster.this.database_name
}

output "security_group_id" {
  description = "Aurora security group ID"
  value       = aws_security_group.db.id
}
