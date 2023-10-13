#----------------------------------------------------------#
# Provider, default region & remote backend configuration
#----------------------------------------------------------#
provider "aws" {
  region  = var.aws_region
  profile = "lits"  #"<name of your profile in $HOME/.aws/credentials>"
}
terraform {
  required_version = ">= 1.1.0"
  backend "s3" {
    bucket = "terraform-state-invenio-test"
    key    = "invenio"
    region = "eu-north-1"
  }
}
