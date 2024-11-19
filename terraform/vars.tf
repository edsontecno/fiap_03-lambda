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
  default = "http://ab2bfee95334d40c8851de48748e20f6-853857609.us-east-1.elb.amazonaws.com:3000"
}

variable "lambda_function_arn" {
  type    = string
  default = ""
}
