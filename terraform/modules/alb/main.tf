# ─────────────────────────────────────────
# Application Load Balancer
# ─────────────────────────────────────────

resource "aws_lb" "main" {
  name               = "${var.project_name}-${var.environment}-alb"
  # result: "budget-tracker-production-alb"

  internal           = false
  # internal = false means public facing
  # accessible from the internet
  # internal = true would be for internal AWS traffic only

  load_balancer_type = "application"
  # application = ALB (layer 7, understands HTTP)
  # network     = NLB (layer 4, raw TCP/UDP)
  # we use application because we serve HTTP traffic

  security_groups    = [var.alb_sg_id]
  # attach our ALB security group
  # allows port 80 from internet

  subnets            = var.public_subnet_ids
  # ALB spans BOTH public subnets
  # one in ap-southeast-2a
  # one in ap-southeast-2b
  # if one AZ goes down, ALB still works in the other ✅

  # enable deletion protection in production
  # prevents accidental deletion of the load balancer
  enable_deletion_protection = false
  # set false for learning so we can destroy easily
  # set true in real production

  tags = {
    Name = "${var.project_name}-${var.environment}-alb"
  }
}

# ─────────────────────────────────────────
# Target Group
# ─────────────────────────────────────────

resource "aws_lb_target_group" "main" {
  name        = "${var.project_name}-${var.environment}-tg"
  port        = var.container_port
  # the port our ECS containers listen on (3000)

  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
  # target_type = "ip" is required for ECS Fargate
  # Fargate tasks get their own IP address
  # ALB sends traffic directly to that IP

  # ── Health Check ──
  # ALB regularly checks if our containers are healthy
  # if a container fails health checks
  # ALB stops sending traffic to it
  health_check {
    enabled             = true
    path                = "/"
    # ALB hits GET / on our app
    # if it gets a 200 response = healthy ✅
    # if it gets no response = unhealthy ❌

    port                = "traffic-port"
    # use the same port as traffic (3000)

    protocol            = "HTTP"
    healthy_threshold   = 2
    # container must pass 2 consecutive checks to be healthy
    # prevents flapping (healthy/unhealthy/healthy)

    unhealthy_threshold = 3
    # container must fail 3 consecutive checks to be unhealthy
    # prevents marking container unhealthy on one bad check

    timeout             = 5
    # wait 5 seconds for a response before marking as failed

    interval            = 30
    # check every 30 seconds

    matcher             = "200"
    # expect HTTP 200 OK response
    # anything else = unhealthy
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-tg"
  }
}

# ─────────────────────────────────────────
# Listener
# ─────────────────────────────────────────

resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  # attach this listener to our ALB
  # arn = Amazon Resource Name (unique identifier)

  port              = 80
  # listen for incoming traffic on port 80 (HTTP)

  protocol          = "HTTP"

  # what to do with incoming traffic
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
    # forward ALL traffic to our target group
    # which contains our ECS containers
  }
}