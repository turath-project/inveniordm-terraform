resource "aws_mq_broker" "rabbit-mq" {
  broker_name                = "rabbitmq-broker"
  apply_immediately          = false
  deployment_mode            = var.mq.deploy_mode
  engine_type                = var.mq.engine_type
  engine_version             = var.mq.engine_ver
  host_instance_type         = var.mq.instance_type
  publicly_accessible        = var.mq.pub_accessible
  security_groups            = [aws_security_group.rabbitmq_sg_nodes.id]
#  subnet_ids                 = module.vpc.private_subnets
  subnet_ids                 = local.is_production ? module.vpc.private_subnets : [module.vpc.private_subnets.0]
  tags                       = {}

  #  encryption_options {
  #    use_aws_owned_key = true
  #  }

  logs {
    general = true
  }

  maintenance_window_start_time {
    day_of_week = "TUESDAY"
    time_of_day = "17:00"
    time_zone   = "UTC"
  }

  user {
    username = var.mq.username
    password = var.mq.password
  }
}

resource "aws_security_group" "rabbitmq_sg_nodes" {
  name        = "mq-sg-nodes"
  vpc_id      = module.vpc.vpc_id
  description = "Security Group for the rabbitmq nodes"
  depends_on = [
    module.vpc.vpc_id
  ]

  ingress {
    cidr_blocks = [
      local.vpc_cidr
    ]
    from_port        = 0
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "-1"
    security_groups  = []
    self             = false
    to_port          = 0
  }

  egress {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
    self      = "true"
  }

  tags = {
    Name = "rabbitmq sg nodes"
  }
}

output "mq_broker_ssl_endpoint" {
  value = aws_mq_broker.rabbit-mq.instances.0.endpoints.0
}
