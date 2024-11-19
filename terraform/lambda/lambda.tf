# Criação da Lambda Function `authorization`
resource "aws_lambda_function" "authorization" {
  # filename         = "./lambda/lambda_function.zip" 
  function_name    = "authorization"
  role             = data.aws_iam_role.labrole.arn
  handler          = "authorization.lambda_handler"
  runtime          = "nodejs20.x" 

  source_code_hash = filebase64sha256("empty_function.js")
  filename = "empty_function.js"

  environment {
    variables = {
      REGION = var.region
      SECRET_KEY_CRYPTO = "SECRET_KEY"
      USER_POOL_ID = var.user_pool_id
    }
  }
}

output "lambda_function_arn" {
  value = aws_lambda_function.authorization.arn
}

