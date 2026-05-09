# ─────────────────────────────────────────
# VPC
# ─────────────────────────────────────────

resource "aws_vpc" "main" {
  # The IP range for our entire VPC
  cidr_block = var.vpc_cidr

  # enable_dns_hostnames allows AWS to assign
  # human readable DNS names to our resources
  # e.g. ip-10-0-1-5.ap-southeast-2.compute.internal
  # ECS and RDS need this to find each other by name
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-${var.environment}-vpc"
    # the ${} syntax is string interpolation
    # it inserts the variable value into the string
    # result: "budget-tracker-production-vpc"
    # you'll see this pattern everywhere in our code
  }
}

# ─────────────────────────────────────────
# Internet Gateway
# ─────────────────────────────────────────

resource "aws_internet_gateway" "main" {
  # attach the internet gateway to our VPC
  vpc_id = aws_vpc.main.id
  # aws_vpc.main.id means:
  # resource type → aws_vpc
  # resource name → main (what we named it above)
  # attribute     → id (the id AWS assigns after creation)
  # this is how Terraform resources reference each other

  tags = {
    Name = "${var.project_name}-${var.environment}-igw"
    # result: "budget-tracker-production-igw"
  }
}

# ─────────────────────────────────────────
# Public Subnets
# ─────────────────────────────────────────

resource "aws_subnet" "public" {
  # count tells Terraform how many of this resource to create
  # length(var.public_subnet_cidrs) = 2 (we have two CIDRs)
  # so Terraform creates two public subnets automatically
  count = length(var.public_subnet_cidrs)

  vpc_id = aws_vpc.main.id

  # count.index is the current iteration number (0, 1, 2...)
  # first loop  → count.index = 0 → "10.0.1.0/24"
  # second loop → count.index = 1 → "10.0.2.0/24"
  cidr_block = var.public_subnet_cidrs[count.index]

  # place each subnet in a different availability zone
  # first subnet  → ap-southeast-2a
  # second subnet → ap-southeast-2b
  availability_zone = var.availability_zones[count.index]

  # automatically assign public IP to anything launched here
  # the load balancer needs a public IP to receive internet traffic
  map_public_ip_on_launch = true

  tags = {
    # count.index + 1 because we want 1,2 not 0,1
    Name = "${var.project_name}-${var.environment}-public-subnet-${count.index + 1}"
    # result: "budget-tracker-production-public-subnet-1"
    #         "budget-tracker-production-public-subnet-2"
  }
}

# ─────────────────────────────────────────
# Private Subnets
# ─────────────────────────────────────────

resource "aws_subnet" "private" {
  # same pattern as public subnets
  # creates two private subnets
  count = length(var.private_subnet_cidrs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  # private subnets do NOT get public IPs
  # nothing in here is directly reachable from internet
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-${var.environment}-private-subnet-${count.index + 1}"
    # result: "budget-tracker-production-private-subnet-1"
    #         "budget-tracker-production-private-subnet-2"
  }
}

# ─────────────────────────────────────────
# NAT Gateway
# ─────────────────────────────────────────

# NAT Gateway needs an Elastic IP (a fixed public IP address)
resource "aws_eip" "nat" {
  # domain = "vpc" tells AWS this IP is for use inside a VPC
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-${var.environment}-nat-eip"
  }
}

resource "aws_nat_gateway" "main" {
  # attach the elastic IP to the NAT gateway
  allocation_id = aws_eip.nat.id

  # NAT gateway lives in the FIRST public subnet
  # [0] means first item in the list
  subnet_id = aws_subnet.public[0].id

  tags = {
    Name = "${var.project_name}-${var.environment}-nat"
  }

  # NAT gateway needs the internet gateway to exist first
  # depends_on makes sure Terraform creates IGW before NAT
  depends_on = [aws_internet_gateway.main]
}

# ─────────────────────────────────────────
# Route Tables
# ─────────────────────────────────────────

# Route table for PUBLIC subnets
# tells public subnet traffic where to go
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    # 0.0.0.0/0 means "all internet traffic"
    cidr_block = "0.0.0.0/0"
    # send all internet traffic through the internet gateway
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-public-rt"
  }
}

# Route table for PRIVATE subnets
# tells private subnet traffic where to go
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    # all outbound traffic from private subnets
    cidr_block = "0.0.0.0/0"
    # goes through NAT gateway (not internet gateway)
    # NAT translates private IP to public IP for outbound only
    # inbound connections from internet are blocked
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-private-rt"
  }
}

# Associate public route table with public subnets
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
  # this links each public subnet to the public route table
  # without this, subnets don't know which route table to use
}

# Associate private route table with private subnets
resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}