#data "aws_iam_policy_document" "backend" {
#  statement {
#    actions = [
#      "kms:Decrypt"
#    ]
#    resources = [aws_kms_key.backend.arn]
#  }
#
#  statement {
#    actions = [
#      "ssm:GetParameters"
#    ]
#    resources = [for parameter in aws_ssm_parameter.backend : parameter.arn]
#  }
#}

#resource "aws_iam_policy" "backend" {
#  name   = format("%s-backend", local.name)
#  policy = data.aws_iam_policy_document.backend.json
#}
#
#
#resource "aws_iam_role" "backend" {
#  name               = format("%s-backend", local.name)
#  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
#
#  managed_policy_arns = [
#    aws_iam_policy.backend.arn,
#    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
#  ]
#}
#
#resource "aws_cloudwatch_log_group" "backend" {
#  name              = format("/%s/backend", local.name)
#  retention_in_days = "7"
#}

resource "aws_ecs_task_definition" "backend" {
  family = format("%s-backend", local.name)

  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"

  cpu    = 512
  memory = 1024

#  task_role_arn      = aws_iam_role.backend.arn
  execution_role_arn = aws_iam_role.ecs_tasks_role.arn

  container_definitions = jsonencode([
    {
      name  = "app"
      image = format("%s:latest", aws_ecr_repository.backend.repository_url)

      essential = true

      portMappings = [
        {
          containerPort = 5000
          hostPort      = 5000
          protocol      = "tcp"
        }
      ]

#      logConfiguration = {
#        logDriver = "awslogs"
#        options = {
#          "awslogs-group"         = aws_cloudwatch_log_group.backend.name
#          "awslogs-region"        = data.aws_region.this.name
#          "awslogs-stream-prefix" = "ecs"
#        }
#      }

#      secrets = [for k, v in aws_ssm_parameter.backend : { name : k, valueFrom : v["arn"] }]
    }
  ])
}

#_____________________________
# ECS service
resource "aws_ecs_service" "project_service" {
  name            = "backend"
  cluster         = aws_ecs_cluster.project_ecs.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = var.ecs_service_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups = [aws_security_group.ecs_task.id]
    subnets         = aws_subnet.ecs_private.*.id
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.project_target_group.id
    container_name   = "${var.app_container_name}"
    container_port   = 5000
  }

  depends_on = [aws_alb_listener.project_listener]

  tags = {
    Name      = "ECS service"
    ManagedBy = "terraform"
  }
}

# ECS service autoscaling
resource "aws_appautoscaling_target" "ecs_scale_target" {
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.project_ecs.name}/${aws_ecs_service.project_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  max_capacity       = var.ecs_autoscale_max
  min_capacity       = var.ecs_autoscale_min
}

#______________________________________________________

resource "aws_ecr_repository" "backend" {
  name                 = format("%s-backend", local.name)
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }
}

#resource "aws_lb_target_group" "backend" {
#  vpc_id = module.vpc.vpc_id
#  name   = format("%s-backend", local.name)
#
#  target_type = "ip"
#  port        = 5000
#  protocol    = "HTTP"
#
#  deregistration_delay = "0"
#
#}
#
#resource "aws_lb_listener_rule" "backend" {
#  listener_arn = aws_lb_listener.https.arn
#
#  action {
#    type             = "forward"
#    target_group_arn = aws_lb_target_group.backend.arn
#  }
#
#  condition {
#    host_header {
#      values = [local.backend_domain]
#    }
#  }
#}
#
#resource "aws_ecs_service" "backend" {
#  depends_on = [
#    aws_lb_listener_rule.backend
#  ]
#
#  name = "backend"
#
#  cluster         = aws_ecs_cluster.project_ecs.id
#  task_definition = aws_ecs_task_definition.project_task.arn
#
#  #  launch_type   = "FARGATE"
#  desired_count = 1
#
#  deployment_maximum_percent         = 200
#  deployment_minimum_healthy_percent = 100
#
#  enable_execute_command = true
#
#  capacity_provider_strategy {
#    capacity_provider = local.is_production ? "FARGATE" : "FARGATE_SPOT"
#    weight            = 100
#  }
#
#  network_configuration {
#    subnets         = module.vpc.private_subnets
#    security_groups = [aws_security_group.ecs.id]
#  }
#
#  load_balancer {
#    target_group_arn = aws_lb_target_group.backend.arn
#    container_name   = "app"
#    container_port   = aws_lb_target_group.backend.port
#  }
#
#  lifecycle {
#    ignore_changes = [
#      task_definition,
#      desired_count
#    ]
#  }
#}
#
#resource "aws_appautoscaling_target" "backend" {
#  min_capacity       = 1
#  max_capacity       = local.is_production ? 5 : 2
#  resource_id        = format("service/%s/%s", module.ecs_cluster.ecs_cluster_name, aws_ecs_service.backend.name)
#  scalable_dimension = "ecs:service:DesiredCount"
#  service_namespace  = "ecs"
#}
#
#resource "aws_appautoscaling_policy" "backend" {
#  name               = "scale-service"
#  policy_type        = "TargetTrackingScaling"
#  resource_id        = aws_appautoscaling_target.backend.resource_id
#  scalable_dimension = aws_appautoscaling_target.backend.scalable_dimension
#  service_namespace  = aws_appautoscaling_target.backend.service_namespace
#
#  target_tracking_scaling_policy_configuration {
#    predefined_metric_specification {
#      predefined_metric_type = "ECSServiceAverageCPUUtilization"
#    }
#
#    target_value       = 75
#    scale_in_cooldown  = 300
#    scale_out_cooldown = 300
#  }
#}
