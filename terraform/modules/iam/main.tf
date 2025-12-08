variable "project" {
  type        = string
  description = "Project name prefix for resources"
}

variable "extra_managed_policy_arns" {
  type        = list(string)
  description = "Optional extra managed policy ARNs to attach to the role"
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to IAM resources"
  default     = {}
}


resource "aws_iam_role" "ec2_role" {
  name = "${var.project}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge({
    Name    = "${var.project}-ec2-role",
    Project = var.project
  }, var.tags)
}


resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cw_agent" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "s3_readonly" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}


resource "aws_iam_role_policy_attachment" "extra" {
  for_each  = toset(var.extra_managed_policy_arns)
  role      = aws_iam_role.ec2_role.name
  policy_arn = each.value
}


resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project}-ec2-instance-profile"
  role = aws_iam_role.ec2_role.name

  tags = merge({
    Name    = "${var.project}-ec2-instance-profile",
    Project = var.project
  }, var.tags)
}


output "role_name" {
  description = "IAM role name for EC2"
  value       = aws_iam_role.ec2_role.name
}

output "role_arn" {
  description = "IAM role ARN for EC2"
  value       = aws_iam_role.ec2_role.arn
}

output "instance_profile_name" {
  description = "IAM instance profile name to attach to EC2 Launch Template"
  value       = aws_iam_instance_profile.ec2_profile.name
}

output "instance_profile_arn" {
  description = "IAM instance profile ARN"
  value       = aws_iam_instance_profile.ec2_profile.arn
}

output "ec2_instance_profile_name" {
  description = "Name of the EC2 instance profile created for EC2 role"
  value       = aws_iam_instance_profile.ec2_profile.name
  
}