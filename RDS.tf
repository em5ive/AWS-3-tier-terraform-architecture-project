resource "aws_rds_cluster" "database" {
  cluster_identifier = "cloudathon-aurora"
  engine             = "aurora-mysql"
  engine_version     = var.aurora_engine_version
  engine_mode        = "provisioned"
  port               = 3306

  db_subnet_group_name   = aws_db_subnet_group.database.name
  vpc_security_group_ids = [aws_security_group.database.id]

  master_username             = var.db_master_username
  manage_master_user_password = true

  storage_encrypted = true
  storage_type      = "aurora"

  backup_retention_period = var.db_backup_retention_days
  preferred_backup_window = var.db_backup_window
  copy_tags_to_snapshot   = true
  apply_immediately       = false

  # deletion protection off temporarily for development
  deletion_protection = false
  skip_final_snapshot = true

  # Use the configured version at creation; AWS manages upgrades afterward.
  # Remove this rule before deliberately managing version upgrades in Terraform.
  lifecycle {
    ignore_changes = [engine_version]
  }

  tags = {
    Name = "cloudathon-aurora"
  }
}

resource "aws_rds_cluster_instance" "az1" {
  auto_minor_version_upgrade = true
  identifier                 = "db-az1"
  cluster_identifier         = aws_rds_cluster.database.id
  instance_class             = var.db_instance_class
  engine                     = aws_rds_cluster.database.engine
  engine_version             = aws_rds_cluster.database.engine_version

  db_subnet_group_name = aws_db_subnet_group.database.name
  availability_zone    = aws_subnet.db_az1.availability_zone
  publicly_accessible  = false
  promotion_tier       = 0
  apply_immediately    = false

  tags = {
    Name = "Cloudathon-db-az1"
  }
}

resource "aws_rds_cluster_instance" "az2" {
  auto_minor_version_upgrade = true
  identifier                 = "db-az2"
  cluster_identifier         = aws_rds_cluster.database.id
  instance_class             = var.db_instance_class
  engine                     = aws_rds_cluster.database.engine
  engine_version             = aws_rds_cluster.database.engine_version

  db_subnet_group_name = aws_db_subnet_group.database.name
  availability_zone    = aws_subnet.db_az2.availability_zone
  publicly_accessible  = false
  promotion_tier       = 1
  apply_immediately    = false


  tags = {
    Name = "Cloudathon-db-az2"
  }
}

output "database_writer_endpoint" {
  value = aws_rds_cluster.database.endpoint
}

output "database_reader_endpoint" {
  value = aws_rds_cluster.database.reader_endpoint
}

output "database_master_secret_arn" {
  description = "Secret reference only; does not expose the password"
  value       = aws_rds_cluster.database.master_user_secret[0].secret_arn
}

resource "aws_db_subnet_group" "database" {
  name        = "cloudathon-subnet-group"
  description = "Database subnets across two Availability Zones"

  subnet_ids = [
    aws_subnet.db_az1.id,
    aws_subnet.db_az2.id,
  ]

  tags = {
    Name = "cloudathon-subnet-group"
  }
}
