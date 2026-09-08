variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "cost-tracker"
}

variable "instance_type" {
  description = "EC2 instance type (Free Tier eligible)"
  type        = string
  default     = "t3.micro"
}

variable "billing_alert_email" {
  description = "Email for SNS notifications"
  type        = string
  default     = ""
}

variable "billing_alarm_thresholds" {
  description = "Map of alarm label to cost threshold in USD"
  type        = map(number)
  default = {
    warning  = 5.0
    critical = 10.0
  }
}

variable "ec2_shutdown_dry_run" {
  description = "If true, Lambda reports idle instances but does not stop them"
  type        = bool
  default     = true
}

variable "s3_glacier_transition_days" {
  description = "Days before current objects move to Glacier"
  type        = number
  default     = 90
}

variable "s3_noncurrent_glacier_days" {
  description = "Days before old object versions move to Glacier"
  type        = number
  default     = 30
}