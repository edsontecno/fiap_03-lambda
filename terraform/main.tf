terraform {
  backend "s3" {
    bucket = "fiap-fase03-tf"
    key    = "lambda/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.regionDefault
}

# Cognito Module
module "cognito" {
  source = "./cognito"
}

# Lambda Module
module "lambda" {
  source       = "./lambda"
  region       = var.regionDefault
  user_pool_id = module.cognito.user_pool_id
}

# API Gateway Module
module "apigateway" {
  source              = "./apigateway"
  region              = var.regionDefault
  lambda_function_arn = module.lambda.lambda_function_arn
  url_load_balance    = var.url_load_balance
}

output "cognito_user_pool_id" {
  value = module.cognito.user_pool_id
}

output "lambda_function_arn" {
  value = module.lambda.lambda_function_arn
}

output "api_gateway_url" {
  value = module.apigateway.api_gateway_url
}
