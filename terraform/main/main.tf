# create vpc - single tier, public subnets only. ECS EC2 instances and
# tasks all get public IPs and reach the internet directly via the IGW,
# so no NAT gateway is needed.
module "vpc" {
  source                 = "../modules/vpc"
  region                 = var.region
  project_name           = var.project_name
  vpc_cidr               = var.vpc_cidr
  public_subnet_az1_cidr = var.public_subnet_az1_cidr
  public_subnet_az2_cidr = var.public_subnet_az2_cidr
}

# create security groups
module "security_group" {
  source                  = "../modules/security_group"
  vpc_id                  = module.vpc.vpc_id
  vpc_cidr                = var.vpc_cidr
  project_name            = var.project_name
  backend_container_port  = var.backend_container_port
  frontend_container_port = var.frontend_container_port
}

# create ECR repositories for both images
module "ecr" {
  source                   = "../modules/ecr"
  project_name             = var.project_name
  backend_repository_name  = var.backend_repository_name
  frontend_repository_name = var.frontend_repository_name
  image_retention_count    = var.image_retention_count
}

# create alb: single ALB, path-based routing (/api/* -> backend, else -> frontend)
module "application_load_balancer" {
  source                     = "../modules/alb"
  project_name               = var.project_name
  alb_sg_id                  = module.security_group.alb_sg_id
  public_subnet_az1_id       = module.vpc.public_subnet_az1_id
  public_subnet_az2_id       = module.vpc.public_subnet_az2_id
  vpc_id                     = module.vpc.vpc_id
  backend_container_port     = var.backend_container_port
  frontend_container_port    = var.frontend_container_port
  backend_health_check_path  = var.backend_health_check_path
  frontend_health_check_path = var.frontend_health_check_path
  enable_deletion_protection = var.enable_deletion_protection
  enable_https               = var.enable_https
  certificate_arn            = var.certificate_arn
}

# create ECS cluster, EC2 Auto Scaling Group + capacity provider, task
# definitions, services, and service-level autoscaling
module "ecs" {
  source = "../modules/ecs"

  project_name = var.project_name
  region       = var.region

  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = [module.vpc.public_subnet_az1_id, module.vpc.public_subnet_az2_id]
  ecs_instance_sg_id = module.security_group.ecs_instance_sg_id

  backend_target_group_arn  = module.application_load_balancer.backend_target_group_arn
  frontend_target_group_arn = module.application_load_balancer.frontend_target_group_arn

  backend_image_url  = module.ecr.backend_repository_url
  frontend_image_url = module.ecr.frontend_repository_url
  image_tag          = var.image_tag

  backend_container_port  = var.backend_container_port
  frontend_container_port = var.frontend_container_port

  backend_container_environment = var.backend_container_environment

  frontend_container_environment = var.frontend_container_environment

  backend_task_cpu     = var.backend_task_cpu
  backend_task_memory  = var.backend_task_memory
  frontend_task_cpu    = var.frontend_task_cpu
  frontend_task_memory = var.frontend_task_memory

  desired_count = var.desired_count
  min_capacity  = var.min_capacity
  max_capacity  = var.max_capacity

  ec2_instance_type        = var.ec2_instance_type
  ec2_key_name             = var.ec2_key_name
  ec2_root_volume_size     = var.ec2_root_volume_size
  ec2_asg_min_size         = var.ec2_asg_min_size
  ec2_asg_max_size         = var.ec2_asg_max_size
  ec2_asg_desired_capacity = var.ec2_asg_desired_capacity
  ec2_capacity_target      = var.ec2_capacity_target

  log_retention_days = var.log_retention_days

  # Module-level depends_on: ECS services register targets against the ALB's
  # target groups, which requires a listener to already exist on the ALB.
  # (The original code tried to express this with a `var.alb_listener`
  # object passed between modules and a resource-level depends_on on it -
  # depends_on doesn't reliably create an edge that way. Depending on the
  # whole ALB module here is the supported pattern.)
  depends_on = [module.application_load_balancer]

}

# --- GitHub Actions OIDC roles ---
# Two separate roles for two separate blast radii: the app-deploy pipeline
# only ever needs to push images and update ECS services; the terraform
# pipeline needs much broader account permissions to create/modify the
# infra itself. Keeping them apart means a compromised app-deploy workflow
# run can't touch networking/IAM.

# App-deploy role: build/push images to ECR, update ECS services.
module "github_oidc_app_deploy" {
  source               = "../modules/github_oidc"
  create_oidc_provider = true # first call creates the (account-wide, one-only) OIDC provider
  role_name            = "github-actions-ecs-deploy"
  github_org           = var.github_org
  github_repo          = var.github_repo
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser",
    "arn:aws:iam::aws:policy/AmazonECS_FullAccess",
  ]
}

# Terraform-apply role: broad infra permissions (VPC/EC2/ALB/ECS/IAM/logs).
# NOTE bootstrapping order: the very first time this whole config is
# applied, nothing exists yet for GitHub Actions to assume - so that first
# `terraform apply` has to run from a local machine with your own AWS
# credentials, same as everything else in this repo. Once this role exists,
# CI can take over subsequent applies (including ones that modify this role
# itself).
module "github_oidc_terraform" {
  source                     = "../modules/github_oidc"
  create_oidc_provider       = false # reuse the provider created above - only one allowed per account
  existing_oidc_provider_arn = module.github_oidc_app_deploy.oidc_provider_arn
  role_name                  = "github-actions-terraform"
  github_org                 = var.github_org
  github_repo                = var.github_repo
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonVPCFullAccess",
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
    "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess",
    "arn:aws:iam::aws:policy/AmazonECS_FullAccess",
    "arn:aws:iam::aws:policy/IAMFullAccess", # needed because this Terraform config itself creates IAM roles - tighten with a permissions boundary later if this becomes a shared/production repo
    "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess",
  ]
  inline_policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "TerraformStateBucket"
        Effect = "Allow"
        Action = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]
        Resource = [
          "arn:aws:s3:::github-terraform-bucket-durvesh-272",
          "arn:aws:s3:::github-terraform-bucket-durvesh-272/*"
        ]
      }
    ]
  })
}

