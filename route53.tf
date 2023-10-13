data "aws_route53_zone" "selected" {
  name         = "devlits.com"
  private_zone = false
}

resource "aws_route53_record" "cert_validation" {
  for_each = toset(concat([var.certificate_domain], var.certificate_sans))

  allow_overwrite = true
  zone_id = data.aws_route53_zone.selected.zone_id
  ttl = 60

  name    = local.validations[each.key].resource_record_name
  type    = local.validations[each.key].resource_record_type
  records = [ local.validations[each.key].resource_record_value ]

}
