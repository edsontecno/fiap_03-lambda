resource "aws_api_gateway_rest_api" "api" {
  name        = "fiap-8soat"
  description = "API Gateway fiap-8soat com rotas /auth e /public"
}

# Criação do recurso /auth
resource "aws_api_gateway_resource" "auth" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "auth"
}

# Criação do recurso /auth/{proxy+}
resource "aws_api_gateway_resource" "auth_proxy" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.auth.id
  path_part   = "{proxy+}"
}

# Criação do recurso /public
resource "aws_api_gateway_resource" "public" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "public"
}

# Criação do recurso /public/{proxy+}
resource "aws_api_gateway_resource" "public_proxy" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.public.id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_authorizer" "lambda_authorizer" {
  name                   = "authorization"
  rest_api_id            = aws_api_gateway_rest_api.api.id
  authorizer_uri         = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${var.lambda_function_arn}/invocations"
  authorizer_result_ttl_in_seconds = 300
  type                   = "TOKEN" 
  identity_source        = "method.request.header.token"
}

# Método ANY para /auth/{proxy+}
resource "aws_api_gateway_method" "auth_proxy_any" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.auth_proxy.id
  http_method   = "ANY"
  authorization = "CUSTOM" 
  authorizer_id = aws_api_gateway_authorizer.lambda_authorizer.id
  request_parameters = {
    "method.request.path.proxy" = true 
  }
}

# Método ANY para /public/{proxy+}
resource "aws_api_gateway_method" "public_proxy_any" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.public_proxy.id
  http_method   = "ANY"
  authorization = "CUSTOM" # Uso de autorizador customizado
  authorizer_id = aws_api_gateway_authorizer.lambda_authorizer.id
  request_parameters = {
    "method.request.path.proxy" = true # Habilita o parâmetro {proxy} no método
  }
}


resource "aws_api_gateway_integration" "auth_proxy_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.auth_proxy.id
  http_method             = aws_api_gateway_method.auth_proxy_any.http_method
  integration_http_method = "ANY"
  type                    = "HTTP" 
  uri                     = var.url_load_balance
  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
    "integration.request.header.user" = "context.authorizer.user"
  }
}

resource "aws_api_gateway_integration" "public_proxy_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.public_proxy.id
  http_method             = aws_api_gateway_method.public_proxy_any.http_method
  integration_http_method = "ANY"
  type                    = "HTTP" 
  uri                     = var.url_load_balance
  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
    "integration.request.header.user" = "context.authorizer.user"
  }
}

resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = "dev"

  depends_on = [
    aws_api_gateway_integration.auth_proxy_integration,
    aws_api_gateway_integration.public_proxy_integration,
  ]
}

output "api_gateway_url" {
  value = aws_api_gateway_deployment.deployment.invoke_url
  description = "URL base do API Gateway."
}
