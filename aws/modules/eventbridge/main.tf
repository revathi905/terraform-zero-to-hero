################################################################################
# MODULE: EVENTBRIDGE
# Creates:
#   - EventBridge Scheduler (modern API, not legacy Rules)
#   - IAM role for scheduler to invoke Lambda
################################################################################

# ── IAM Role for EventBridge Scheduler ───────────────────────────────────────
resource "aws_iam_role" "scheduler_role" {
  name = "EventBridge-Scheduler-${var.project_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "scheduler.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "scheduler_invoke_lambda" {
  name = "invoke-lambda-${var.project_name}"
  role = aws_iam_role.scheduler_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "lambda:InvokeFunction"
      Resource = var.lambda_arn
    }]
  })
}

# ── EventBridge Schedule ──────────────────────────────────────────────────────
resource "aws_scheduler_schedule" "link_monitor" {
  name        = "${var.project_name}-daily-schedule"
  description = "Run ${var.project_name} Lambda on a daily cron schedule"
  group_name  = "default"

  # Flexible time window OFF = run exactly on time
  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression          = "cron(${var.schedule_cron})"
  schedule_expression_timezone = "Asia/Kolkata"  # IST — change if needed

  target {
    arn      = var.lambda_arn
    role_arn = aws_iam_role.scheduler_role.arn

    # Empty JSON payload — Lambda doesn't need event data
    input = jsonencode({})

    retry_policy {
      maximum_retry_attempts       = 2
      maximum_event_age_in_seconds = 3600
    }
  }
}

# ── Lambda permission for EventBridge ────────────────────────────────────────
resource "aws_lambda_permission" "allow_scheduler" {
  statement_id  = "AllowEventBridgeScheduler"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_name
  principal     = "scheduler.amazonaws.com"
  source_arn    = aws_scheduler_schedule.link_monitor.arn
}
