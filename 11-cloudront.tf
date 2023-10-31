module "cdn" {
  source = "terraform-aws-modules/cloudfront/aws"

  aliases = ["${local.web-ui_domain}"]

  comment             = "Invenio"
  enabled             = true
  is_ipv6_enabled     = true
  price_class         = "PriceClass_200"
  retain_on_delete    = false
  wait_for_deployment = false

  create_origin_access_identity = false
  create_origin_access_control = true
  origin_access_control = {
    s3_oac = {
      description      = "CloudFront access to S3"
      origin_type      = "s3"
      signing_behavior = "always"
      signing_protocol = "sigv4"
    }
  }
  origin_access_identities = {
    s3 = "Cloudfront access"
  }

  origin = {
    loadbalancer = {
      domain_name = local.alb_domain
      custom_origin_config = {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "https-only"
        origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
      }
    }

    s3 = {
      domain_name = aws_s3_bucket.static.bucket_regional_domain_name
      origin_access_control = "s3_oac"
    #   s3_origin_config = {
    #     origin_access_identity = "s3"
    #     origin_access_control = "s3_oac"
    #   }
    }
  }

  default_cache_behavior = {
    target_origin_id           = "loadbalancer"
    viewer_protocol_policy     = "allow-all"

    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods  = ["GET", "HEAD"]
    compress        = false
    use_forwarded_values = false
    cache_policy_id  = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
    origin_request_policy_id = "216adef6-5c7f-47e4-b989-5492eafa07d3"
  }

  ordered_cache_behavior = [
    {
      path_pattern           = "/static/*"
      target_origin_id       = "s3"
      viewer_protocol_policy = "redirect-to-https"

      allowed_methods = ["GET", "HEAD", "OPTIONS"]
      cached_methods  = ["GET", "HEAD"]
      cache_policy_id  = "658327ea-f89d-4fab-a63d-7e88639e58f6"
      origin_request_policy_id = "acba4595-bd28-49b8-b9fe-13317c0390fa"
      compress        = true
      use_forwarded_values = false
    }
  ]

  viewer_certificate = {
    acm_certificate_arn = module.acm_certificate_cloudfront.acm_certificate_arn
    ssl_support_method  = "sni-only"
  }
}

##s3-bucket for static

resource "aws_s3_bucket" "static" {
  bucket = var.s3.static_bucket
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket_policy" "static" {
  bucket = aws_s3_bucket.static.id
  policy = data.aws_iam_policy_document.s3_policy.json
}
data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    effect    = "Allow"
    resources = ["${aws_s3_bucket.static.arn}/*"]
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${module.cdn.cloudfront_distribution_id}"]
    }
  }
}
