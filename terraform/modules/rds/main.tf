# ─────────────────────────────────────────
# RDS Subnet Group
# ─────────────────────────────────────────

resource "aws_db_subnet_group" "main" {
  name        = "${var.project_name}-${var.environment}-db-subnet-group"
  description = "Subnet group for RDS database"

  # RDS needs to know which subnets it can use
  # we pass our private subnets here
  # AWS will place the database in one of these subnets
  # and use the other for standby if needed
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${var.project_name}-${var.environment}-db-subnet-group"
  }
}

# ─────────────────────────────────────────
# RDS Instance
# ─────────────────────────────────────────

resource "aws_db_instance" "main" {
  # a unique identifier for this RDS instance
  identifier = "${var.project_name}-${var.environment}-db"
  # result: "budget-tracker-production-db"

  # ── Database Engine ──
  engine         = "postgres"
  engine_version = "15"
  # PostgreSQL version 15.4
  # a stable, modern version of PostgreSQL

  # ── Instance Size ──
  instance_class = var.db_instance_class
  # db.t3.micro → smallest instance
  # eligible for AWS free tier
  # 1 vCPU, 1GB RAM

  # ── Storage ──
  allocated_storage     = 20
  max_allocated_storage = 100
  # start with 20GB
  # AWS will automatically scale up to 100GB if needed
  # this is called storage autoscaling
  storage_type          = "gp2"
  # gp2 = general purpose SSD
  # good balance of performance and cost

  # ── Database Details ──
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password
  # these come from terraform.tfvars
  # password is marked sensitive so never printed

  # ── Networking ──
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.rds_sg_id]
  publicly_accessible    = false
  # publicly_accessible = false is critical
  # database is only reachable from inside the VPC
  # specifically only from ECS via security group rules

  # ── Backups ──
  backup_retention_period = 7
  # keep 7 days of automatic backups
  # if something goes wrong you can restore
  # to any point in the last 7 days
  backup_window = "03:00-04:00"
  # run backups between 3am-4am Sydney time
  # low traffic period, minimal impact

  # ── Maintenance ──
  maintenance_window = "Mon:04:00-Mon:05:00"
  # AWS applies updates Monday 4-5am Sydney time
  # right after backup window
  # again low traffic period

  # ── Availability ──
  multi_az = false
  # multi_az = true would create a standby database
  # in a second availability zone for high availability
  # we set false to keep costs down while learning
  # in real production this would be true

  # ── Protection ──
  deletion_protection = false
  # deletion_protection = true prevents accidental deletion
  # we set false so we can easily destroy resources
  # while learning and experimenting
  # in real production this would be true

  # skip final snapshot when destroying
  # normally RDS takes a final backup before deletion
  # we skip this to make terraform destroy faster
  # in real production set this to false
  skip_final_snapshot = true

  tags = {
    Name = "${var.project_name}-${var.environment}-db"
  }
}