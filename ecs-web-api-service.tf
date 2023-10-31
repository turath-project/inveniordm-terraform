data "aws_iam_policy_document" "web-api" {
  statement {
    actions = [
      "kms:Decrypt"
    ]
    resources = [aws_kms_key.backend.arn]
  }

  statement {
    actions = [
      "ssm:GetParameters"
    ]
    resources = [for parameter in aws_ssm_parameter.backend : parameter.arn]
  }
}

resource "aws_iam_policy" "web-api" {
  name   = format("%s-web-api", local.name)
  policy = data.aws_iam_policy_document.web-api.json
}


resource "aws_iam_role" "web-api" {
  name               = format("%s-web-api", local.name)
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json

  managed_policy_arns = [
    aws_iam_policy.web-api.arn,
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  ]
}

resource "aws_cloudwatch_log_group" "web-api" {
  name              = format("/%s/web-api", local.name)
  retention_in_days = "7"
}

resource "aws_ecr_repository" "invenio-ecr" {                  # this ECR used for web-ui, web-api and celery services
  name                 = format("%s-app", local.name)
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }
}

resource "aws_ecs_task_definition" "web-api" {
  family = format("%s-web-api", local.name)

  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"

  cpu    = 1024
  memory = 2048

  task_role_arn      = aws_iam_role.web-api.arn
  execution_role_arn = aws_iam_role.web-api.arn

  container_definitions = jsonencode([
    {
      name  = "app"
      image = format("%s:latest", aws_ecr_repository.invenio-ecr.repository_url)

      essential = true

      environment = [

      ]

      entryPoint: [
          "sh",
          "-c"
      ],
      command: [
          "/bin/sh -c \"invenio db init create && invenio roles create admin && invenio access allow superuser-access role admin && invenio index init && invenio rdm-records demo && invenio rdm-records fixtures && uwsgi /opt/invenio/var/instance/uwsgi_rest.ini\""
      ],

#      command   = [
#        "sleep", "infinity"
#      ]

      portMappings = [
        {
          containerPort = 5000
          hostPort      = 5000
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.web-api.name
          "awslogs-region"        = data.aws_region.this.name
          "awslogs-stream-prefix" = "ecs"
        }
      }

      secrets = [for k, v in aws_ssm_parameter.backend : { name : k, valueFrom : v["arn"] }]
    }
  ])
}

resource "aws_lb_target_group" "web-api" {
  vpc_id = module.vpc.vpc_id
  name   = format("%s-web-api", local.name)
  target_type = "ip"
  port        = 5000
  protocol    = "HTTP"
  deregistration_delay = "0"

  health_check {
    path     = "/"
    interval = 10
    matcher  = "200-499"
  }
}

resource "aws_lb_listener_rule" "web-api" {
 listener_arn = aws_lb_listener.https.arn
 priority     = 4

 action {
   type             = "forward"
   target_group_arn = aws_lb_target_group.web-api.arn
 }

 condition {
   path_pattern {
     values = ["/api/*"]
   }
 }
}

resource "aws_ecs_service" "web-api" {
#  depends_on = [
#    aws_lb_listener_rule.web-api
#  ]

  name = "web-api"

  cluster         = module.ecs_cluster.ecs_cluster_id
  task_definition = aws_ecs_task_definition.web-api.family

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
    target_group_arn = aws_lb_target_group.web-api.arn
    container_name   = "app"
    container_port   = aws_lb_target_group.web-api.port
  }

  lifecycle {
    ignore_changes = [
      task_definition,
      desired_count
    ]
  }
}

resource "aws_appautoscaling_target" "web-api" {
  min_capacity       = 1
  max_capacity       = local.is_production ? 5 : 2
  resource_id        = format("service/%s/%s", module.ecs_cluster.ecs_cluster_name, aws_ecs_service.web-api.name)
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "web-api" {
  name               = "scale-service"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.web-api.resource_id
  scalable_dimension = aws_appautoscaling_target.web-api.scalable_dimension
  service_namespace  = aws_appautoscaling_target.web-api.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value       = 75
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}
