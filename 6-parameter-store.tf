resource "aws_kms_key" "backend" {
  description             = format("%s-backend", local.name)
  deletion_window_in_days = 7
}

resource "aws_ssm_parameter" "backend" {
  for_each = merge(nonsensitive(local.secrets["backend"]),
    {
      AWS_ACCOUNT_NUMBER     = data.aws_caller_identity.this.account_id,       # There you can add non sensitive data
      AWS_REGION             = data.aws_region.this.name                       # Or sensitive with links from *.tfvars.json file
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


resource "aws_kms_key" "minio" {
  description             = format("%s-minio", local.name)
  deletion_window_in_days = 7
}

resource "aws_ssm_parameter" "minio" {
  for_each = merge(nonsensitive(local.secrets["minio"]),
    {
      MINIO_ROOT_USER = var.minio.root_user               # There you can add non sensitive data
      MINIO_ROOT_PASSWORD: var.minio.root_pass            # Or sensitive with links from *.tfvars.json
    }
  )

  name        = format("/%s-minio/%s/%s", local.project, local.environment, each.key)
  description = "N/A"

  type      = "SecureString"
  tier      = "Standard"
  key_id    = aws_kms_key.minio.id
  value     = each.value
  overwrite = true
}


resource "aws_kms_key" "pgadmin" {
  description             = format("%s-pgadmin", local.name)
  deletion_window_in_days = 7
}

resource "aws_ssm_parameter" "pgadmin" {
  for_each = merge(nonsensitive(local.secrets["pgadmin"]),
    {
      PGADMIN_DEFAULT_PASSWORD = var.pgadmin.root_pass               # There you can add non sensitive data
      PGADMIN_DEFAULT_EMAIL = var.pgadmin.admin_email                # Or sensitive with links from *.tfvars.json
    }
  )

  name        = format("/%s-pgadmin/%s/%s", local.project, local.environment, each.key)
  description = "N/A"

  type      = "SecureString"
  tier      = "Standard"
  key_id    = aws_kms_key.pgadmin.id
  value     = each.value
  overwrite = true
}