# ─────────────────────────────────────────
# ECS Cluster
# ─────────────────────────────────────────

resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-${var.environment}-cluster"
  # result: "budget-tracker-production-cluster"

  # Container Insights enables detailed monitoring
  # CPU, memory, network metrics per container
  # visible in CloudWatch dashboard
  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-cluster"
  }
}

# ─────────────────────────────────────────
# CloudWatch Log Group
# ─────────────────────────────────────────

resource "aws_cloudwatch_log_group" "main" {
  name              = "/ecs/${var.project_name}-${var.environment}"
  # result: "/ecs/budget-tracker-production"
  # this is where your container logs will appear
  # console.log() in your Node.js app goes here!

  retention_in_days = 30
  # keep logs for 30 days then automatically delete
  # prevents log storage costs from growing forever

  tags = {
    Name = "${var.project_name}-${var.environment}-logs"
  }
}

# ─────────────────────────────────────────
# ECS Task Definition
# ─────────────────────────────────────────

resource "aws_ecs_task_definition" "main" {
  family = "${var.project_name}-${var.environment}"
  # family is like a name for this task definition
  # AWS keeps versions: family:1, family:2, family:3
  # each time you update and deploy, version increments

  # Fargate = AWS manages the underlying servers
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  # awsvpc gives each task its own network interface
  # and its own IP address
  # required for Fargate

  cpu    = var.task_cpu
  memory = var.task_memory
  # how much CPU and RAM this task gets
  # 256 CPU units = 0.25 vCPU
  # 512 MB memory

  # the IAM role that ECS uses to pull from ECR
  # and write logs to CloudWatch
  execution_role_arn = aws_iam_role.ecs_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn

  # container definition is JSON
  # tells ECS exactly how to run our container
  container_definitions = jsonencode([
    {
      name  = var.project_name
      image = "${var.ecr_repository_url}:latest"
      # pulls the latest image from ECR
      # in production you'd use a specific version tag
      # e.g. :v1.2.3 instead of :latest

      portMappings = [
        {
          containerPort = var.container_port
          # the port inside the container (3000)
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]

      # environment variables passed into the container
      # your Node.js app reads these with process.env
      environment = [
        {
          name  = "NODE_ENV"
          value = "production"
        },
        {
          name  = "PORT"
          value = tostring(var.container_port)
          # tostring converts number 3000 to string "3000"
        },
        {
          name  = "DB_HOST"
          value = var.db_endpoint
          # the RDS endpoint our app connects to
        },
        {
          name  = "DB_NAME"
          value = var.db_name
        },
        {
          name  = "DB_USER"
          value = var.db_username
        },
        {
          name  = "DB_PASSWORD"
          value = var.db_password
          # in a stricter production setup
          # you'd use AWS Secrets Manager here
          # instead of passing as plain environment variable
          # but this is fine for learning
        }
      ]

      # logging configuration
      # sends all container logs to CloudWatch
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.main.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
          # logs appear as:
          # /ecs/budget-tracker-production/ecs/container-id
        }
      }

      # health check inside the container
      # separate from ALB health check
      # ECS uses this to know if the container is running
      healthCheck = {
        command     = ["CMD-SHELL", "wget -q -O /dev/null http://localhost:${var.container_port}/ || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
        # give container 60 seconds to start up
        # before health checks begin
        # Node.js needs time to initialise
      }

      essential = true
      # essential = true means if this container stops
      # the entire task stops
      # ECS then starts a new task automatically
    }
  ])

  tags = {
    Name = "${var.project_name}-${var.environment}-task"
  }
}

# ─────────────────────────────────────────
# IAM Roles for ECS
# ─────────────────────────────────────────

# Execution Role — used by ECS AGENT
# to pull images and write logs
resource "aws_iam_role" "ecs_execution_role" {
  name = "${var.project_name}-${var.environment}-ecs-execution-role"

  # trust policy — who can assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
          # only ECS tasks can use this role
          # not EC2, not Lambda, not humans
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-ecs-execution-role"
  }
}

# attach AWS managed policy to execution role
# this policy allows:
# → pulling images from ECR
# → writing logs to CloudWatch
resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  # this is an AWS managed policy
  # AWS maintains and updates it
  # we don't need to write it ourselves
}

# Task Role — used by YOUR APPLICATION
# permissions your app needs at runtime
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name}-${var.environment}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-ecs-task-role"
  }
}

# ─────────────────────────────────────────
# ECS Service
# ─────────────────────────────────────────

resource "aws_ecs_service" "main" {
  name            = "${var.project_name}-${var.environment}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = var.app_count
  # desired_count = 1 means keep 1 container running
  # if it crashes ECS automatically starts a new one

  # use Fargate launch type
  launch_type = "FARGATE"

  # networking configuration for the tasks
  network_configuration {
    subnets          = var.private_subnet_ids
    # tasks run in private subnets
    security_groups  = [var.ecs_sg_id]
    assign_public_ip = false
    # no public IP — tasks are only reachable via ALB
  }

  # connect ECS service to ALB target group
  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = var.project_name
    container_port   = var.container_port
    # ALB sends traffic to this container and port
  }

  # deployment configuration
  # controls how new versions are deployed
  deployment_minimum_healthy_percent = 50
  # keep at least 50% of tasks running during deployment
  # with 1 task: allows it to stop before starting new one

  deployment_maximum_percent = 200
  # allow up to 200% of desired count during deployment
  # with 1 task: can run 2 temporarily during update
  # ensures zero downtime deployments

  # wait for service to be stable after deployment
  wait_for_steady_state = false
  # set false for faster terraform apply
  # set true in production to catch deployment failures

  tags = {
    Name = "${var.project_name}-${var.environment}-service"
  }
}