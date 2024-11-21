variable "regionDefault" {
  default = "us-east-1"
}

variable "accountIdVoclabs" {
  default = "207151609511"
}

variable "policyArn" {
  default = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

variable "url_load_balance" {
  default = "https://d1a0-2804-46ec-80d-b900-b8a5-ab5d-70b2-191.ngrok-free.app"
}

variable "lambda_function_arn" {
  type    = string
  default = ""
}
