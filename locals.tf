locals {
  secrets     = sensitive(yamldecode(file("${path.module}/secrets.yml")))

  name          = format("%s-%s", local.project, local.environment)
  environment   = terraform.workspace
  project       = "invenio"
  region        = var.vpc.region
  azs           = slice(data.aws_availability_zones.available.names, 0, 3)
  vpc_cidr      = var.vpc.cidr
  is_production = local.environment == "production"


  tags = {
    Application = "invenio"
    CreatedBy   = "terraform"
    Environment = local.environment
    Project     = local.project
  }

  alb_domain = format("alb-%s.%s", local.project, var.vpc.dns_zone)
  web-ui_domain = format("%s.%s", local.project, var.vpc.dns_zone)
  minio_domain = format("minio-%s.%s", local.project, var.vpc.dns_zone)
  pgadmin_domain = format("pgadmin-%s.%s", local.project, var.vpc.dns_zone)

  common_prefix = "invenio"
  elk_domain = "${local.common_prefix}-elk-domain"

}
