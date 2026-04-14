################################################################################
# VARIABLES — fill values in terraform.tfvars (never commit secrets)
################################################################################



variable "project_name" {
  description = "Project name used for naming all resources"
  type        = string
  default     = "link-monitor"
}

# ── EC2 ───────────────────────────────────────────────────────────────────────
variable "ec2_instance_type" {
  description = "EC2 instance type (t3.micro is free-tier eligible)"
  type        = string
  default     = "t3.micro"
}

variable "ec2_ami_id" {
  description = "Ubuntu 22.04 LTS AMI ID (check for latest in your region)"
  type        = string
  # ap-south-1 Ubuntu 22.04 LTS — update if region changes
  default     = "ami-0f58b397bc5c1f2e8"
}

variable "ec2_key_name" {
  description = "Name of existing EC2 Key Pair in AWS (for SSH)"
  type        = string
}

variable "ec2_private_key_pem" {
  description = "Content of .pem private key (stored as GitHub secret for CI/CD)"
  type        = string
  sensitive   = true
}

# ── DOCKER HUB ────────────────────────────────────────────────────────────────
variable "dockerhub_username" {
  description = "Docker Hub username (e.g. siyyadri)"
  type        = string
}

variable "dockerhub_token" {
  description = "Docker Hub access token (Read & Write)"
  type        = string
  sensitive   = true
}

# ── GITHUB ────────────────────────────────────────────────────────────────────
variable "github_token" {
  description = "GitHub personal access token (needs repo + secrets scope)"
  type        = string
  sensitive   = true
}

variable "github_owner" {
  description = "GitHub username or org (e.g. revathi905)"
  type        = string
}

variable "github_repo" {
  description = "GitHub repo name only — NOT the full URL (e.g. link_monitor)"
  type        = string
  default     = "link_monitor"
}

# ── LAMBDA / SCHEDULER ────────────────────────────────────────────────────────
variable "schedule_cron" {
  description = "EventBridge cron (UTC). 0 4 * * ? * = 9:30 AM IST daily"
  type        = string
  default     = "0 4 * * ? *"
}

variable "python_version" {
  description = "Python version used in GitHub Actions"
  type        = string
  default     = "3.11"
}

variable "app_dir" {
  description = "Absolute path on EC2 that gets volume-mounted as /app inside the container"
  type        = string
  default     = "/home/ubuntu/link_monitor"
}

variable "script_name" {
  description = "Python script to run inside the container (e.g. screenshot_checker_1.py)"
  type        = string
  default     = "screenshot_checker_1.py"
}
