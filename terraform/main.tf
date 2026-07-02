###############################################################################
# GitHub Actions -> AWS via OIDC (keyless CI/CD)
#
# Creates the GitHub OIDC identity provider in AWS and an IAM role that only
# workflows from a specific repo (and optionally a specific branch) can assume.
# No long-lived AWS access keys are stored in GitHub secrets.
###############################################################################

# Fetch GitHub's OIDC TLS certificate so the thumbprint is computed at apply
# time rather than hard-coded and left to rot.
data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]

  tags = var.tags
}

# Trust policy: the OIDC provider is the principal, the audience must be
# sts.amazonaws.com, and the token subject must match this repo and (optionally)
# a single branch. This is what stops any other repo from assuming the role.
data "aws_iam_policy_document" "trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_org}/${var.github_repo}:${var.subject_claim}"]
    }
  }
}

resource "aws_iam_role" "deploy" {
  name                 = var.role_name
  assume_role_policy   = data.aws_iam_policy_document.trust.json
  max_session_duration = var.max_session_duration
  tags                 = var.tags
}

# Attach whatever managed policies the pipeline genuinely needs. Kept as a
# variable so consumers grant least privilege explicitly instead of inheriting
# a broad default.
resource "aws_iam_role_policy_attachment" "managed" {
  for_each   = toset(var.managed_policy_arns)
  role       = aws_iam_role.deploy.name
  policy_arn = each.value
}
