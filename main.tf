// main.tf

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Random suffix to keep S3 bucket names globally unique
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

# S3 bucket (e.g. for payment event archives or DLQs later)
resource "aws_s3_bucket" "payments_events" {
  bucket        = "${var.project_name}-${var.environment}-events-${random_string.suffix.result}"
  force_destroy = true

  tags = merge(
    {
      "Project"     = var.project_name
      "Environment" = var.environment
      "Component"   = "payments-events-bucket"
    },
    var.tags
  )
}

resource "aws_s3_bucket_public_access_block" "payments_events" {
  bucket = aws_s3_bucket.payments_events.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DynamoDB table for payment events
resource "aws_dynamodb_table" "payments_events" {
  name         = "${var.project_name}-${var.environment}-payments"
  billing_mode = "PAY_PER_REQUEST"

  hash_key  = "payment_id"
  range_key = "created_at"

  attribute {
    name = "payment_id"
    type = "S"
  }

  attribute {
    name = "created_at"
    type = "S"
  }

  tags = merge(
    {
      "Project"     = var.project_name
      "Environment" = var.environment
      "Component"   = "payments-events-table"
    },
    var.tags
  )
}

# IAM role for Lambda
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda_exec" {
  name               = "${var.project_name}-${var.environment}-lambda-exec"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = merge(
    {
      "Project"     = var.project_name
      "Environment" = var.environment
      "Component"   = "lambda-exec-role"
    },
    var.tags
  )
}

# Basic Lambda logging permissions
resource "aws_iam_role_policy_attachment" "lambda_basic_logs" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# DynamoDB write permissions for payment events
data "aws_iam_policy_document" "lambda_dynamodb_write" {
  statement {
    effect = "Allow"

    actions = [
      "dynamodb:PutItem"
    ]

    resources = [
      aws_dynamodb_table.payments_events.arn
    ]
  }
}

resource "aws_iam_role_policy" "lambda_dynamodb_write" {
  name   = "${var.project_name}-${var.environment}-lambda-dynamodb-write"
  role   = aws_iam_role.lambda_exec.id
  policy = data.aws_iam_policy_document.lambda_dynamodb_write.json
}

# CloudWatch Logs group for Lambda
resource "aws_cloudwatch_log_group" "payments_writer" {
  name              = "/aws/lambda/${aws_lambda_function.payments_writer.function_name}"
  retention_in_days = var.log_retention_days

  tags = merge(
    {
      "Project"     = var.project_name
      "Environment" = var.environment
      "Component"   = "lambda-logs"
    },
    var.tags
  )
}

# Lambda function that writes mock payment events into DynamoDB
resource "aws_lambda_function" "payments_writer" {
  function_name = "${var.project_name}-${var.environment}-payments-writer"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.12"

  filename         = "${path.module}/lambda/lambda.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda/lambda.zip")

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.payments_events.name
    }
  }

  timeout = 10
  memory_size = 128

  tags = merge(
    {
      "Project"     = var.project_name
      "Environment" = var.environment
      "Component"   = "payments-writer-lambda"
    },
    var.tags
  )
}

