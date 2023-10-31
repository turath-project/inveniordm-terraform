resource "aws_s3_bucket" "invenio_bucket" {
  bucket = var.s3.data_bucket
}

output "invenio_bucket_url" {
  value = aws_s3_bucket.invenio_bucket.bucket_regional_domain_name
}