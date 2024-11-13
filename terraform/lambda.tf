# Criação da Lambda Function `authorization`
resource "aws_lambda_function" "authorization" {
  filename         = "../lambda_function.zip" 
  function_name    = "authorization"
  role             = data.aws_iam_role.labrole.arn
  handler          = "authorization.lambda_handler"
  runtime          = "nodejs20.x" 

  environment {
    variables = {
      REGION = "us-east-1"
      SECRET_KEY_CRYPTO = "SECRET_KEY"
      USER_POOL_ID = "us-east-1_80QZtAqcL"
    }
  }
}

# Exporta o ARN da função Lambda para uso em outros módulos
output "lambda_function_arn" {
  value = aws_lambda_function.authorization.arn
}
