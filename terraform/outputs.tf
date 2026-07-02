output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.cost_tracker_bucket.bucket
}

output "ec2_instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.cost_tracker_ec2.id
}

output "ec2_public_ip" {
  description = "EC2 public IP"
  value       = aws_instance.cost_tracker_ec2.public_ip
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.cost_tracker_lambda.function_name
}