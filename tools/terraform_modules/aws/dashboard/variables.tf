variable "bucket_name" {
  type = string
}

variable "dns" {
  type = string
}

variable "tags" {
  type = map
}

variable "route53_zone" {
  type = string
}

variable "env" {
  type = string
}
