resource "aws_acm_certificate" "example" {
  domain_name                 = var.certificate_domain
  subject_alternative_names   = var.certificate_sans
  validation_method           = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "example" {
  certificate_arn         = aws_acm_certificate.example.arn
  validation_record_fqdns = aws_acm_certificate.example.domain_validation_options[*].resource_record_name
}