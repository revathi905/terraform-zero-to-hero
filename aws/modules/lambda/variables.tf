variable "instance_id"    { type = string }
variable "docker_image"   { type = string }
variable "lambda_role_arn"{ type = string }
variable "project_name"   { type = string }
variable "app_dir"        {
  type    = string
  default = "/home/ubuntu/link_monitor"
  description = "Path on EC2 that gets volume-mounted into the container as /app"
}
variable "script_name"    {
  type    = string
  default = "screenshot_checker_1.py"
  description = "Python script filename to run inside the container (relative to /app)"
}
