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

# Criação do recurso /public/orders
resource "aws_api_gateway_resource" "public_orders" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.public.id
  path_part   = "orders"
}

# Criação do recurso /public/payment
resource "aws_api_gateway_resource" "public_payment" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.public.id
  path_part   = "payment"
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

resource "aws_api_gateway_method" "public_proxy_orders" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.public_orders.id
  http_method   = "POST"
  authorization = "CUSTOM" # Uso de autorizador customizado
  authorizer_id = aws_api_gateway_authorizer.lambda_authorizer.id
  request_parameters = {
    "method.request.path.proxy" = true # Habilita o parâmetro {proxy} no método
  }
}

resource "aws_api_gateway_method" "public_proxy_payment" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.public_payment.id
  http_method   = "POST"
  authorization = "NONE" 
}

resource "aws_api_gateway_integration" "auth_proxy_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.auth_proxy.id
  http_method             = aws_api_gateway_method.auth_proxy_any.http_method
  integration_http_method = "ANY"
  type                    = "HTTP_PROXY" 
  uri                     = "${var.url_load_balance}/{proxy}"
  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
    "integration.request.header.user" = "context.authorizer.user"
  }
  # response_templates = {
  #   "application/json" = "$input.json('$')"
  # }
}

resource "aws_api_gateway_integration" "public_proxy_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.public_orders.id
  http_method             = aws_api_gateway_method.public_proxy_orders.http_method
  integration_http_method = "POST"
  type                    = "HTTP_PROXY" 
  uri                     = "${var.url_load_balance}/orders"
  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
    "integration.request.header.user" = "context.authorizer.user"
  }
  # response_templates = {
  #   "application/json" = "$input.json('$')"
  # }
}

resource "aws_api_gateway_integration" "public_payment_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.public_payment.id
  http_method             = aws_api_gateway_method.public_proxy_payment.http_method
  integration_http_method = "POST"
  type                    = "HTTP_PROXY" 
  uri                     = "${var.url_load_balance}/webhook"
  # response_templates = {
  #   "application/json" = "$input.json('$')"
  # }
}

# resource "aws_api_gateway_integration_response" "public_order_response" {
#   rest_api_id = aws_api_gateway_rest_api.api.id
#   resource_id = aws_api_gateway_resource.public_orders.id
#   http_method = aws_api_gateway_method.public_proxy_orders.http_method
#   status_code = "200"

#   response_parameters = {
#     "method.response.header.Content-Type" = "'application/json'"
#   }
# }


# resource "aws_api_gateway_integration_response" "public_payment_response" {
#   rest_api_id = aws_api_gateway_rest_api.api.id
#   resource_id = aws_api_gateway_resource.public_payment.id
#   http_method = aws_api_gateway_method.public_proxy_payment.http_method
#   status_code = "200"

#   response_parameters = {
#     "method.response.header.Content-Type" = "'application/json'"
#   }
# }

# resource "aws_api_gateway_integration_response" "public_auth_response" {
#   rest_api_id = aws_api_gateway_rest_api.api.id
#   resource_id = aws_api_gateway_resource.auth_proxy.id
#   http_method = aws_api_gateway_method.auth_proxy_any.http_method
#   status_code = "200"

#   response_parameters = {
#     "method.response.header.Content-Type" = "'application/json'"
#   }
# }


resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = "dev"

  depends_on = [
    aws_api_gateway_integration.auth_proxy_integration,
    aws_api_gateway_integration.public_proxy_integration,
  ]
}

resource "aws_lambda_permission" "allow_api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "authorization"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

output "api_gateway_url" {
  value = aws_api_gateway_deployment.deployment.invoke_url
  description = "URL base do API Gateway."
}

output "api_gateway_execution_arn" {
  value = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
  description = "ARN de execução do API Gateway para uso com o autorizador Lambda."
}
