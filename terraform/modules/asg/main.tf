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

# Instance role for SSM Session Manager (so you can shell in without public SSH)
resource "aws_iam_role" "ec2_role" {
  name = "${var.project}-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}


# Launch Template

resource "aws_launch_template" "lt" {
  name_prefix            = "${var.project}-lt-"
  image_id               = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [var.ec2_sg_id]

  user_data = base64encode(local.userdata) 

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project}-ec2"
    }
  }
}



resource "aws_autoscaling_group" "asg" {
  name                = "${var.project}-asg"
  desired_capacity    = var.desired_capacity
  min_size            = var.min_size
  max_size            = var.max_size
  vpc_zone_identifier = var.private_subnet_ids
  target_group_arns   = [var.target_group_arn]
  health_check_type   = "EC2"
  health_check_grace_period = 120

  launch_template {
    id      = aws_launch_template.lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project}-ec2"
    propagate_at_launch = true
  }

  lifecycle { create_before_destroy = true }
}

# Target tracking autoscaling by average CPU ~50%
resource "aws_autoscaling_policy" "cpu_tgt" {
  name                   = "${var.project}-cpu-50"
  autoscaling_group_name = aws_autoscaling_group.asg.name
  policy_type            = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification { predefined_metric_type = "ASGAverageCPUUtilization" }
    target_value = 50
  }
}

# EC2/ASG CPU alarm
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.project}-EC2-CPU-High"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 70
  dimensions = { AutoScalingGroupName = aws_autoscaling_group.asg.name }
  alarm_description   = "CPU > 70% for 2 minutes"
}

output "asg_name" { value = aws_autoscaling_group.asg.name }