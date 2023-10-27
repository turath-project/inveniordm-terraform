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

#  ingress {
#    protocol  = -1
#    from_port = 0
#    to_port   = 0
#    self      = true
#  }

#  ingress {
#    protocol        = "tcp"
#    from_port       = 5672
#    to_port         = 5672
#    security_groups = [aws_security_group.rabbitmq_sg_elb.id]
#  }

#  ingress {
#    protocol        = "tcp"
#    from_port       = 15672
#    to_port         = 15672
#    security_groups = [aws_security_group.rabbitmq_sg_elb.id]
#  }

  ingress {
    cidr_blocks = [
      local.vpc_cidr
      #      "0.0.0.0/0",
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

#  egress {
#    protocol  = "-1"
#    from_port = 0
#    to_port   = 0
#
#    cidr_blocks = [
#      "0.0.0.0/0",
#    ]
#  }

  tags = {
    Name = "rabbitmq sg nodes"
  }
}

#resource "aws_security_group" "rabbitmq_sg_elb" {
#  name        = "rabbitmq_elb-sg"
#  vpc_id      = module.vpc.vpc_id
#  description = "Security Group for the rabbitmq elb"
#
#  ingress {
#    protocol        = "tcp"
#    from_port       = 443
#    to_port         = 443
#    security_groups = [aws_security_group.rabbitmq_sg_nodes.id]
#  }
#
#  egress {
#    protocol    = "-1"
#    from_port   = 0
#    to_port     = 0
#    cidr_blocks = ["0.0.0.0/0"]
#  }
#
#  tags = {
#    Name = "rabbitmq sg ELB"
#  }
#}
#
#resource "aws_elb" "mq_elb" {
#  name = "mq-elb"
#
#  listener {
#    instance_port     = 443
#    instance_protocol = "tcp"
#    lb_port           = 443
#    lb_protocol       = "tcp"
#  }
#
##  listener {
##    instance_port     = 15672
##    instance_protocol = "http"
##    lb_port           = 80
##    lb_protocol       = "http"
##  }
#
#  health_check {
#    interval            = 30
#    unhealthy_threshold = 10
#    healthy_threshold   = 2
#    timeout             = 3
#    target              = "TCP:443"
#  }
#
#  subnets         = flatten(module.vpc.public_subnets)
#  idle_timeout    = 3600
#  internal        = true
#  security_groups = [aws_security_group.rabbitmq_sg_elb.id]
#
#  tags = {
#    Name = "mq_elb"
#  }
#}

output "mq_broker_ssl_endpoint" {
  value = aws_mq_broker.rabbit-mq.instances.0.endpoints.0
}
