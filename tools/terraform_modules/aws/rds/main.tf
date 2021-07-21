module "rds_security_group" {
  source  = "terraform-aws-modules/security-group/aws//modules/postgresql"
  version = "~> 3.0"

  name                = "rds-sg"
  vpc_id              = var.vpc_id
  ingress_cidr_blocks = var.allow_subnet_cidrs

  tags = var.tags
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "aws_kms_key" "key" {
  description             = "RDS storage encryption key"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  tags                    = var.tags
}

module "rds" {
  source = "terraform-aws-modules/rds/aws"

  identifier = var.identifier

  engine               = var.engine
  family               = var.engine_family
  major_engine_version = var.major_engine_version
  engine_version       = var.engine_version
  instance_class       = var.instance_class
  allocated_storage    = var.storage_gb
  storage_encrypted    = true
  kms_key_id           = aws_kms_key.key.arn
  port                 = 5432
  skip_final_snapshot  = false

  name     = var.name
  username = var.username
  password = random_password.password.result

  vpc_security_group_ids = [module.rds_security_group.this_security_group_id]

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  multi_az            = var.multi_az
  publicly_accessible = true

  backup_retention_period = 7
  apply_immediately       = true

  tags = var.tags

  subnet_ids                = var.subnet_ids
  final_snapshot_identifier = "alex-mysql"

  # parameters = [
  #   {
  #     name  = "character_set_client"
  #     value = "utf8"
  #   },
  #   {
  #     name  = "character_set_server"
  #     value = "utf8"
  #   },
  #   {
  #     name  = "long_query_time"
  #     value = "2"
  #   },
  #   {
  #     apply_method = "pending-reboot"
  #     name         = "tls_version"
  #     value        = "TLSv1.2"
  #   },
  #   {
  #     name  = "wait_timeout"
  #     value = "600"
  #   }
  # ]
}

output "username" {
  description = "RDS username"
  value       = var.username
}

output "password" {
  description = "RDS password"
  sensitive   = true
  value       = random_password.password.result
}
