#!/usr/bin/env python3
"""Stop running EC2 instances that look unused (low CPU) and are opted in."""

import os
from datetime import datetime, timedelta, timezone

import boto3

CPU_THRESHOLD = float(os.environ.get("CPU_THRESHOLD", "5.0"))
LOOKBACK_MINUTES = int(os.environ.get("LOOKBACK_MINUTES", "60"))
DRY_RUN = os.environ.get("DRY_RUN", "true").lower() == "true"
SNS_TOPIC_ARN = os.environ.get("SNS_TOPIC_ARN", "")


def is_idle(cloudwatch, instance_id: str) -> bool:
    end = datetime.now(timezone.utc)
    start = end - timedelta(minutes=LOOKBACK_MINUTES)

    resp = cloudwatch.get_metric_statistics(
        Namespace="AWS/EC2",
        MetricName="CPUUtilization",
        Dimensions=[{"Name": "InstanceId", "Value": instance_id}],
        StartTime=start,
        EndTime=end,
        Period=LOOKBACK_MINUTES * 60,
        Statistics=["Average"],
    )
    datapoints = resp.get("Datapoints", [])
    if not datapoints:
        # No CPU data yet (new instance) — do not stop it
        return False
    avg = datapoints[0]["Average"]
    return avg < CPU_THRESHOLD


def find_and_stop():
    ec2 = boto3.client("ec2")
    cloudwatch = boto3.client("cloudwatch")

    running = ec2.describe_instances(
        Filters=[
            {"Name": "instance-state-name", "Values": ["running"]},
            {"Name": "tag:AutoShutdown", "Values": ["true"]},
        ]
    )

    stopped = []
    skipped = []

    for reservation in running.get("Reservations", []):
        for instance in reservation["Instances"]:
            instance_id = instance["InstanceId"]
            name = next(
                (t["Value"] for t in instance.get("Tags", []) if t["Key"] == "Name"),
                instance_id,
            )

            if not is_idle(cloudwatch, instance_id):
                skipped.append(f"{name} ({instance_id}) — CPU not idle")
                continue

            if DRY_RUN:
                stopped.append(f"{name} ({instance_id}) — DRY RUN, would stop")
            else:
                ec2.stop_instances(InstanceIds=[instance_id])
                stopped.append(f"{name} ({instance_id}) — stopped")

    return stopped, skipped


def handler(event, context):
    stopped, skipped = find_and_stop()
    lines = [
        "EC2 Auto-Shutdown Report",
        f"Dry run: {DRY_RUN}",
        f"CPU threshold: {CPU_THRESHOLD}% over {LOOKBACK_MINUTES} min",
        "",
        "Stopped / would stop:",
        *(stopped or ["  (none)"]),
        "",
        "Skipped:",
        *(skipped or ["  (none)"]),
    ]
    message = "\n".join(lines)

    if SNS_TOPIC_ARN:
        boto3.client("sns").publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject="EC2 Auto-Shutdown Report",
            Message=message,
        )

    return {"statusCode": 200, "stopped": stopped, "skipped": skipped}


if __name__ == "__main__":
    stopped, skipped = find_and_stop()
    print("stopped:", stopped)
    print("skipped:", skipped)