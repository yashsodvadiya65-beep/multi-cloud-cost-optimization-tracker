# --- S3 Bucket (Free Tier: 5GB storage) ---
resource "aws_s3_bucket" "cost_tracker_bucket" {
  bucket = "${var.project_name}-data-${data.aws_caller_identity.current.account_id}"

  tags = {
    Project = var.project_name
    Purpose = "cost-optimization-tracker"
  }
}

resource "aws_s3_bucket_versioning" "cost_tracker_versioning" {
  bucket = aws_s3_bucket.cost_tracker_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

# --- EC2 Instance (Free Tier: t2.micro, 750 hrs/month) ---
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "cost_tracker_ec2" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  tags = {
    Name    = "${var.project_name}-ec2"
    Project = var.project_name
  }
}

# --- Lambda Function (Free Tier: 1M requests/month) ---
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "cost_tracker_lambda" {
  function_name = "${var.project_name}-hello"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "python3.12"

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  tags = {
    Project = var.project_name
  }
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/lambda_function.zip"

  source {
    content  = <<EOF
def handler(event, context):
    return {
        'statusCode': 200,
        'body': 'Cost tracker lambda is running'
    }
EOF
    filename = "index.py"
  }
}

data "aws_caller_identity" "current" {}