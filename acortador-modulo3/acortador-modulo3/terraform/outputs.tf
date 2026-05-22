output "stats_api_url" {
  value       = "${aws_apigatewayv2_api.http_api.api_endpoint}/stats/"
  description = "URL base para consultar estadísticas (agrega el código al final)"
}