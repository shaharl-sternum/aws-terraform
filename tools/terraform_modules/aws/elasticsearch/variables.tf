variable "vpc_id" {
  type = string
}

variable "create_es_linked_role" {
  type    = bool
  default = false
}

variable "subnet_cidrs" {
  type = list
}

variable "domain" {
  type = string
}

variable "elasticsearch_version" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "subnet_ids" {
  type = list
}

variable "tags" {
  type = map
}

variable "azs" {
  type = list
}

variable "volume_size" {
  type    = number
  default = 100
}

variable "encrypt_at_rest" {
  type    = bool
  default = false
}

variable "node_to_node_encryption" {
  type    = bool
  default = false
}

variable elasticsearch_node_count {}

variable "dedicated_master_count" {
  type = number
}

variable "dedicated_master_enabled" {
  type = bool
}

variable "dedicated_master_type" {
  type = string
}