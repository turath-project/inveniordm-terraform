#resource "aws_kms_key" "backend" {
#  description             = format("%s-backend", local.name)
#  deletion_window_in_days = 7
#}
#
#resource "aws_ssm_parameter" "backend" {
#  for_each = merge(nonsensitive(local.secrets["backend"]),
#    {
#      AWS_ACCOUNT_NUMBER     = data.aws_caller_identity.this.account_id,
#      AWS_REGION             = data.aws_region.this.name
#      LOOP_DATABASE_HOST     = module.rds.db_instance_address
#      LOOP_DATABASE_PORT     = "5432"
#      LOOP_DATABASE_USERNAME = var.rds.db_username
#      LOOP_DATABASE_PASSWORD = var.rds.password
#      LOOP_DATABASE_NAME     = var.rds.db_name
#    }
#  )
#
#  name        = format("/%s-backend/%s/%s", local.project, each.key)
#  description = "N/A"
#
#  type      = "SecureString"
#  tier      = "Standard"
#  key_id    = aws_kms_key.backend.id
#  value     = each.value
#  overwrite = "true"
#}
