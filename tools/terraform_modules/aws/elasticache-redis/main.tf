module "redis_security_group" {
  source  = "terraform-aws-modules/security-group/aws//modules/redis"
  version = "~> 3.0"

  name                = "elasticache-redis-sg"
  vpc_id              = var.vpc_id
  ingress_cidr_blocks = var.subnet_cidrs

  tags = var.tags
}

resource "aws_elasticache_subnet_group" "elasticache-redis-subnet-group" {
  name       = "alex-${var.env}-elasticache-redis-subnet-group"
  subnet_ids = var.subnet_ids
}

resource "aws_elasticache_cluster" "elasticache-redis" {
  cluster_id           = var.cluster_id
  engine               = "redis"
  node_type            = var.node_type
  num_cache_nodes      = var.num_cache_nodes
  parameter_group_name = var.parameter_group_name
  engine_version       = var.engine_version
  port                 = var.port
  tags                 = var.tags
  security_group_ids   = [module.redis_security_group.this_security_group_id]
  subnet_group_name    = aws_elasticache_subnet_group.elasticache-redis-subnet-group.name
}