data "aws_route53_zone" "this" {
  name         = var.vpc.dns_zone
  private_zone = false
}

# resource "aws_route53_record" "cert_validation" {
#   for_each = toset(concat([var.acm.cert_domain], [
#     var.acm_sans.certificate_invenio,
#     var.acm_sans.certificate_alb,
#     var.acm_sans.certificate_minio,
#     var.acm_sans.certificate_pgadmin
#     ]
#    )
#   )
#   allow_overwrite = true
#   zone_id = data.aws_route53_zone.this.zone_id
#   ttl = 60

#   name    = local.validations[each.key].resource_record_name
#   type    = local.validations[each.key].resource_record_type
#   records = [ local.validations[each.key].resource_record_value ]

# }


resource "aws_route53_record" "invenio_A-record" {
  for_each = toset([
    local.alb_domain,
    local.minio_domain,
    local.pgadmin_domain
  ])
  depends_on = [data.aws_route53_zone.this, aws_lb.this]

  zone_id = data.aws_route53_zone.this.zone_id
  name    = each.key
  type    = "A"

  alias {
    name                   = aws_lb.this.dns_name
    zone_id                = aws_lb.this.zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "alb" {
  for_each = toset([
    local.web-ui_domain
  ])
  depends_on = [data.aws_route53_zone.this, aws_lb.this]

  zone_id = data.aws_route53_zone.this.zone_id
  name    = each.key
  type    = "A"

  alias {
    name                   = module.cdn.cloudfront_distribution_domain_name
    zone_id                = module.cdn.cloudfront_distribution_hosted_zone_id
    evaluate_target_health = false
  }
}