# Multi-Cloud Cost Optimization Tracker

## Overview
Design a cloud cost optimization tracker for AWS Free Tier resources using
Terraform, CloudWatch, and Python (boto3) to generate cost reports and alerts
with IAM best practices.

## Week 1 Focus
- Set up AWS Free Tier
- Learn Terraform basics
- Plan resource inventory

## Tools
- AWS Free Tier
- Terraform
- Python + boto3
- CloudWatch
- GitHub Actions

## Project Structure
multi-cloud-cost-optimization-tracker/ 
├── README.md 
├── requirements.txt          ← here
├── scripts/
│   └── fetch_cost_explorer.py
├── terraform/ 
│   ├── main.tf          # S3, EC2, Lambda, EventBridge
│   ├── iam.tf           # cost reporter user + Lambda report policy
│   ├── billing_alarms.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── provider.tf
└── .github/workflows/

## Current capability: monthly cost report
Automated flow:
`EventBridge (1st of month) → Lambda → Cost Explorer → SNS email`
- **Script:** `scripts/fetch_cost_explorer.py`
  - Builds a previous-calendar-month report by service
  - Lambda `handler` publishes the report to SNS
- **Infra:** `terraform/`
  - Lambda `cost-tracker-monthly-report`
  - IAM for `ce:GetCostAndUsage` + `sns:Publish`
  - EventBridge cron: `cron(0 9 1 * ? *)` (09:00 UTC on the 1st)
  - SNS topic for billing alerts / report email

## Current capability: unused EC2 auto-shutdown
`EventBridge (hourly) → Lambda → CloudWatch CPU + EC2 Describe → Stop idle → SNS email`
  - Opt-in tag: AutoShutdown=true
  - Idle = average CPU < 5% over 60 minutes
  - DRY_RUN first, then real stop