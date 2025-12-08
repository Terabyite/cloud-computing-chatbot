locals { name = var.project }

module "vpc" {
  source  = "./modules/vpc"
  project = local.name
}

module "security" {
  source         = "./modules/security"
  project        = local.name
  vpc_id         = module.vpc.vpc_id
  allow_ssh_cidr = var.allow_ssh_cidr
}

module "alb" {
  source            = "./modules/alb"
  project           = local.name
  vpc_id            = module.vpc.vpc_id
  public_subnets    = module.vpc.public_subnet_ids
  alb_sg_id         = module.security.alb_sg_id
  target_port       = 8080
  health_check_path = "/"
  enable_alb_logs   = var.enable_alb_logs
  alb_logs_bucket   = var.alb_logs_bucket

  certificate_arn   = var.hosted_zone_name == "" ? "" : module.acm[0].certificate_arn
}

module "asg" {
  source              = "./modules/asg"
  project             = local.name
  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnet_ids
  instance_type       = var.instance_type
  key_name            = var.key_name
  ec2_sg_id           = module.security.ec2_sg_id
  target_group_arn    = module.alb.target_group_arn
  desired_capacity    = var.desired_capacity
  min_size            = var.min_size
  max_size            = var.max_size
  chatbot_repo_url    = var.chatbot_repo_url
  ami_id              = data.aws_ami.ubuntu.id
  iam_instance_profile_name = module.iam.ec2_instance_profile_name
}

data "aws_route53_zone" "this" {
  count = var.hosted_zone_name == "" ? 0 : 1
  name  = var.hosted_zone_name
}

module "acm" {
  source           = "./modules/acm"
  count            = var.hosted_zone_name == "" ? 0 : 1

  # if subdomain empty → root domain
  domain_name      = trimsuffix(
    var.app_subdomain == "" ? var.hosted_zone_name : "${var.app_subdomain}.${var.hosted_zone_name}",
    "."
  )

  hosted_zone_id   = data.aws_route53_zone.this[0].zone_id
}


module "dns" {
  source         = "./modules/dns"
  count          = var.hosted_zone_name == "" ? 0 : 1
  hosted_zone_id = data.aws_route53_zone.this[0].zone_id
  record_name    = trimsuffix(
    var.app_subdomain == "" ? var.hosted_zone_name : "${var.app_subdomain}.${var.hosted_zone_name}",
    "."
  )
  alb_dns_name   = module.alb.alb_dns_name
  alb_zone_id    = module.alb.alb_zone_id
}

module "iam" {
  source  = "./modules/iam"
  project = var.project

  extra_managed_policy_arns = [
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
    "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess",          
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",           
  ]

  tags = {
    Owner = "devops"
    Env   = "prod"
  }
}

data "aws_ami" "ubuntu" {
  owners      = ["099720109477"] # Canonical
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}