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
  default = "http://a67395559806b4351b830cebe07d7874-1478507779.us-east-1.elb.amazonaws.com:3000"
}

variable "lambda_function_arn" {
  type    = string
  default = ""
}
