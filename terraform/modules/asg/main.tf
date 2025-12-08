variable "project"            { type = string }
variable "vpc_id"             { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "instance_type"      { type = string }
variable "key_name"           { type = string }
variable "ec2_sg_id"          { type = string }
variable "target_group_arn"   { type = string }
variable "desired_capacity"   { type = number }
variable "min_size"           { type = number }
variable "max_size"           { type = number }
variable "chatbot_repo_url"   { type = string }
variable "ami_id"             { type = string }
variable "iam_instance_profile_name" {
  description = "Name of the IAM instance profile to attach to EC2 instances"
  type        = string
}
variable "tags" {
  type    = map(string)
  default = {}
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_launch_template" "lt" {
  name_prefix            = "${var.project}-lt-"
  image_id               = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [var.ec2_sg_id]

  iam_instance_profile {
    name = var.iam_instance_profile_name
  }

  tag_specifications {
  resource_type = "instance"
  tags = merge({
    Name      = "${var.project}-ec2"
    ManagedBy = "github-actions" 
    Project   = var.project
  }, var.tags)
}

  # enforce IMDSv2
  metadata_options {
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
    http_endpoint               = "enabled"
  }
}

resource "aws_autoscaling_group" "asg" {
  name                = "${var.project}-asg"
  desired_capacity    = var.desired_capacity
  min_size            = var.min_size
  max_size            = var.max_size
  vpc_zone_identifier = var.private_subnet_ids
  target_group_arns   = [var.target_group_arn]

  # Use ELB health so ASG follows ALB target health
  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.lt.id
    version = "$Latest"
  }

 tag {
  key                 = "Name"
  value               = "${var.project}-ec2"
  propagate_at_launch = true
}

  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle { create_before_destroy = true }
}

resource "aws_autoscaling_policy" "cpu_tgt" {
  name                   = "${var.project}-cpu-50"
  autoscaling_group_name = aws_autoscaling_group.asg.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50
  }
}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.project}-EC2-CPU-High"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 70
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }
  alarm_description = "CPU > 70% for 2 minutes"
}

output "asg_name" { value = aws_autoscaling_group.asg.name }
output "launch_template_id" { value = aws_launch_template.lt.id }
output "launch_template_latest_version" { value = aws_launch_template.lt.latest_version }