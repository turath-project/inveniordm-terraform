module "acm_certificate" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 3.5"

  domain_name = local.alb_domain
  zone_id     = data.aws_route53_zone.this.zone_id

  subject_alternative_names = [local.pgadmin_domain, local.minio_domain]

  validate_certificate = true
  wait_for_validation  = true

  validation_method = "DNS"
}

module "acm_certificate_cloudfront" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 3.5"
  providers = {
    aws = aws.alternate_region       # Bypass AWS limitations for acm validation only from us-east-1 region
  }

  domain_name = local.web-ui_domain
  zone_id     = data.aws_route53_zone.this.zone_id

  validate_certificate = true
  wait_for_validation  = true

  validation_method = "DNS"
}
