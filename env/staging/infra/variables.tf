variable vpc_name {}
variable vpc_cidr {}
variable private_subnet_cidrs {}
variable public_subnet_cidrs {}
variable region {}
variable env {}
variable eks_instance_type {}
variable cluster_name {}
variable cluster_version {}
variable elasticsearch_node_count {}
variable elasticsearch_instance_type {}
variable elasticsearch_dedicated_master_type {}
variable elasticsearch_dedicated_master_enabled {}
variable map_users {
  description = "Additional IAM users to add to the aws-auth configmap."
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}