module "ecs_cluster" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "~> 3.5.0"

  name       = format("%s-cluster", local.name)
  create_ecs = true

  container_insights = true

  capacity_providers = local.is_production ? ["FARGATE"] : ["FARGATE", "FARGATE_SPOT"]
  default_capacity_provider_strategy = [
    {
      capacity_provider = local.is_production ? "FARGATE" : "FARGATE_SPOT"
    }
  ]
}


resource "aws_security_group" "ecs" {
  name        = format("ecs-%s", local.name)
  description = "internal HTTP"
  vpc_id      = module.vpc.vpc_id
}

resource "aws_security_group_rule" "ecs_ingress_lb" {
  type              = "ingress"
  security_group_id = aws_security_group.ecs.id
  description       = "Allow HTTP access from the Load Balancer"

  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.lb.id
}

resource "aws_security_group_rule" "ecs_egress" {
  type              = "egress"
  security_group_id = aws_security_group.ecs.id

  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

data "aws_iam_policy_document" "ecs_task_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}
