variable region {}

variable cluster_name {
  type = string
}

variable "tags" {
  type = map
}

variable "cluster_version" {
  type = string
}

variable "env" {
  type = string
}

variable "create_es_linked_role" {
  type    = bool
  default = false
}

variable "private_subnet_cidrs" {
  type    = list
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "public_subnet_cidrs" {
  type    = list
  default = ["10.0.101.0/24", "10.0.102.0/24"]
}

# variable "azs" {
#   type    = list
#   default = ["us-east-1a", "us-east-1b"]
# }

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "rds_instance_class" {
  type    = string
  default = "db.t3.medium"
}

variable "rds_storage_gb" {
  type    = number
  default = 50
}

variable "elasticache_redis_node_type" {
  type    = string
  default = "cache.t3.medium"
}

variable "elasticsearch_instance_type" {
  type    = string
  default = "t2.medium.elasticsearch"
}

variable "elasticsearch_dedicated_master_enabled" {
  type    = bool
  default = false
}

variable "elasticsearch_dedicated_master_count" {
  type    = number
  default = 0
}

// Not all instances support this feature. See here https://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/aes-supported-instance-types.html
variable "elasticsearch_encrypt_at_rest" {
  type    = bool
  default = false
}

variable "elasticsearch_node_to_node_encryption" {
  type    = bool
  default = false
}

variable "eks_worker_instance_type" {
  type    = string
  default = "t3.medium"
}

variable "eks_strong_worker_instance_type" {
  type    = string
  default = "c5a.xlarge"
}

variable "elasticsearch_volume_size" {
  type    = number
  default = 50
}

variable "dashboard" {
  type = object({
    bucket_name  = string
    dns          = string
    route53_zone = string
  })
}

variable "minimum_eks_regular_wrokers_count" {
  type    = number
  default = 2
}

variable "storage_size" {
  type    = number
  default = 100
}


variable "minimum_eks_strong_wrokers_count" {
  type    = number
  default = 2
}

variable "lambda_security_headers_name" {
  type    = string
  default = "set_security_headers"
}

variable "elasticsearch_node_count" {}

variable "elasticsearch_dedicated_master_type" {
  type = string
}

variable map_users {
  description = "Additional IAM users to add to the aws-auth configmap."
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}