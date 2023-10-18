module "vpc" {
  source                 = "terraform-aws-modules/vpc/aws"
  version                = "4.0.1"
  name                    = format("%s-vpc", local.name)
  cidr                   = var.vpc.cidr
  azs                    = local.azs
  private_subnets        = ["${var.vpc.private_subnet1}", "${var.vpc.private_subnet2}", "${var.vpc.private_subnet3}"]
  public_subnets         = ["${var.vpc.public_subnet1}", "${var.vpc.public_subnet2}", "${var.vpc.public_subnet3}"]
  database_subnets       = ["${var.vpc.database_subnet1}", "${var.vpc.database_subnet2}", "${var.vpc.database_subnet3}"]
  elasticache_subnets = [for i, _ in local.azs : cidrsubnet(local.vpc_cidr, 8, local.is_production ? 10 + i : 50 + i)]
  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false
  reuse_nat_ips          = false
  create_database_subnet_group           = true
  create_database_subnet_route_table     = true
  create_database_internet_gateway_route = true


  public_subnet_tags = {
    Tier = "public"
  }

  private_subnet_tags = {
    Tier = "private"
  }

  database_subnet_tags = {
    Tier = "database"
  }

  elasticache_subnet_tags = {
    Tier = "elasticache"
  }
}
