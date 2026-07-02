# github-actions-oidc-aws

Keyless CI/CD from GitHub Actions to AWS. Instead of storing long-lived AWS
access keys in GitHub secrets, workflows exchange a short-lived GitHub OIDC
token for temporary AWS credentials. The Terraform here provisions the OIDC
identity provider and an IAM role scoped so that only a specific repository
(and optionally a single branch or environment) can assume it.

I built this because static `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY`
secrets are the most common way CI credentials leak. OIDC removes the secret
entirely.

## How it works

```
GitHub Actions job
   │  requests an OIDC token (id-token: write)
   ▼
token.actions.githubusercontent.com  ──►  AWS STS AssumeRoleWithWebIdentity
   │                                            │ trust policy checks aud + sub
   ▼                                            ▼
short-lived AWS credentials  ◄───────────  scoped IAM role
```

The IAM trust policy pins two claims:
- `aud` must equal `sts.amazonaws.com`
- `sub` must match `repo:<org>/<repo>:<subject_claim>`

so no other repository can assume the role.

## Usage

1. Provision the provider and role:

   ```bash
   cd terraform
   terraform init
   terraform apply \
     -var="github_org=AitelqadiMo" \
     -var="github_repo=my-app" \
     -var='subject_claim=ref:refs/heads/main' \
     -var='managed_policy_arns=["arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"]'
   ```

2. Copy the `role_arn` output into a repo variable named `AWS_ROLE_ARN`.

3. Add a workflow that assumes the role (see
   `.github/workflows/deploy.yml`). The key lines:

   ```yaml
   permissions:
     id-token: write   # required to request the OIDC token
     contents: read
   ```

## Security choices

- **No static keys.** Nothing long-lived is stored in GitHub.
- **Scoped trust.** The role trusts exactly one repo, and by default only the
  `main` branch. Widen with `subject_claim` only when you must.
- **Least privilege.** Permissions are passed in explicitly via
  `managed_policy_arns`; there is no broad default.
- **Thumbprint computed at apply time** from GitHub's live certificate, so it
  never goes stale in code.

## License

MIT. See [LICENSE](LICENSE).
