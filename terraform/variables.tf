variable "github_org" {
  description = "GitHub organisation or user that owns the repository."
  type        = string
}

variable "github_repo" {
  description = "Repository name allowed to assume the role."
  type        = string
}

variable "subject_claim" {
  description = <<-EOT
    The token subject suffix the role trusts. Examples:
      "ref:refs/heads/main"   -> only the main branch
      "environment:production" -> only the production environment
      "*"                      -> any ref in the repo (least restrictive)
  EOT
  type        = string
  default     = "ref:refs/heads/main"
}

variable "role_name" {
  description = "Name of the IAM role GitHub Actions will assume."
  type        = string
  default     = "github-actions-deploy"
}

variable "managed_policy_arns" {
  description = "List of IAM managed policy ARNs to attach (grant least privilege)."
  type        = list(string)
  default     = []
}

variable "max_session_duration" {
  description = "Maximum assumed-role session duration in seconds."
  type        = number
  default     = 3600
}

variable "tags" {
  description = "Tags applied to created resources."
  type        = map(string)
  default     = {}
}
