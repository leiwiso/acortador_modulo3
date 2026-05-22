provider "aws" {
  region = var.aws_region
}

# Referenciar la tabla compartida de DynamoDB
data "aws_dynamodb_table" "urls_table" {
  name = "ShortUrlsTable"
}

# Empaquetado automático de la Lambda
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/../lambda/index.js"
  output_path = "${path.module}/lambda_function.zip"
}

# Rol de IAM
resource "aws_iam_role" "lambda_role" {
  name = "url_shortener_stats_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Políticas de Solo Lectura para DynamoDB y Logs
resource "aws_iam_role_policy" "lambda_policy" {
  name = "url_shortener_stats_policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem"
        ]
        Resource = data.aws_dynamodb_table.urls_table.arn
      }
    ]
  })
}

# Función Lambda
resource "aws_lambda_function" "stats_lambda" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "UrlShortener-Get-Stats"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      DYNAMODB_TABLE = data.aws_dynamodb_table.urls_table.name
    }
  }
}

# API Gateway independiente
resource "aws_apigatewayv2_api" "http_api" {
  name          = "UrlStats-API"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id           = aws_apigatewayv2_api.http_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.stats_lambda.invoke_arn
}

# Ruta específica requerida: GET /stats/{codigo}
resource "aws_apigatewayv2_route" "stats_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "GET /stats/{codigo}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_stage" "api_stage" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "api_gateway_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.stats_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}