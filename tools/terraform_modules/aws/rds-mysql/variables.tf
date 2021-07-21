variable "vpc_id" {
  type = string
}

variable "identifier" {
  type = string
}

variable "allow_subnet_cidrs" {
  type = list
}

variable "name" {
  type = string
}

variable "instance_class" {
  type = string
}

variable "storage_gb" {
  type = number
}

variable "username" {
  type = string
}

variable "multi_az" {
  type = bool
}

variable "subnet_ids" {
  type = list
}

variable "tags" {
  type = map
}

variable "engine" {
  type    = string
  default = "mysql"
}

variable "engine_family" {
  type    = string
  default = "mysql5.7"
}

variable "major_engine_version" {
  type    = string
  default = "5.7"
}

variable "engine_version" {
  type    = string
  default = "5.7.28"
}