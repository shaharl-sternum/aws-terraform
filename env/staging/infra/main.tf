terraform {
  backend "s3" {
    bucket = "alex-infra"
    key    = "terraform_states/stage"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.region
}

module "aws_base" {
  
  source                = "../../../tools/terraform_modules/aws/base"
  create_es_linked_role = false
  tags = {
    "Owner"       = "alex"
    "Environment" = "staging"
  }

  cluster_name                           = var.cluster_name
  vpc_cidr                               = var.vpc_cidr
  env                                    = var.env
  private_subnet_cidrs                   = var.private_subnet_cidrs
  public_subnet_cidrs                    = var.public_subnet_cidrs
  elasticsearch_encrypt_at_rest          = true
  elasticsearch_volume_size              = 100
  elasticsearch_instance_type            = var.elasticsearch_instance_type
  elasticsearch_node_count               = var.elasticsearch_node_count
  elasticsearch_node_to_node_encryption  = true
  elasticsearch_dedicated_master_type    = var.elasticsearch_dedicated_master_type
  elasticsearch_dedicated_master_enabled = var.elasticsearch_dedicated_master_enabled
  elasticsearch_dedicated_master_count   = 3
  cluster_version                        = var.cluster_version
  minimum_eks_regular_wrokers_count      = 2
  minimum_eks_strong_wrokers_count       = 1
  eks_strong_worker_instance_type        = "t3.medium"
  eks_worker_instance_type               = var.eks_instance_type
  map_users                              = var.map_users
  region                                 = var.region

  dashboard = {
    bucket_name  = "not yet"
    dns          = "not yet"
    route53_zone = "not yet"
  }
}