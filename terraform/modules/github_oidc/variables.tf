variable "create_oidc_provider" {
  description = "Create the GitHub OIDC provider. Only one can exist per AWS account - set false on the second+ call to this module and pass existing_oidc_provider_arn instead."
  type        = bool
  default     = true
}

variable "existing_oidc_provider_arn" {
  description = "ARN of an already-existing GitHub OIDC provider. Only used when create_oidc_provider = false."
  type        = string
  default     = ""
}

variable "role_name" {
  description = "IAM role name, e.g. github-actions-ecs-deploy or github-actions-terraform"
  type        = string
}

variable "github_org" {
  description = "GitHub org/user, e.g. durveshyadav3604"
  type        = string
}

variable "github_repo" {
  description = "GitHub repo name, e.g. SparknetTask1"
  type        = string
}

variable "subject_suffix" {
  description = "Suffix appended to repo:org/repo: in the OIDC subject claim. \"*\" allows any branch/PR/tag; use \"ref:refs/heads/main\" to restrict to only main-branch runs."
  type        = string
  default     = "*"
}

variable "managed_policy_arns" {
  description = "List of AWS managed policy ARNs to attach"
  type        = list(string)
  default     = []
}

variable "inline_policy_json" {
  description = "Optional inline policy JSON (jsonencode(...)) for permissions with no matching AWS managed policy"
  type        = string
  default     = null
}
