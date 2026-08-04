# GitHub's OIDC thumbprint - this is GitHub's own certificate authority
# thumbprint, not project-specific. AWS validates GitHub's token signature
# against this, so a workflow run can prove "I am really a run of this repo"
# without ever holding a long-lived AWS access key.
locals {
  github_oidc_thumbprint = "6938fd4d98bab03faadb97b34396831e3780aea1"
}

# Only one OIDC provider for "token.actions.githubusercontent.com" can exist
# per AWS account - if you already created one by hand earlier (or via a
# different Terraform root), set create_oidc_provider = false and pass its
# ARN in via existing_oidc_provider_arn instead of creating a duplicate.
resource "aws_iam_openid_connect_provider" "github" {
  count           = var.create_oidc_provider ? 1 : 0
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [local.github_oidc_thumbprint]

  tags = { Name = "github-actions-oidc" }
}

locals {
  oidc_provider_arn = var.create_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : var.existing_oidc_provider_arn
}

# One role per workflow/purpose (e.g. app-deploy vs terraform-apply) - call
# this module once per role so each gets only the permissions it actually
# needs, rather than one shared role with the union of everything.
resource "aws_iam_role" "this" {
  name = var.role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Federated = local.oidc_provider_arn }
        Action    = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            # e.g. "repo:durveshyadav3604/SparknetTask1:*" - matches any
            # branch/tag/PR in that repo. Narrow this (e.g.
            # ":ref:refs/heads/main") if you want only main-branch runs to
            # be able to assume this role at all.
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:${var.subject_suffix}"
          }
        }
      }
    ]
  })

  tags = { Name = var.role_name }
}

resource "aws_iam_role_policy_attachment" "managed" {
  for_each   = toset(var.managed_policy_arns)
  role       = aws_iam_role.this.name
  policy_arn = each.value
}

resource "aws_iam_role_policy" "inline" {
  count  = var.inline_policy_json != null ? 1 : 0
  name   = "${var.role_name}-inline"
  role   = aws_iam_role.this.id
  policy = var.inline_policy_json
}
