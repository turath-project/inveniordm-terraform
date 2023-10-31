resource "aws_security_group" "es" {
  name = "${local.common_prefix}-es-sg"
  description = "Allow inbound traffic to ElasticSearch from VPC CIDR"
  vpc_id      = module.vpc.vpc_id
  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      module.vpc.vpc_cidr_block
    ]
  }
}

resource "aws_iam_service_linked_role" "es" {
  aws_service_name = "es.amazonaws.com"
}

resource "aws_elasticsearch_domain" "es" {
  domain_name = local.elk_domain
  elasticsearch_version = var.elk.es_version

  cluster_config {
    instance_count = var.elk.instance_count
    instance_type = var.elk.instance_type
    zone_awareness_enabled = false

#  zone_awareness_config {
#    availability_zone_count = var.elk.zone_count
#  }

  }

  auto_tune_options {
    desired_state       = var.elk.elk_autotune
    rollback_on_disable = "NO_ROLLBACK"
  }

  vpc_options {
#    subnet_ids = flatten(module.vpc.private_subnets)         # Only if you need more than 1 instance and 1 av_zone
    subnet_ids = [module.vpc.private_subnets.0]
    security_group_ids = [
      aws_security_group.es.id
    ]
  }

  ebs_options {
    ebs_enabled = true
    volume_size = 10
  }
  access_policies = <<CONFIG
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Action": "es:*",
          "Principal": "*",
          "Effect": "Allow",
          "Resource": "arn:aws:es:${data.aws_region.this.name}:${data.aws_caller_identity.this.account_id}:domain/${local.elk_domain}/*"
      }
  ]
}
  CONFIG

  snapshot_options {
    automated_snapshot_start_hour = 23
  }
  tags = {
    Domain = local.elk_domain
  }
}

output "elk_endpoint" {
  value = aws_elasticsearch_domain.es.endpoint
}

output "elk_kibana_endpoint" {
  value = aws_elasticsearch_domain.es.kibana_endpoint
}