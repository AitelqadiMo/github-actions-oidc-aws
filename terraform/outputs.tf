output "role_arn" {
  description = "ARN of the role GitHub Actions assumes. Set this as the AWS_ROLE_ARN variable in the repo."
  value       = aws_iam_role.deploy.arn
}

output "oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider."
  value       = aws_iam_openid_connect_provider.github.arn
}
