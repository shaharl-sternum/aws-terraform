data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source               = "../vpc"
  name                 = var.env
  cidr                 = var.vpc_cidr
  azs                  = data.aws_availability_zones.available.names
  private_subnet_cidrs = var.private_subnet_cidrs
  public_subnet_cidrs  = var.public_subnet_cidrs
  tags                 = var.tags
  eks_cluster_name     = var.cluster_name
}

module "eks" {
  cluster_version     = var.cluster_version
  cluster_name        = var.cluster_name
  source              = "../eks"
  vpc_id              = module.vpc.vpc_id
  public_subnet_cidrs = var.public_subnet_cidrs
  private_subnet_ids  = module.vpc.private_subnets
  tags                = var.tags
  env                 = var.env
  map_users           = var.map_users
  region              = var.region
  worker_group_1 = {
    instance_type = var.eks_worker_instance_type
    min_count     = var.minimum_eks_regular_wrokers_count
    max_count     = 20
    desired_count = var.minimum_eks_regular_wrokers_count
    root_size     = var.storage_size
    taint         = ""
  }
  # iam_group_allow_access = "alex-dev-ops"
  # iam_user_allow_access  = "circle-ci"
}

# module "rds" {
#   source             = "../rds"
#   vpc_id             = module.vpc.vpc_id
#   allow_subnet_cidrs = concat(var.private_subnet_cidrs, var.public_subnet_cidrs)
#   instance_class     = var.rds_instance_class
#   multi_az           = true
#   subnet_ids         = module.vpc.public_subnets
#   storage_gb         = var.rds_storage_gb
#   tags               = var.tags
#   identifier         = "alex-${var.env}-postgresql"
#   name               = "alex"
#   username           = "alex"
# }

# TEMP

# module "rds-mysql" {
#   source             = "../rds-mysql"
#   vpc_id             = module.vpc.vpc_id
#   allow_subnet_cidrs = concat(var.private_subnet_cidrs, var.public_subnet_cidrs)
#   instance_class     = var.rds_instance_class
#   multi_az           = true
#   subnet_ids         = module.vpc.public_subnets
#   storage_gb         = var.rds_storage_gb
#   tags               = var.tags
#   identifier         = "alex-${var.env}-mysql"
#   name               = "alex"
#   username           = "alex"
# }

module "elasticache-redis" {
  source       = "../elasticache-redis"
  node_type    = var.elasticache_redis_node_type
  cluster_id   = "alex-${var.env}-redis"
  vpc_id       = module.vpc.vpc_id
  subnet_cidrs = var.private_subnet_cidrs
  tags         = var.tags
  env          = var.env
  subnet_ids   = module.vpc.private_subnets
}

module "elasticsearch" {
  source                   = "../elasticsearch"
  vpc_id                   = module.vpc.vpc_id
  subnet_cidrs             = var.private_subnet_cidrs
  subnet_ids               = module.vpc.private_subnets
  domain                   = "alex-${var.env}-es"
  elasticsearch_version    = "7.9"
  volume_size              = var.elasticsearch_volume_size
  instance_type            = var.elasticsearch_instance_type
  tags                     = var.tags
  azs                      = data.aws_availability_zones.available.names
  elasticsearch_node_count = var.elasticsearch_node_count
  create_es_linked_role    = var.create_es_linked_role
  encrypt_at_rest          = var.elasticsearch_encrypt_at_rest
  node_to_node_encryption  = var.elasticsearch_node_to_node_encryption
  dedicated_master_type    = var.elasticsearch_dedicated_master_type
  dedicated_master_enabled = var.elasticsearch_dedicated_master_enabled
  dedicated_master_count   = var.elasticsearch_dedicated_master_count
}

resource "aws_sqs_queue" "tasks_queue" {
  name                       = "${var.env}-tasks-queue"
  visibility_timeout_seconds = 360
  tags                       = var.tags
}

resource "aws_sqs_queue" "packets_queue" {
  name                       = "${var.env}-packets-queue"
  visibility_timeout_seconds = 360
  tags                       = var.tags
}

# module "dashboard" {
#   source       = "../dashboard"
#   bucket_name  = var.dashboard.bucket_name
#   dns          = var.dashboard.dns
#   route53_zone = var.dashboard.route53_zone
#   tags         = var.tags
#   env          = var.env
# }

provider "kubernetes" {
  # load_config_file       = false
  host                   = element(concat(data.aws_eks_cluster.cluster[*].endpoint, list("")), 0)
  cluster_ca_certificate = base64decode(element(concat(data.aws_eks_cluster.cluster[*].certificate_authority.0.data, list("")), 0))
  exec {
    command     = "aws-iam-authenticator"
    api_version = "client.authentication.k8s.io/v1alpha1"
    args        = ["token", "-i", data.aws_eks_cluster.cluster.name, "arn:aws:iam::069425080139:user/shahar"]
  }
}

provider "helm" {
  kubernetes {
    # load_config_file = false
    exec {
      command     = "aws-iam-authenticator"
      api_version = "client.authentication.k8s.io/v1alpha1"
      args        = ["token", "-i", data.aws_eks_cluster.cluster.name, "arn:aws:iam::069425080139:user/shahar"]
    }
    host                   = element(concat(data.aws_eks_cluster.cluster[*].endpoint, list("")), 0)
    cluster_ca_certificate = base64decode(element(concat(data.aws_eks_cluster.cluster[*].certificate_authority.0.data, list("")), 0))
  }
}