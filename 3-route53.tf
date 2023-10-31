data "aws_route53_zone" "this" {
  name         = var.vpc.dns_zone
  private_zone = false
}


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