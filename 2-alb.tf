#---------------------------------------------#
# ALB, target group & listeners
#---------------------------------------------#

# Application Load Balancer
resource "aws_alb" "application_lb" {
  name               = "load-balancer"
  load_balancer_type = "application"
  subnets            = aws_subnet.ecs_public.*.id
  security_groups    = [aws_security_group.lb_sg.id]

  access_logs {
    enabled = true
    prefix  = "logs"
    bucket  = aws_s3_bucket.alb_access_logs.bucket
  }

  tags = {
    Name       =   "Application LB"
    ManagedBy  =   "terraform"
  }
}

# Defined target group for the ALB
resource "aws_alb_target_group" "project_target_group" {
  name        = "project-target-group"
  port        = 5000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200-399"
    timeout             = "3"
    path                = "/api"
    unhealthy_threshold = "2"
  }
}

# Redirected all HTTP traffic from the ALB to the target group
resource "aws_alb_listener" "project_listener" {
  load_balancer_arn = aws_alb.application_lb.id
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.project_target_group.id
    type             = "forward"
  }
}

# Redirected all HTTPS traffic from the ALB to the target group
resource "aws_alb_listener" "project_listener_https" {
  load_balancer_arn = aws_alb.application_lb.id
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate_validation.example.certificate_arn

  default_action {
    target_group_arn = aws_alb_target_group.project_target_group.id
    type             = "forward"
  }
}
