#↓↓↓↓↓ common locals ↓↓↓↓↓
locals {
  name    = format("%s", local.project)
  #  environment   = terraform.workspace
  project = "invenio"
  region  = "eu-north-1"
#  backend_domain = format("test-%s.%s", local.project, var.dns_zone)
  #  secrets     = sensitive(yamldecode(file("${path.module}/secrets.yml")))
  validations = {
  for option in aws_acm_certificate.example.domain_validation_options :
  option.domain_name => option
  }

}