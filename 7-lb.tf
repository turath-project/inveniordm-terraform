resource "aws_security_group" "lb" {
  name        = format("lb-%s", local.name)
  description = "public HTTP and HTTPS"
  vpc_id      = module.vpc.vpc_id
}

resource "aws_security_group_rule" "lb_ingress_http" {
  type              = "ingress"
  security_group_id = aws_security_group.lb.id
  description       = "Allow HTTP access from the Internet"

  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}


resource "aws_security_group_rule" "lb_ingress_https" {
  type              = "ingress"
  security_group_id = aws_security_group.lb.id
  description       = "Allow HTTPS access from the Internet"

  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "lb_egress" {
  type              = "egress"
  security_group_id = aws_security_group.lb.id

  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_lb" "this" {
  name = format("%s-alb", local.name)

  load_balancer_type = "application"

  subnets         = module.vpc.public_subnets
  security_groups = [aws_security_group.lb.id]

  timeouts {
    create = "10m"
    delete = "10m"
    update = "10m"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn

  port     = 80
  protocol = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      status_code = "HTTP_301"
      port        = "443"
      protocol    = "HTTPS"
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn

  port            = 443
  protocol        = "HTTPS"
  certificate_arn   = module.acm_certificate.acm_certificate_arn
  ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      status_code  = "404"
      message_body = "Not Found"
    }
  }
}
