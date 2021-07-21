variable "name" {
  type = string
}

variable "cidr" {
  type = string
}

variable "azs" {
  type = list
}

variable "private_subnet_cidrs" {
  type = list
}

variable "public_subnet_cidrs" {
  type = list
}

variable "tags" {
  type    = map
  default = {}
}

variable "eks_cluster_name" {
  type = string
}