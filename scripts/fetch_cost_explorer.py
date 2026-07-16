#!/usr/bin/env python3
"""Fetch and parse AWS Cost Explorer cost and usage data."""

from datetime import date, timedelta
from decimal import Decimal

import boto3


def main():
    client = boto3.client("ce", region_name="us-east-1")

    end = date.today()
    start = end - timedelta(days=30)

    response = client.get_cost_and_usage(
        TimePeriod={
            "Start": start.isoformat(),
            "End": end.isoformat(),
        },
        Granularity="MONTHLY",
        Metrics=["UnblendedCost"],
        GroupBy=[{"Type": "DIMENSION", "Key": "SERVICE"}],
    )

    print("AWS Cost Explorer Report")
    print(f"Period: {start} → {end} (end exclusive)")
    print("-" * 50)

    for period in response["ResultsByTime"]:
        p_start = period["TimePeriod"]["Start"]
        p_end = period["TimePeriod"]["End"]
        print(f"\nPeriod: {p_start} → {p_end}")

        rows = []
        for group in period.get("Groups", []):
            name = group["Keys"][0]
            amount = Decimal(group["Metrics"]["UnblendedCost"]["Amount"])
            rows.append((name, amount))

        for name, amount in sorted(rows, key=lambda x: x[1], reverse=True):
            print(f"  {name}: ${amount:.4f}")


if __name__ == "__main__":
    main()