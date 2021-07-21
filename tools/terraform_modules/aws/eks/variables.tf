variable "cluster_name" {
  type = string
}

variable "cluster_version" {
  type = string
}

variable "private_subnet_ids" {
  type = list
}
variable "public_subnet_cidrs" {
  type = list
}
variable "tags" {
  type = map
}
variable "vpc_id" {
  type = string
}

variable region {}

variable "worker_group_1" {
  type = object({
    instance_type = string
    desired_count = number
    min_count     = number
    max_count     = number
    taint         = string
    root_size     = number
  })
}
# variable "worker_group_2" {
#   type = object({
#     instance_type = string
#     desired_count = number
#     min_count     = number
#     max_count     = number
#     taint         = string
#     root_size     = number
#   })
# }

variable "env" {
  type = string
}
variable "mysql_username" {
  type    = string
  default = ""
}
variable "mysql_password" {
  type    = string
  default = ""
}
variable "map_users" {
  description = "Additional IAM users to add to the aws-auth configmap."
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}
variable "iam_group_allow_access" {
  type        = string
  description = "Name of IAM group to attach assume-role policy to"
  default     = null
}
variable "iam_user_allow_access" {
  type        = string
  description = "Name of IAM user to attach assume-role policy to"
  default     = null
}
