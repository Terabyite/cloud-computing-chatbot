variable "project" {
  type        = string
  description = "Project name prefix"
}

variable "common_tags" {
  type        = map(string)
  description = "Optional common tags to apply"
  default     = {}
}

resource "aws_iam_role" "ec2_role" {
  name = "${var.project}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = merge({
    Name = "${var.project}-ec2-role"
  }, var.common_tags)
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

output "iam_role_name" {
  value       = aws_iam_role.ec2_role.name
  description = "EC2 IAM role name"
}

output "iam_instance_profile_name" {
  value       = aws_iam_instance_profile.ec2_profile.name
  description = "EC2 instance profile name"
}