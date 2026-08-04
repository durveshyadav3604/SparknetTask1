region       = "ap-south-1"
project_name = "awsinfra"
environment  = "production"

vpc_cidr               = "172.16.0.0/16"
public_subnet_az1_cidr = "172.16.0.0/20"
public_subnet_az2_cidr = "172.16.16.0/20"

# FIXED: original had a single container_port=3000 for both containers with
# a placeholder comment to "check" it. Neither container actually listens on
# 3000 - backend's Dockerfile EXPOSEs 5000, frontend's nginx EXPOSEs 80.
backend_container_port     = 5000
frontend_container_port    = 80
backend_health_check_path  = "/api/health" # FIXED: was "/health", which 404s - server.js only defines /api/health
frontend_health_check_path = "/"

desired_count = 2
min_capacity  = 2
max_capacity  = 4

# --- EC2 container instances (ECS EC2 launch type, not Fargate) ---
ec2_instance_type        = "t3.small"
ec2_key_name             = "linux-key2" # set to an existing EC2 key pair if you want SSH access; SSM Session Manager works either way
ec2_root_volume_size     = 30
ec2_asg_min_size         = 2
ec2_asg_max_size         = 4
ec2_asg_desired_capacity = 2
ec2_capacity_target      = 80

backend_task_cpu     = 512
backend_task_memory  = 1024
frontend_task_cpu    = 256
frontend_task_memory = 512

backend_container_environment = [
  { name = "NODE_ENV", value = "production" },
  { name = "PORT", value = "5000" },
  { name = "MONGO_URI", value = "" },
  { name = "SERVER_URL", value = "http://localhost:5000" }
]
# REACT_APP_API_URL is a *build-time* arg baked into the static bundle by
# the frontend Dockerfile - it can't be injected as a runtime container env
# var. Set it as a build-arg in the CI/CD workflow instead (see ci-cd.yml).
frontend_container_environment = [
  { name = "REACT_APP_API_URL", value = "aws_lb.application_load_balancer.dns_name" }
]

# Flip on once you have a domain + ACM cert; until then the ALB serves
# plain HTTP on :80.
enable_https    = false
certificate_arn = ""

enable_deletion_protection = false

github_org  = "durveshyadav3604"
github_repo = "SparknetTask1"