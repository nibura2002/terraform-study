terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

module "vpc" {
  source = "../modules/vpc"
}

module "database" {
  source = "../modules/database"
  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids
}

module "backend" {
  source = "../modules/backend"
  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids = module.vpc.public_subnet_ids
  db_endpoint = module.database.db_endpoint
  db_username = module.database.db_username
  db_password = module.database.db_password
  db_name = module.database.db_name
  frontend_url = module.frontend.frontend_url
}

module "frontend" {
  source = "../modules/frontend"
  api_endpoint = module.backend.api_endpoint
}

output "api_endpoint" {
  value = module.backend.api_endpoint
}

output "frontend_url" {
  value = module.frontend.frontend_url
}

output "api_repository_url" {
  value = module.backend.api_repository_url
}

output "frontend_bucket_name" {
  value = module.frontend.bucket_name
} 