terraform {
  required_version = ">=1.5.2,<2.0.0"
  backend "s3" {
    bucket          = "terraform-state-invenio-eu-north-1"        # manual add value
    key             = "terraform.tfstate"                         # manual add value
    region          = "eu-north-1"                                # manual add value
    # dynamodb_table  = "terraform-state-invenio-lock"
  }
}

provider "aws" {
  region = local.region
  allowed_account_ids = [var.account_id]
  default_tags {
    tags = merge(local.tags)
  }  
}

provider "aws" {                         # This is used by acm validation (AWS limits: validation accepted only
  alias  = "alternate_region"            #   from us-east-1 region
  region = "us-east-1"
}

##↓↓↓↓↓ common locals ↓↓↓↓↓
#locals {
#  name          = format("%s-%s", local.project, local.environment)
#  environment   = terraform.workspace
#  project       = "invenio"
#  region        = "eu-north-1"
#  azs           = slice(data.aws_availability_zones.available.names, 0, 3)
#  vpc_cidr      = "10.0.0.0/16"
#  is_production = local.environment == "production"
#
#
#  tags = {
#    Application = "invenio"
#    CreatedBy   = "terraform"
#    Environment = local.environment
#    Project     = local.project
#  }
#}
##↑↑↑↑↑ common locals ↑↑↑↑↑
#------------------------#
#↓↓↓↓↓ common data ↓↓↓↓↓
data "aws_region" "this" {}

data "aws_availability_zones" "available" {
  state = "available"
  filter {
    name   = "region-name"
    values = [data.aws_region.this.name]
  }
}

data "aws_caller_identity" "this" {
}
#↑↑↑↑↑ common data ↑↑↑↑↑
#------------------------#
#↓↓↓↓↓ common variables ↓↓↓↓↓
#variable "environment" {
#  type        = string
#  description = "Name of environment which should match Terraform workspace name"
#}
#
#variable "account_id" {
#  type        = string
#  description = "Id of AWS account"
#  validation {
#    condition     = length(var.account_id) == 12
#    error_message = "\"Account Id\" has wrong format"
#  }
#}
#↑↑↑↑↑ Common variables ↑↑↑↑↑
