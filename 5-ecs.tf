#----------------------------------------------#
# General ECS configuration
#----------------------------------------------#

# ECS cluster
resource "aws_ecs_cluster" "project_ecs" {
  name = var.project_name

  tags = {
    Name      = "ECS cluster"
    ManagedBy = "terraform"
  }
}

## ECS service
#resource "aws_ecs_service" "project_service" {
#  name            = "ecs-service"
#  cluster         = aws_ecs_cluster.project_ecs.id
#  task_definition = aws_ecs_task_definition.project_task.arn
#  desired_count   = var.ecs_service_count
#  launch_type     = "FARGATE"
#
#  network_configuration {
#    security_groups = [aws_security_group.ecs_task.id]
#    subnets         = aws_subnet.ecs_private.*.id
#  }
#
#  load_balancer {
#    target_group_arn = aws_alb_target_group.project_target_group.id
#    container_name   = "${var.app_container_name}"
#    container_port   = 5000
#  }
#
#  depends_on = [aws_alb_listener.project_listener]
#
#  tags = {
#    Name      = "ECS service"
#    ManagedBy = "terraform"
#  }
#}

## ECS service autoscaling
#resource "aws_appautoscaling_target" "ecs_scale_target" {
#  service_namespace  = "ecs"
#  resource_id        = "service/${aws_ecs_cluster.project_ecs.name}/${aws_ecs_service.project_service.name}"
#  scalable_dimension = "ecs:service:DesiredCount"
#  max_capacity       = var.ecs_autoscale_max
#  min_capacity       = var.ecs_autoscale_min
#}

## ECR Respository in AWS for backend image
#resource "aws_ecr_repository" "app" {
#  name = var.ecr_repo
#}
