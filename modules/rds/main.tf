# Aurora Serverless v2 PostgreSQL
# Scales automatically based on load, supports multi-AZ

resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-db-subnet"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "${var.name}-db-subnet"
  }
}

resource "aws_security_group" "db" {
  name_prefix = "${var.name}-db-"
  vpc_id      = var.vpc_id
  description = "Security group for Aurora PostgreSQL"

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = var.allowed_security_group_ids
    description     = "PostgreSQL from EKS nodes"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = {
    Name = "${var.name}-db-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Aurora Cluster
resource "aws_rds_cluster" "this" {
  cluster_identifier = "${var.name}-aurora"

  engine         = "aurora-postgresql"
  engine_mode    = "provisioned"
  engine_version = "16.4"

  database_name   = var.db_name
  master_username = var.db_username
  master_password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.db.id]

  storage_encrypted   = true
  deletion_protection = var.deletion_protection

  backup_retention_period      = var.backup_retention_days
  preferred_backup_window      = "03:00-04:00"
  preferred_maintenance_window = "Mon:04:00-Mon:05:00"

  skip_final_snapshot = var.skip_final_snapshot

  serverlessv2_scaling_configuration {
    min_capacity = var.min_capacity
    max_capacity = var.max_capacity
  }

  tags = {
    Name   = "${var.name}-aurora"
    backup = var.backup_tag
  }
}

# Primary instance (Serverless v2)
resource "aws_rds_cluster_instance" "primary" {
  identifier         = "${var.name}-aurora-primary"
  cluster_identifier = aws_rds_cluster.this.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.this.engine
  engine_version     = aws_rds_cluster.this.engine_version

  performance_insights_enabled = true

  tags = {
    Name = "${var.name}-aurora-primary"
  }
}

# Read replica (Serverless v2, only in prod)
resource "aws_rds_cluster_instance" "replica" {
  count = var.replica_count

  identifier         = "${var.name}-aurora-replica-${count.index}"
  cluster_identifier = aws_rds_cluster.this.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.this.engine
  engine_version     = aws_rds_cluster.this.engine_version

  performance_insights_enabled = true

  tags = {
    Name = "${var.name}-aurora-replica-${count.index}"
  }
}
