# # RDS Module
module "rds" {
  source = "terraform-aws-modules/rds/aws"
  version = "6.1.0"
  identifier = format("%s-rds", local.name)
  # All available versions: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html#PostgreSQL.Concepts
  engine               = "postgres"
  engine_version       = "15"
  family               = "postgres15"
  major_engine_version = "15"
  instance_class       = local.is_production ? var.rds.instance_class_prod : var.rds.instance_class
  allocated_storage    = var.rds.allocated_storage
  db_name  = var.rds.db_name
  username = var.rds.db_username
  port     = 5432
  multi_az               = var.rds.multi_az
  db_subnet_group_name   = module.vpc.database_subnet_group
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  manage_master_user_password = false
  password = var.rds.password
  publicly_accessible = true

  maintenance_window              = "Mon:00:00-Mon:03:00"
  backup_window                   = "03:00-06:00"
  enabled_cloudwatch_logs_exports = []
  create_cloudwatch_log_group     = false

  backup_retention_period = 7
  skip_final_snapshot     = false
}

resource "aws_security_group" "db_sg" {
  name   = format("rds-%s", local.name)
  vpc_id = module.vpc.vpc_id
}
resource "aws_security_group_rule" "db_inbound" {
  security_group_id = aws_security_group.db_sg.id
  type              = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  cidr_blocks       = [module.vpc.vpc_cidr_block]         # Add IP to allow connection to RDS: [module.vpc.vpc_cidr_block, x.x.x.x/32]
}

resource "aws_security_group_rule" "db_outbound" {
  security_group_id = aws_security_group.db_sg.id
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

output "db_instance_endpoint" {
  description = "The connection endpoint"
  value       = module.rds.db_instance_endpoint
}
