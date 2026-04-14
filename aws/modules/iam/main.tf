################################################################################
# MODULE: IAM
# Creates:
#   1. EC2 IAM Role  — allows SSM + ECR access on the instance
#   2. Lambda IAM Role — allows EC2 start/stop and SSM send_command
################################################################################

# ── EC2 Role (for SSM agent) ──────────────────────────────────────────────────
resource "aws_iam_role" "ec2_ssm_role" {
  name = "EC2-SSM-LinkMonitor-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = { Name = "EC2-SSM-LinkMonitor-Role" }
}

resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "EC2-SSM-LinkMonitor-Profile"
  role = aws_iam_role.ec2_ssm_role.name
}

# ── Lambda Role ───────────────────────────────────────────────────────────────
resource "aws_iam_role" "lambda_role" {
  name = "Lambda-EventBridge-EC2-Orchestrator"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = { Name = "Lambda-EventBridge-EC2-Orchestrator" }
}

# Lambda: EC2 start/stop only (tighter than FullAccess)
resource "aws_iam_role_policy" "lambda_ec2_policy" {
  name = "lambda-ec2-start-stop"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:SendCommand",
          "ssm:GetCommandInvocation",
          "ssm:ListCommandInvocations"
        ]
        Resource = "*"
      },
      {
        # CloudWatch Logs for Lambda
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}
