output "lambda_role_name" {
  description = "Lambda execution role (already least-privilege for logs)"
  value       = aws_iam_role.lambda_role.name
}

output "cost_reporter_user_name" {
  description = "IAM user for Cost Explorer script"
  value       = aws_iam_user.cost_reporter.name
}

output "cost_reporter_access_key_id" {
  description = "Access key ID for cost reporter (secret is sensitive)"
  value       = aws_iam_access_key.cost_reporter.id
}

output "cost_reporter_secret_access_key" {
  description = "Secret access key — store locally, never commit"
  value       = aws_iam_access_key.cost_reporter.secret
  sensitive   = true
}