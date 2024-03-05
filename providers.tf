terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  
  backend "s3" {
    bucket         = "zy-bucket"
    key            = "./terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "terraform_lock"
    encrypt        = true
  }
}

// https://developer.hashicorp.com/terraform/language/providers/requirements
provider "aws" {
  region = var.AWS_REGION
  profile = var.AWS_PROFILE
 
}

