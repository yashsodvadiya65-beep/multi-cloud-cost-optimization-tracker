# Least-privilege identity for the Cost Explorer Python script

resource "aws_iam_user" "cost_reporter" {
  name = "${var.project_name}-cost-reporter"

  tags = {
    Project = var.project_name
    Purpose = "cost-explorer-readonly"
  }
}

resource "aws_iam_user_policy" "cost_explorer_readonly" {
  name = "${var.project_name}-ce-readonly"
  user = aws_iam_user.cost_reporter.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCostExplorerGetCostAndUsage"
        Effect = "Allow"
        Action = [
          "ce:GetCostAndUsage"
        ]
        Resource = "*"
      }
    ]
  })
}

# Optional: access key for local script testing (do NOT commit the secret)
resource "aws_iam_access_key" "cost_reporter" {
  user = aws_iam_user.cost_reporter.name
}

# Permissions for the Lambda monthly cost report
resource "aws_iam_role_policy" "lambda_cost_report" {
  name = "${var.project_name}-lambda-cost-report"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "CostExplorerRead"
        Effect   = "Allow"
        Action   = ["ce:GetCostAndUsage"]
        Resource = "*"
      },
      {
        Sid      = "PublishCostReport"
        Effect   = "Allow"
        Action   = ["sns:Publish"]
        Resource = aws_sns_topic.billing_alerts.arn
      }
    ]
  })
}