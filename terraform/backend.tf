terraform {
  backend "s3" {
    bucket = "terabbyte-terraform-state"
    key    = "chatbot/terraform.tfstate"
    region = "us-east-1"
  }
}