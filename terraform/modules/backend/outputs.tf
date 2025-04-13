output "api_endpoint" {
  value = "http://${aws_lb.api.dns_name}"
}

output "api_repository_url" {
  value = aws_ecr_repository.api.repository_url
} 