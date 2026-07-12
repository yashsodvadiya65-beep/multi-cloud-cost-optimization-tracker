#SNS topic

resource "aws_sns_topic" "billing_alerts" {
  provider = aws.us_east_1
  name     = "${var.project_name}-billing-alerts"
}

#Email subscription (only when email is set)

resource "aws_sns_topic_subscription" "billing_email" {
  count     = var.billing_alert_email != "" ? 1 : 0
  provider  = aws.us_east_1
  topic_arn = aws_sns_topic.billing_alerts.arn
  protocol  = "email"
  endpoint  = var.billing_alert_email
}

#CloudWatch alarm (one block, many alarms via for_each)

resource "aws_cloudwatch_metric_alarm" "billing" {
  for_each = var.billing_alarm_thresholds

  provider = aws.us_east_1

  alarm_name          = "${var.project_name}-billing-${each.key}-${each.value}usd"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = 21600
  statistic           = "Maximum"
  threshold           = each.value
  alarm_actions       = [aws_sns_topic.billing_alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    Currency = "USD"
  }
}