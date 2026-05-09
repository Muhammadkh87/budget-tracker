# ─────────────────────────────────────────
# ALB Security Group
# Controls traffic to the Load Balancer
# ─────────────────────────────────────────

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-${var.environment}-alb-sg"
  description = "Security group for the Application Load Balancer"
  vpc_id      = var.vpc_id

  # INBOUND RULES
  # allow HTTP traffic from anywhere on the internet
  ingress {
    description = "Allow HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    # 0.0.0.0/0 means allow from ANY IP address
    # this is fine for the load balancer
    # it's meant to be public facing
  }

  # OUTBOUND RULES
  # allow all outbound traffic
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    # protocol -1 means ALL protocols
    # from_port and to_port 0 means ALL ports
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-alb-sg"
  }
}

# ─────────────────────────────────────────
# ECS Security Group
# Controls traffic to our containers
# ─────────────────────────────────────────

resource "aws_security_group" "ecs" {
  name        = "${var.project_name}-${var.environment}-ecs-sg"
  description = "Security group for ECS tasks"
  vpc_id      = var.vpc_id

  # INBOUND RULES
  # only allow traffic FROM the ALB security group
  # NOT from the internet directly
  ingress {
    description     = "Allow traffic from ALB only"
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    # instead of cidr_blocks we use security_groups
    # this means ONLY traffic coming from the ALB
    # is allowed into ECS — nothing else
    security_groups = [aws_security_group.alb.id]
  }

  # OUTBOUND RULES
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    # ECS needs outbound access to:
    # → pull Docker images from ECR
    # → connect to RDS database
    # → call external APIs if needed
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-ecs-sg"
  }
}

# ─────────────────────────────────────────
# RDS Security Group
# Controls traffic to our database
# ─────────────────────────────────────────

resource "aws_security_group" "rds" {
  name        = "${var.project_name}-${var.environment}-rds-sg"
  description = "Security group for RDS database"
  vpc_id      = var.vpc_id

  # INBOUND RULES
  # only allow PostgreSQL traffic FROM ECS security group
  # database is completely hidden from internet
  ingress {
    description     = "Allow PostgreSQL from ECS only"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    # 5432 is the default PostgreSQL port
    # only ECS containers can reach the database
    security_groups = [aws_security_group.ecs.id]
  }

  # OUTBOUND RULES
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-rds-sg"
  }
}