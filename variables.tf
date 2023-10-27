variable "vpc" {
  type        = map(string)
  description = "Define CIDR and subnets ranges"
}

variable "environment" {
  type        = string
  description = "Name of environment which should match Terraform workspace name"
}

variable "account_id" {
  type        = string
  description = "Id of AWS account"
  validation {
    condition     = length(var.account_id) == 12
    error_message = "\"Account Id\" has wrong format"
  }
}

variable "acm" {
  type   = map(string)
  description = "The domain of the static site, eg example.com"
}

variable "acm_sans" {
  type   = map(string)
  description = "Domains for whitch we need certificates"
}

variable "rds" {
  type  = map(string)
}

variable "redis" {
  type  = map(string)
}

variable "elk" {
  type = map(string)
}

variable "mq" {
  type = map(string)
}

variable "minio" {
  type = map(string)
}

variable "pgadmin" {
  type = map(string)
}
