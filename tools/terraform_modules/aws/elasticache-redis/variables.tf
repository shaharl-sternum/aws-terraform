variable "node_type" {
  type = string
}

variable "cluster_id" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_cidrs" {
  type = list
}

variable "tags" {
  type = map
}

variable "engine_version" {
  type    = string
  default = "5.0.5"
}

variable "parameter_group_name" {
  type    = string
  default = "default.redis5.0"
}

variable "num_cache_nodes" {
  type    = number
  default = 1
}

variable "port" {
  type    = number
  default = 6379
}

variable "env" {
  type = string
}

variable "subnet_ids" {
  type = list
}
