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


# User Data (Startup Script)
locals {
  userdata = <<-EOF
#!/bin/bash
set -euxo pipefail
exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1

echo "=== Starting chatbot setup on $(date) ==="

# --- Add 2 GB swap FIRST (before any heavy operation) ---
fallocate -l 2G /swapfile || dd if=/dev/zero of=/swapfile bs=1M count=2048
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
sysctl vm.swappiness=100
grep -q '/swapfile' /etc/fstab || echo '/swapfile swap swap defaults 0 0' >> /etc/fstab

# Confirm swap is active
free -h || true
swapon --show || true

# --- Update system and install required packages ---
dnf update -y
dnf install -y git python3 python3-pip

# --- Clone chatbot repo ---
cd /home/ec2-user
if [ ! -d "cloud-computing-chatbot" ]; then
  for i in 1 2 3; do
    git clone https://github.com/edwincai/cloud-computing-chatbot.git && break
    echo "Git clone failed, retrying..."
    sleep 5
  done
fi
chown -R ec2-user:ec2-user /home/ec2-user/cloud-computing-chatbot
chmod -R 755 /home/ec2-user/cloud-computing-chatbot

# --- Bootstrap pip safely ---
python3 -m ensurepip --upgrade
python3 -m pip install --upgrade wheel

# --- Install dependencies (TensorFlow light version) ---
python3 -m pip install tornado keras nltk "tensorflow-cpu==2.12.0" \
  "urllib3<2.0" "requests<2.32"

# --- Download NLTK data globally ---
mkdir -p /usr/share/nltk_data
python3 -m nltk.downloader -d /usr/share/nltk_data punkt wordnet || true

# --- Create and enable systemd service ---
cat >/etc/systemd/system/chatbot.service <<'UNIT'
[Unit]
Description=AI Chatbot (Tornado)
After=network.target

[Service]
User=ec2-user
Environment=PYTHONUNBUFFERED=1
Environment=NLTK_DATA=/usr/share/nltk_data
WorkingDirectory=/home/ec2-user/cloud-computing-chatbot
ExecStart=/usr/bin/python3 /home/ec2-user/cloud-computing-chatbot/chatdemo.py --port=8080
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable chatbot
systemctl start chatbot

echo "=== Chatbot setup completed successfully at $(date) ==="
EOF
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