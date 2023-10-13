#----------------------------------------------#
# Network configuration
#----------------------------------------------#

# Fetched AZs in the current region
data "aws_availability_zones" "available" {}

# Defined VPC for the project
resource "aws_vpc" "main" {
  cidr_block           = "172.22.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name               = "ECS VPC",
    ManagedBy          = "terraform"
  }
}

# Created 2 private subnets, each in a different AZ
resource "aws_subnet" "ecs_private" {
  count             = 2
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  vpc_id            = aws_vpc.main.id

  tags = {
    Name              = "Private subnet",
    ManagedBy         = "terraform"
  }
}

# Created 2 public subnets, each in a different AZ
resource "aws_subnet" "ecs_public" {
  count                   = 2
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index + 2)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  vpc_id                  = aws_vpc.main.id
  map_public_ip_on_launch = true

  tags = {
    Name              = "Public subnet",
    ManagedBy         = "terraform"
  }
}

# Internet Gateway for the public subnets. Allows communication between our VPC and the internet
resource "aws_internet_gateway" "vpc_internet_gateway" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name              = "Internet gateway",
    ManagedBy         = "terraform"
  }
}

# Route the public subnet traffic through the IGW
resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.main.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.vpc_internet_gateway.id
}

# NAT gateway with an Elastic IP for each private subnet to get internet connectivity
resource "aws_nat_gateway" "gateway" {
  count         = 2
  subnet_id     = element(aws_subnet.ecs_public.*.id, count.index)
  allocation_id = element(aws_eip.gateway.*.id, count.index)

  tags = {
    Name             = "NAT gateway"
    ManagedBy        = "terraform"
  }
}

resource "aws_eip" "gateway" {
  count      = 2
  vpc        = true
  depends_on = [aws_internet_gateway.vpc_internet_gateway]

  tags = {
    Name              = "EIP for NAT gateway"
    ManagedBy         = "terraform"
  }
}

# Route table for the private subnets, make it route non-local traffic through the NAT gateway to the internet
resource "aws_route_table" "private" {
  count  = 2
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.gateway.*.id, count.index)
  }
}

# Explicitly associated the newly created route table to the private subnets
resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = element(aws_subnet.ecs_private.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
}
