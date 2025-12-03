variable "project"           { type = string }
variable "vpc_id"            { type = string }
variable "public_subnets"    { type = list(string) }
variable "alb_sg_id"         { type = string }
variable "target_port"       { type = number }
variable "health_check_path" { type = string }
variable "certificate_arn"   { type = string }
variable "enable_alb_logs"   { 
    type = bool    
default = false 
}
variable "alb_logs_bucket"   { 
    type = string  
    default = "" 
    }

resource "aws_lb" "this" {
  name               = "${var.project}-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = var.public_subnets
  security_groups    = [var.alb_sg_id]
  dynamic "access_logs" {
    for_each = var.enable_alb_logs ? [1] : []
    content {
      bucket  = var.alb_logs_bucket
      enabled = true
    }
  }
  tags = { Name = "${var.project}-alb" }
}

resource "aws_lb_target_group" "tg" {
  name        = "${var.project}-tg"
  vpc_id      = var.vpc_id
  port        = var.target_port
  protocol    = "HTTP"
  target_type = "instance"
  health_check {
    path                = var.health_check_path
    healthy_threshold   = 2
    unhealthy_threshold = 5
    interval            = 30
    matcher             = "200-399"
  }
  tags = { Name = "${var.project}-tg" }
}

# HTTP 80 -> redirect to HTTPS 443
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      status_code = "HTTP_301"
      protocol    = "HTTPS"
      port        = "443"
    }
  }
}

# HTTPS 443 -> target group
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

# ALB 5XX alarm (basic)
resource "aws_cloudwatch_metric_alarm" "alb_5xx_high" {
  alarm_name          = "${var.project}-ALB-5XX-High"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = 5
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  dimensions = {
    LoadBalancer = aws_lb.this.arn_suffix
  }
  alarm_description = "ALB 5XX > 5 in 1m"
}

output "alb_dns_name"     { value = aws_lb.this.dns_name }
output "alb_zone_id"      { value = aws_lb.this.zone_id }
output "target_group_arn" { value = aws_lb_target_group.tg.arn }
output "alb_arn"          { value = aws_lb.this.arn }