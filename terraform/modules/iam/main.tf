variable "project" {
  description = "Project name used for resource naming/tagging"
  type        = string
}

variable "extra_managed_policy_arns" {
  description = "Optional list of extra AWS managed policy ARNs to attach to the EC2 role"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to IAM resources"
  type        = map(string)
  default     = {}
}

# IAM role the EC2 instances will assume
resource "aws_iam_role" "ec2_role" {
  name               = "${var.project}-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge({
    Name    = "${var.project}-ec2-role"
    Project = var.project
  }, var.tags)
}

# Attach core SSM policy (required for Systems Manager)
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach any additional managed policies (optional)
resource "aws_iam_role_policy_attachment" "extra_managed" {
  for_each = toset(var.extra_managed_policy_arns)
  role     = aws_iam_role.ec2_role.name
  policy_arn = each.value
}

# Instance profile so EC2/Launch Template can reference it by name
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project}-ec2-instance-profile"
  role = aws_iam_role.ec2_role.name

  tags = merge({
    Name    = "${var.project}-ec2-instance-profile"
    Project = var.project
  }, var.tags)
}

output "ec2_role_name" {
  value       = aws_iam_role.ec2_role.name
  description = "Name of the IAM role attached to EC2 instances"
}

output "ec2_instance_profile_name" {
  value       = aws_iam_instance_profile.ec2_profile.name
  description = "Instance profile name (use this in launch templates/ASG)"
}

output "ec2_instance_profile_arn" {
  value       = aws_iam_instance_profile.ec2_profile.arn
  description = "Instance profile ARN"
}