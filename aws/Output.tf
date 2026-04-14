################################################################################
# OUTPUTS — printed after terraform apply
################################################################################

output "ec2_public_ip" {
  description = "Public IP of the new EC2 instance"
  value       = module.ec2.public_ip
}

output "ec2_instance_id" {
  description = "EC2 Instance ID (needed to update Lambda if changed)"
  value       = module.ec2.instance_id
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = module.lambda.lambda_name
}

output "lambda_function_arn" {
  description = "Lambda function ARN"
  value       = module.lambda.lambda_arn
}

output "eventbridge_schedule_arn" {
  description = "EventBridge schedule ARN"
  value       = module.eventbridge.schedule_arn
}

output "github_workflow_url" {
  description = "Direct URL to the created GitHub Actions workflow"
  value       = "https://github.com/${var.github_owner}/${var.github_repo}/actions"
}

output "next_steps" {
  description = "What to do after terraform apply"
  value       = <<-EOT
    ✅ Infrastructure created. Next steps:
    1. SSH into new EC2:  ssh -i <your-key>.pem ubuntu@${module.ec2.public_ip}
    2. Push code to GitHub main branch — CI/CD pipeline fires automatically
    3. Test Lambda manually: AWS Console → Lambda → ${module.lambda.lambda_name} → Test
    4. Check EventBridge schedule in AWS Console → EventBridge → Schedules
  EOT
}
