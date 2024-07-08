# Terraform Block
terraform {
  required_version = "> 0.14.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Provider Block
variable "AWS_ACCESS_KEY_ID" {
  description = "AWS session token"
  type        = string
}
variable "AWS_SECRET_ACCESS_KEY" {
  description = "AWS session token"
  type        = string
}
provider "aws" {
  region  = "us-east-1"
  access_key = AWS_ACCESS_KEY_ID
  secret_key = AWS_SECRET_ACCESS_KEY
}

