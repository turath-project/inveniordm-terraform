terraform {
  required_version = ">=1.5.2,<2.0.0"
  backend "s3" {
    bucket          = "cmesturath-dev-applications"        # manual add value
    key             = "terraform-inveniordm.tfstate"                         # manual add value
    region          = "us-east-1"                                # manual add value
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
