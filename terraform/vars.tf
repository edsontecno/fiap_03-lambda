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
  default = "https://b03e-2804-46ec-80d-b900-9a0e-646a-cf41-19e3.ngrok-free.app"
}

variable "lambda_function_arn" {
  type    = string
  default = ""
}
