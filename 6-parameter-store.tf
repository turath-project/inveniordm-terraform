resource "aws_kms_key" "backend" {
  description             = format("%s-backend", local.name)
  deletion_window_in_days = 7
}

resource "aws_ssm_parameter" "backend" {
  for_each = merge(nonsensitive(local.secrets["backend"]),
    {
      AWS_ACCOUNT_NUMBER     = data.aws_caller_identity.this.account_id,       # There you can add non sensetive data
      AWS_REGION             = data.aws_region.this.name                       # Sensitive data stored in secrets.yml
#      DATABASE_HOST     = module.rds.db_instance_address
#      DATABASE_PORT     = "5432"
#      DATABASE_USERNAME = var.rds.db_username
#      DATABASE_PASSWORD = var.rds.password
#      DATABASE_NAME     = var.rds.db_name
    }
  )

  name        = format("/%s-backend/%s/%s", local.project, local.environment, each.key)
  description = "N/A"

  type      = "SecureString"
  tier      = "Standard"
  key_id    = aws_kms_key.backend.id
  value     = each.value
  overwrite = true
}


resource "aws_kms_key" "frontend" {
  description             = format("%s-frontend", local.name)
  deletion_window_in_days = 7
}

#resource "aws_ssm_parameter" "frontend" {
#  for_each = merge(nonsensitive(local.secrets["frontend"]),
#    {
#      AWS_ACCOUNT_NUMBER     = data.aws_caller_identity.this.account_id,
#      AWS_REGION             = data.aws_region.this.name
#      DATABASE_HOST     = module.rds.db_instance_address
#      DATABASE_PORT     = "5432"
#      DATABASE_USERNAME = var.rds.db_username
#      DATABASE_PASSWORD = var.rds.password
#      DATABASE_NAME     = var.rds.db_name
#    }
#  )
#
#  name        = format("/%s-frontend/%s/%s", local.project, local.environment, each.key)
#  description = "N/A"
#
#  type      = "SecureString"
#  tier      = "Standard"
#  key_id    = aws_kms_key.frontend.id
#  value     = each.value
#  overwrite = "true"
#}
