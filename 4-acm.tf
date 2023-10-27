module "acm_certificate" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 3.5"
  providers = {
    aws = aws.alternate_region       # Bypass AWS limitations for acm validation only from us-east-1 region
  }

  domain_name = var.vpc.dns_zone
  zone_id     = data.aws_route53_zone.this.zone_id

  subject_alternative_names = [local.frontend_domain, local.web-api_domain, local.web-ui_domain ]

  validate_certificate = true
  wait_for_validation  = true

  validation_method = "DNS"
}

resource "aws_acm_certificate" "acm_certificate" {
  domain_name                 = var.acm.cert_domain
#  subject_alternative_names   = var.certificate_sans
  subject_alternative_names = [
    var.acm_sans.certificate_san1,
    var.acm_sans.certificate_san2,
    var.acm_sans.certificate_san3,
    var.acm_sans.certificate_san4,
    var.acm_sans.certificate_san5
  ]
  validation_method           = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "acm_certificate_validation" {
  certificate_arn         = aws_acm_certificate.acm_certificate.arn
  validation_record_fqdns = aws_acm_certificate.acm_certificate.domain_validation_options[*].resource_record_name
}
