resource "aws_s3_bucket" "invenio_bucket" {
  bucket = "invenio-data"
}

output "invenio_bucket_url" {
  value = aws_s3_bucket.invenio_bucket.bucket_regional_domain_name
}