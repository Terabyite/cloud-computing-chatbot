variable "project"        { type = string }
variable "vpc_id"         { type = string }
variable "allow_ssh_cidr" { type = list(string) }

# ALB Security Group: 
resource "aws_security_group" "alb" {
  name   = "${var.project}-alb-sg"
  vpc_id = var.vpc_id

  ingress { 
    from_port = 80  
    to_port = 80  
    protocol = "tcp" 
    cidr_blocks = ["0.0.0.0/0"] 
    }
  ingress { 
    from_port = 443 
  to_port = 443 
  protocol = "tcp" 
  cidr_blocks = ["0.0.0.0/0"] 
  }

  egress  { 
    from_port = 0   
    to_port = 0   
    protocol = "-1" 
    cidr_blocks = ["0.0.0.0/0"] 
    }

  tags = { Name = "${var.project}-alb-sg" }
}

# EC2 Security Group: 
resource "aws_security_group" "ec2" {
  name   = "${var.project}-ec2-sg"
  vpc_id = var.vpc_id

  ingress {
    description     = "App from ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allow_ssh_cidr
  }

  egress { 
    from_port = 0 
    to_port = 0 
    protocol = "-1" 
    cidr_blocks = ["0.0.0.0/0"] 
    }

  tags = { Name = "${var.project}-ec2-sg" }
}

output "alb_sg_id" { value = aws_security_group.alb.id }
output "ec2_sg_id" { value = aws_security_group.ec2.id }