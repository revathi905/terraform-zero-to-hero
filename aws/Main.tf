################################################################################
# ROOT MAIN.TF — Link Monitor CI/CD Infrastructure
# Wires all modules together
################################################################################

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = "ap-south-2"
}

provider "github" {
  token = var.github_token
  owner = var.github_owner
}

# ── IAM ───────────────────────────────────────────────────────────────────────
module "iam" {
  source = "./modules/iam"
}

# ── EC2 ───────────────────────────────────────────────────────────────────────
module "ec2" {
  source            = "./modules/ec2"
  instance_type     = var.ec2_instance_type
  ami_id            = var.ec2_ami_id
  key_name          = var.ec2_key_name
  ec2_iam_role_name = module.iam.ec2_instance_profile_name
  project_name      = var.project_name
  github_repo_url   = "https://github.com/${var.github_owner}/${var.github_repo}.git"
}

# ── LAMBDA ────────────────────────────────────────────────────────────────────
module "lambda" {
  source              = "./modules/lambda"
  instance_id         = module.ec2.instance_id
  docker_image        = "${var.dockerhub_username}/${var.project_name}:latest"
  lambda_role_arn     = module.iam.lambda_role_arn
  project_name        = var.project_name
  app_dir             = var.app_dir
  script_name         = var.script_name
}

# ── EVENTBRIDGE ───────────────────────────────────────────────────────────────
module "eventbridge" {
  source           = "./modules/eventbridge"
  lambda_arn       = module.lambda.lambda_arn
  lambda_name      = module.lambda.lambda_name
  schedule_cron    = var.schedule_cron
  project_name     = var.project_name
}

# ── GITHUB SECRETS + WORKFLOW ─────────────────────────────────────────────────
resource "github_actions_secret" "docker_username" {
  repository      = var.github_repo
  secret_name     = "DOCKER_USERNAME"
  plaintext_value = var.dockerhub_username
}

resource "github_actions_secret" "docker_password" {
  repository      = var.github_repo
  secret_name     = "DOCKER_PASSWORD"
  plaintext_value = var.dockerhub_token
}

resource "github_actions_secret" "ec2_host" {
  repository      = var.github_repo
  secret_name     = "EC2_HOST"
  plaintext_value = module.ec2.public_ip
}

resource "github_actions_secret" "ec2_user" {
  repository      = var.github_repo
  secret_name     = "EC2_USER"
  plaintext_value = "ubuntu"
}

resource "github_actions_secret" "ec2_ssh_key" {
  repository      = var.github_repo
  secret_name     = "EC2_SSH_KEY"
  plaintext_value = var.ec2_private_key_pem
}

# ── GITHUB ACTIONS WORKFLOW FILE ──────────────────────────────────────────────
resource "github_repository_file" "workflow" {
  repository          = var.github_repo
  branch              = "main"
  file                = ".github/workflows/deploy.yml"
  commit_message      = "chore: add CI/CD pipeline via Terraform"
  overwrite_on_create = true

  content = templatefile("${path.module}/template/deploy.yml.tpl", {
    dockerhub_username = var.dockerhub_username
    project_name       = var.project_name
    python_version     = var.python_version
  })
}
