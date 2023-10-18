moved {
  from = module.redis.aws_elasticache_replication_group.default[0]
  to   = aws_elasticache_replication_group.this
}

resource "aws_security_group" "elasticache" {
  name        = format("elasticache-%s", local.name)
  description = "internal ElastiCache Redis"
  vpc_id      = module.vpc.vpc_id
}

resource "aws_security_group_rule" "elasticache_ingress_ecs" {
  type              = "ingress"
  security_group_id = aws_security_group.elasticache.id
  description       = "Allow Redis access from the backend application"

  from_port                = 6379
  to_port                  = 6379
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ecs.id
}

resource "aws_elasticache_replication_group" "this" {
  replication_group_id = local.name
  description          = local.name
  engine               = "redis"
  engine_version       = var.redis.engine_version
  node_type            = local.is_production ? var.redis.node_type_prod : var.redis.node_type

  num_cache_clusters = local.is_production ? 2 : 1

  subnet_group_name  = module.vpc.elasticache_subnet_group_name
  security_group_ids = [aws_security_group.elasticache.id]

  multi_az_enabled           = local.is_production
  automatic_failover_enabled = local.is_production
  at_rest_encryption_enabled = true
  transit_encryption_enabled = false

  maintenance_window = "wed:04:00-wed:05:00"
}

output "elasticache_replication_group_primary_endpoint_address" {
  value       = aws_elasticache_replication_group.this.primary_endpoint_address
  description = "The address of the endpoint for the primary node in the replication group."
}