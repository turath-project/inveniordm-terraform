data "aws_iam_policy_document" "minio" {
  statement {
    actions = [
      "kms:Decrypt"
    ]
    resources = [aws_kms_key.minio.arn]
  }

  statement {
    actions = [
      "ssm:GetParameters"
    ]
    resources = [for parameter in aws_ssm_parameter.minio : parameter.arn]
  }
}

resource "aws_iam_policy" "minio" {
  name   = format("%s-minio", local.name)
  policy = data.aws_iam_policy_document.minio.json
}


resource "aws_iam_role" "minio" {
  name               = format("%s-minio", local.name)
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json

  managed_policy_arns = [
    aws_iam_policy.minio.arn,
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  ]
}

resource "aws_cloudwatch_log_group" "minio" {
  name              = format("/%s/minio", local.name)
  retention_in_days = "7"
}

resource "aws_ecs_task_definition" "minio" {
  family = format("%s-minio", local.name)

  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"

  cpu    = 512
  memory = 1024

  task_role_arn      = aws_iam_role.minio.arn
  execution_role_arn = aws_iam_role.minio.arn

  container_definitions = jsonencode([
    {
      name  = "app"
      image = "quay.io/minio/minio"

      essential = true

      command   = [
        "server", "/data", "--console-address", ":9001"
      ]

      portMappings = [
        {
          containerPort = 9001
          hostPort      = 9001
          protocol      = "tcp"
        },
        {
          containerPort = 9000
          hostPort      = 9000
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.minio.name
          "awslogs-region"        = data.aws_region.this.name
          "awslogs-stream-prefix" = "ecs"
        }
      }

      secrets = [for k, v in aws_ssm_parameter.minio : { name : k, valueFrom : v["arn"] }]
    }
  ])
}

resource "aws_lb_target_group" "minio" {
  vpc_id = module.vpc.vpc_id
  name   = format("%s-minio", local.name)
  target_type = "ip"
  port        = 9001
  protocol    = "HTTP"
  deregistration_delay = "0"

  health_check {
    path     = "/"
    interval = 10
    matcher  = "200-499"
  }
}

resource "aws_lb_listener_rule" "minio" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.minio.arn
  }

  condition {
    host_header {
      values = [local.minio_domain]
    }
  }
}

resource "aws_ecs_service" "minio" {
  depends_on = [
    aws_lb_listener_rule.minio
  ]

  name = "minio"

  cluster         = module.ecs_cluster.ecs_cluster_id
  task_definition = aws_ecs_task_definition.minio.family

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
    target_group_arn = aws_lb_target_group.minio.arn
    container_name   = "app"
    container_port   = aws_lb_target_group.minio.port
  }

  lifecycle {
    ignore_changes = [
      task_definition,
      desired_count
    ]
  }
}

resource "aws_appautoscaling_target" "minio" {
  min_capacity       = 1
  max_capacity       = local.is_production ? 5 : 2
  resource_id        = format("service/%s/%s", module.ecs_cluster.ecs_cluster_name, aws_ecs_service.minio.name)
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "minio" {
  name               = "scale-service"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.minio.resource_id
  scalable_dimension = aws_appautoscaling_target.minio.scalable_dimension
  service_namespace  = aws_appautoscaling_target.minio.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value       = 75
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}
