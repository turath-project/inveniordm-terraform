data "aws_iam_policy_document" "pgadmin" {
  statement {
    actions = [
      "kms:Decrypt"
    ]
    resources = [aws_kms_key.pgadmin.arn]
  }

  statement {
    actions = [
      "ssm:GetParameters"
    ]
    resources = [for parameter in aws_ssm_parameter.pgadmin : parameter.arn]
  }
}

resource "aws_iam_policy" "pgadmin" {
  name   = format("%s-pgadmin", local.name)
  policy = data.aws_iam_policy_document.pgadmin.json
}


resource "aws_iam_role" "pgadmin" {
  name               = format("%s-pgadmin", local.name)
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json

  managed_policy_arns = [
    aws_iam_policy.pgadmin.arn,
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  ]
}

resource "aws_cloudwatch_log_group" "pgadmin" {
  name              = format("/%s/pgadmin", local.name)
  retention_in_days = "7"
}

#resource "aws_ecr_repository" "pgadmin" {
#  name                 = format("%s-pgadmin", local.name)
#  image_tag_mutability = "MUTABLE"
#
#  image_scanning_configuration {
#    scan_on_push = false
#  }
#}

resource "aws_ecs_task_definition" "pgadmin" {
  family = format("%s-pgadmin", local.name)

  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"

  cpu    = 512
  memory = 1024

  task_role_arn      = aws_iam_role.pgadmin.arn
  execution_role_arn = aws_iam_role.pgadmin.arn

  container_definitions = jsonencode([
    {
      name  = "app"
      image = "dpage/pgadmin4"
      essential = true

      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.pgadmin.name
          "awslogs-region"        = data.aws_region.this.name
          "awslogs-stream-prefix" = "ecs"
        }
      }

      secrets = [for k, v in aws_ssm_parameter.pgadmin : { name : k, valueFrom : v["arn"] }]
    }
  ])
}

resource "aws_lb_target_group" "pgadmin" {
  vpc_id = module.vpc.vpc_id
  name   = format("%s-pgadmin", local.name)
  target_type = "ip"
  port        = 80
  protocol    = "HTTP"
  deregistration_delay = "0"

  health_check {
    path     = "/"
    interval = 10
    matcher  = "200-499"
  }
}

resource "aws_lb_listener_rule" "pgadmin" {
  listener_arn = aws_lb_listener.https.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.pgadmin.arn
  }

  condition {
    host_header {
      values = [local.pgadmin_domain]
    }
  }
}

resource "aws_ecs_service" "pgadmin" {
  depends_on = [
    aws_lb_listener_rule.pgadmin
  ]

  name = "pgadmin"

  cluster         = module.ecs_cluster.ecs_cluster_id
  task_definition = aws_ecs_task_definition.pgadmin.family

  #  launch_type   = "FARGATE"
  desired_count = 1

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  enable_execute_command = true

  capacity_provider_strategy {
    capacity_provider = local.is_production ? "FARGATE" : "FARGATE_SPOT"
    weight            = 100
  }

  network_configuration {
    subnets         = module.vpc.private_subnets
    security_groups = [aws_security_group.ecs.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.pgadmin.arn
    container_name   = "app"
    container_port   = aws_lb_target_group.pgadmin.port
  }

  lifecycle {
    ignore_changes = [
      task_definition,
      desired_count
    ]
  }
}

resource "aws_appautoscaling_target" "pgadmin" {
  min_capacity       = 1
  max_capacity       = local.is_production ? 5 : 2
  resource_id        = format("service/%s/%s", module.ecs_cluster.ecs_cluster_name, aws_ecs_service.pgadmin.name)
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "pgadmin" {
  name               = "scale-service"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.pgadmin.resource_id
  scalable_dimension = aws_appautoscaling_target.pgadmin.scalable_dimension
  service_namespace  = aws_appautoscaling_target.pgadmin.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value       = 75
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}
