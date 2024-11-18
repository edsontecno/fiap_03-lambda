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
  default = "https://teste.com.br"
}

variable "lambda_function_arn" {
  type    = string
  default = ""
}
