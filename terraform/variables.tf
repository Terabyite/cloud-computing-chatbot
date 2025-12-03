# Project & Environment Configuration

variable "project" {
  type    = string
  default = "ai-chatbot"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "aws_profile" {
  type    = string
  default = "default"
}

# EC2 / Auto Scaling Configuration

variable "key_name" {
  type    = string
  default = "mytraining"
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "desired_capacity" {
  type    = number
  default = 2
}

variable "min_size" {
  type    = number
  default = 1
}

variable "max_size" {
  type    = number
  default = 3
}

# Security / Networking

variable "allow_ssh_cidr" {
  description = "List of CIDR blocks allowed SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"] 
}

# Application Settings

variable "chatbot_repo_url" {
  description = "GitHub repository URL for chatbot code"
  type        = string
  default     = "https://github.com/edwincai/cloud-computing-chatbot.git"
}

# Load Balancer Logging

variable "enable_alb_logs" {
  description = "Enable ALB access logs"
  type        = bool
  default     = false
}

variable "alb_logs_bucket" {
  description = "S3 bucket for ALB access logs"
  type        = string
  default     = ""
}

# Domain / SSL / DNS

variable "hosted_zone_name" {
  description = "Route 53 hosted zone name"
  type        = string
  default     = "terabbyte.online"
}

variable "app_subdomain" {
  description = "Optional subdomain; leave blank for root domain"
  type        = string
  default     = ""
}
