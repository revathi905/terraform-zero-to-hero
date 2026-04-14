variable "ami_id"            { type = string }
variable "instance_type"     { type = string }
variable "key_name"          { type = string }
variable "ec2_iam_role_name" { type = string }
variable "project_name"      { type = string }
variable "github_repo_url"   {
  type        = string
  description = "HTTPS clone URL for the GitHub repo, e.g. https://github.com/revathi905/link_monitor.git"
  default     = ""
}
