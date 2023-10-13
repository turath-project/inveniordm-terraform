##-------------------------------------------------------------------#
## S3 buckets configuration for frontend static hosting
##-------------------------------------------------------------------#
#
## S3 bucket configuration for frontend
#resource "aws_s3_bucket" "frontend" {
#  bucket = "${var.project_name}-frontend"
#
#  tags = {
#    Name         = "frontend s3 bucket"
#    ManagedBy    = "terraform"
#  }
#}
#
#resource "aws_s3_bucket_acl" "frontend" {
#  bucket = aws_s3_bucket.frontend.id
#  acl    = "private"
#}
#
#data "aws_iam_policy_document" "s3_frontend" {
#  statement {
#    actions   = ["s3:GetObject"]
#    resources = ["${aws_s3_bucket.frontend.arn}/*"]
#
#    principals {
#      type        = "AWS"
#      identifiers = [aws_cloudfront_origin_access_identity.frontend.iam_arn]
#    }
#  }
#}
#
#resource "aws_s3_bucket_policy" "frontend" {
#  bucket = aws_s3_bucket.frontend.id
#  policy = data.aws_iam_policy_document.s3_frontend.json
#}
#
#resource "aws_s3_bucket_public_access_block" "frontend" {
#  bucket                  = aws_s3_bucket.frontend.id
#  block_public_acls       = true
#  block_public_policy     = true
#  ignore_public_acls      = true
#  restrict_public_buckets = true
#}
#
#resource "aws_s3_bucket_versioning" "versioning_frontend" {
#  bucket = aws_s3_bucket.frontend.id
#
#  versioning_configuration {
#    status = "Enabled"
#  }
#}


# S3 bucket for ALB access logs

resource "aws_s3_bucket" "alb_access_logs" {
  bucket        = "${var.project_name}-alb-access-logs"
  acl           = "private"
  force_destroy = true

  lifecycle_rule {
    id                                     = "cleanup"
    enabled                                = true
    abort_incomplete_multipart_upload_days = 1
    prefix                                 = "/"

    expiration {
      days = 3
    }
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_policy" "alb_access_logs" {
  bucket = aws_s3_bucket.alb_access_logs.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "s3:PutObject",
      "Principal": {
        "AWS": "arn:aws:iam::897822967062:root"
      },
      "Resource": "${aws_s3_bucket.alb_access_logs.arn}/*",
      "Effect": "Allow"
    }
  ]
}
POLICY
}

