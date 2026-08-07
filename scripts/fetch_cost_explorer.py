#!/usr/bin/env python3
"""Fetch AWS Cost Explorer data and format a monthly cost report."""

import os
from datetime import date, timedelta
from decimal import Decimal
from typing import Optional, Tuple


import boto3


def previous_month_range(today: Optional[date] = None) -> Tuple[date, date]:
    """Return (start, end) for the previous calendar month. End is exclusive."""
    today = today or date.today()
    first_of_this_month = today.replace(day=1)
    last_of_prev_month = first_of_this_month - timedelta(days=1)
    start = last_of_prev_month.replace(day=1)
    end = first_of_this_month
    return start, end


def build_report() -> str:
    """Query Cost Explorer for last month and return email-ready text."""
    client = boto3.client("ce", region_name="us-east-1")
    start, end = previous_month_range()

    response = client.get_cost_and_usage(
        TimePeriod={
            "Start": start.isoformat(),
            "End": end.isoformat(),
        },
        Granularity="MONTHLY",
        Metrics=["UnblendedCost"],
        GroupBy=[{"Type": "DIMENSION", "Key": "SERVICE"}],
    )

    lines = [
        "AWS Monthly Cost Report",
        f"Period: {start} → {end} (end exclusive)",
        "-" * 50,
    ]

    grand_total = Decimal("0")

    for period in response["ResultsByTime"]:
        p_start = period["TimePeriod"]["Start"]
        p_end = period["TimePeriod"]["End"]
        lines.append(f"\nBilling period: {p_start} → {p_end}")

        rows = []
        period_total = Decimal("0")
        for group in period.get("Groups", []):
            name = group["Keys"][0]
            amount = Decimal(group["Metrics"]["UnblendedCost"]["Amount"])
            rows.append((name, amount))
            period_total += amount

        grand_total += period_total
        lines.append(f"Total: ${period_total:.4f}")
        lines.append("")

        for name, amount in sorted(rows, key=lambda x: x[1], reverse=True):
            if amount == 0:
                continue
            lines.append(f"  {name}: ${amount:.4f}")

    lines.append("")
    lines.append("-" * 50)
    lines.append(f"Grand total: ${grand_total:.4f}")

    return "\n".join(lines)


def handler(event, context):
    """Lambda entrypoint: build report and email via SNS."""
    report = build_report()
    sns = boto3.client("sns")
    sns.publish(
        TopicArn=os.environ["SNS_TOPIC_ARN"],
        Subject="Monthly AWS Cost Report",
        Message=report,
    )
    return {"statusCode": 200, "body": "Report sent"}


if __name__ == "__main__":
    print(build_report())