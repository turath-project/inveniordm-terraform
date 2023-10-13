##-----------------------------------------------------------#
## RDS PostgreSQL configuration
##-----------------------------------------------------------#
#
## SG for PostgreSQL
#resource "aws_security_group" "rds_postgres" {
#  name        = "${var.project_name}-rds-sec-group"
#  description = "Security group of ${var.project_name}-rds"
#  vpc_id      = aws_vpc.main.id
#
#  # Allow access only from ECS cluster
#  ingress {
#    description     = "Access from workers"
#    from_port       = 5432
#    protocol        = "tcp"
#    to_port         = 5432
#    security_groups = [aws_security_group.ecs_task.id]
#  }
#
#  egress {
#    from_port   = 0
#    protocol    = "-1"
#    to_port     = 0
#    cidr_blocks = ["0.0.0.0/0"]
#  }
#
#  tags = {
#    Name      = "${var.project_name}-rds-sec-group"
#    ManagedBy = "terraform"
#  }
#}
#
## Subnet for PostgreSQL
#resource "aws_db_subnet_group" "postgres" {
#  name       = "${var.project_name}-database-subnet-group"
#  subnet_ids = aws_subnet.ecs_public.*.id
#
#  tags = {
#    Name      = "${var.project_name}-database-subnet-group"
#    ManagedBy = "terraform"
#  }
#}
#
## PostgreSQL configuration
#resource "aws_db_instance" "postgres" {
#  availability_zone                     = data.aws_availability_zones.available.names[0]
#  identifier                            = "${var.project_name}-db"
##  db_name                               = var.POSTGRES_DATABASE_NAME
##  username                              = var.POSTGRES_DATABASE_USERNAME
#  db_name                               = "test_db"
#  username                              = "db_admin"
#  password                              = "qwerty123"
#  allocated_storage                     = 20
#  storage_type                          = "gp2"
#  storage_encrypted                     = true
#  engine                                = "postgres"
#  engine_version                        = "15.2"
#  instance_class                        = var.postgres_instance
#  backup_retention_period               = "7"
#  deletion_protection                   = false
#  db_subnet_group_name                  = aws_db_subnet_group.postgres.name
#  vpc_security_group_ids                = [aws_security_group.rds_postgres.id]
#  maintenance_window                    = "wed:02:15-wed:02:45"
#  publicly_accessible                   = false
#  iam_database_authentication_enabled   = false
#  performance_insights_enabled          = true
#  performance_insights_retention_period = 7
#  auto_minor_version_upgrade            = false
#  skip_final_snapshot                   = true
#  tags = {
#
#    Name      = "${var.project_name}-postgres"
#    ManagedBy = "terraform"
#  }
#}
